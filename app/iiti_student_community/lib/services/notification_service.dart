import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  
  // Callback for navigation when a notification is tapped
  Function(String eventId)? onEventNotificationTapped;

  // Mark notifications as read
  Future<void> _markNotificationAsRead(String eventId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      // from the notifications collection get the notification where eventId is equal to eventId
      await _firestore.collection('notifications').where('eventId', isEqualTo: eventId).get().then((value) {
        for (var doc in value.docs) {
          // update the notification document to mark read
          _firestore.collection('notifications').doc(doc.id).update({'readStatus.$userId': true}).then((_) {
            print('Notification marked as read');
          }).catchError((error) {
            print('Failed to mark notification as read: $error');
          });
        }
      });
    }
  }
  
  // Initialize the service
  Future<void> init({Function(String eventId)? onNotificationTap}) async {
    onEventNotificationTapped = onNotificationTap;
    
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
      
      await _flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            Map<String, dynamic> data = json.decode(response.payload!);
            if (data['eventId'] != null && onEventNotificationTapped != null) {
              onEventNotificationTapped!(data['eventId']);
              _markNotificationAsRead(data['eventId']);
            }
          }
        },
      );
      
      // Configure FCM callbacks
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Save FCM token to database
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _saveTokenToDatabase(token);
      }
      
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
      
      // Sync subscriptions with FCM topics
      await _syncSubscriptionsWithTopics();
    }
  }
  
  Future<void> _syncSubscriptionsWithTopics() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Get all clubs the user is subscribed to
      final userSubscriptions = await _firestore
          .collection('clubs')
          .where('subscribers', arrayContains: userId)
          .get();
      
      // Subscribe to each club's topic
      for (var club in userSubscriptions.docs) {
        await _firebaseMessaging.subscribeToTopic('club_${club.id}');
      }
    } catch (e) {
      print('Error syncing subscriptions: $e');
    }
  }
  
  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && _flutterLocalNotificationsPlugin != null) {
      _flutterLocalNotificationsPlugin!.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'club_events_channel',
            'Club Events',
            channelDescription: 'Notifications for new club events',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (message.data['eventId'] != null && onEventNotificationTapped != null) {
      onEventNotificationTapped!(message.data['eventId']);
    }
  }
  
  // Subscribe to a club's topic
  Future<void> subscribeToClub(String clubId) async {
    await _firebaseMessaging.subscribeToTopic('club_$clubId');
    
    // Store notification subscription in Firestore
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('notification_subscriptions').doc(userId).set({
        'subscribedClubs': FieldValue.arrayUnion([clubId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
  
  // Unsubscribe from a club's topic
  Future<void> unsubscribeFromClub(String clubId) async {
    await _firebaseMessaging.unsubscribeFromTopic('club_$clubId');
    
    // Remove notification subscription from Firestore
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('notification_subscriptions').doc(userId).set({
        'subscribedClubs': FieldValue.arrayRemove([clubId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
