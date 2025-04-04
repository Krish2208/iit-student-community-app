import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'tabs/home_tab.dart';
import 'tabs/clubs_events.dart';
import 'tabs/profile_tab.dart';
import 'tabs/ride_sharing_tab.dart';
import 'tabs/merchandise_tab.dart';
import 'package:iiti_student_community/services/notification_service.dart';
import 'package:iiti_student_community/screens/event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const ClubsEventsTab(),
    const MerchandiseTab(),
    const RideSharingTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize notification service and check permissions
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    await notificationService.init(
      onNotificationTap: (eventId) async {
        // Handle navigation to event details
        print('Navigate to event: $eventId');
        // Fetch event details from Firestore using the eventId
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
        if (!doc.exists) {
          print('Event not found');
          return;
        }
        // Navigate to the event details page
        print('Event found: ${doc.data()}');
        
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(event: Event.fromFirestore(doc))));
      },
    );

    // Check permissions after UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndRequestPermissions(context);
    });
  }

  Future<void> checkAndRequestPermissions(BuildContext context) async {
    NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
    print('Current notification settings: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // User has already denied - need to guide them to settings
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notifications Disabled'),
            content: const Text(
              'Notifications are disabled. To receive updates about events, please enable notifications in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      // First time - show educational UI before requesting
      if (mounted) {
        showNotificationPermissionDialog(context);
      }
    }
  }

  void showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'To get updates about new events from clubs you follow, please enable notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              requestNotificationPermissions();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> requestNotificationPermissions() async {
    // Request permissions
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true, // For iOS, allows quiet notifications until user decides
    );

    print('User notification permission status: ${settings.authorizationStatus}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration),
            label: 'Clubs & Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Merchandise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Ride Sharing',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}