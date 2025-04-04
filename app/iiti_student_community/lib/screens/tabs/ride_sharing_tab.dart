import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:iiti_student_community/components/map_view.dart';
import 'package:iiti_student_community/screens/ride_request_screen.dart';
import 'package:iiti_student_community/models/places_suggestion.dart';

final String kGoogleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

// Main ride sharing page with ride request list and filters
class RideSharingTab extends StatefulWidget {
  const RideSharingTab({Key? key}) : super(key: key);

  @override
  State<RideSharingTab> createState() => _RideSharingTabState();
}

class _RideSharingTabState extends State<RideSharingTab> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterDate;
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  bool _isLoading = false;

  // For location suggestions
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Fetch place suggestions from Google Places API
  Future<void> _getPlaceSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$input&'
        'components=country:in&'
        'key=$kGoogleApiKey'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List<dynamic> predictions = data['predictions'];
        setState(() {
          _placeSuggestions = predictions
              .map((prediction) => PlaceSuggestion(
                    description: prediction['description'],
                    placeId: prediction['place_id'],
                  ))
              .toList();
          _showSuggestions = true;
        });
      } else {
        setState(() {
          _placeSuggestions = [];
          _showSuggestions = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting suggestions: $e')),
      );
    }
  }

  // Get place details from place ID
  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=geometry,name,formatted_address&'
        'key=$kGoogleApiKey'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final result = data['result'];
        final geometry = result['geometry'];
        final location = geometry['location'];

        setState(() {
          _selectedLocation = LatLng(
            location['lat'],
            location['lng'],
          );
          _selectedLocationName = result['formatted_address'] ?? result['name'];
          _searchController.text = _selectedLocationName!;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting place details: ${data['status']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting place details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter Rides',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16.0),

                  // Date filter
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_filterDate != null
                        ? DateFormat('EEE, MMM d, yyyy').format(_filterDate!)
                        : 'Select Date'),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _filterDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          _filterDate = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 8.0),

                  // Filter actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterDate = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('CLEAR ALL'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Trigger rebuild with filters
                          Navigator.pop(context);
                        },
                        child: const Text('APPLY'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Calculate distance between two coordinates in kilometers using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = math.pi / 180;
    const earthRadiusKm = 6371.0;
    
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    
    return earthRadiusKm * 2 * math.asin(math.sqrt(a));
  }

  void _clearSearchFilters() {
    setState(() {
      _searchController.clear();
      _selectedLocation = null;
      _selectedLocationName = null;
    });
  }

  Stream<QuerySnapshot> _getRideRequestsStream() {
    // Start with base query
    Query query = FirebaseFirestore.instance.collection('ride_requests');

    // Apply date filter if set
    if (_filterDate != null) {
      final DateTime startOfDay = DateTime(
        _filterDate!.year,
        _filterDate!.month,
        _filterDate!.day,
      );

      final DateTime endOfDay = DateTime(
        _filterDate!.year,
        _filterDate!.month,
        _filterDate!.day,
        23, 59, 59,
      );

      query = query.where(
        'dateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
      ).where(
        'dateTime',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
      );
    } else {
      // Default: show future rides
      query = query.where(
        'dateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
      );
    }

    // Order results
    return query.orderBy('dateTime', descending: false).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter rides',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with location suggestions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearchFilters,
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _getPlaceSuggestions(value);
                    });
                  },
                ),
                
                // Display place suggestions
                if (_showSuggestions && _placeSuggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _placeSuggestions.length > 5 ? 5 : _placeSuggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _placeSuggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(suggestion.description),
                          leading: const Icon(Icons.location_on_outlined),
                          onTap: () {
                            _getPlaceDetails(suggestion.placeId);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Filter chips display
          if (_filterDate != null || _selectedLocationName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filterDate != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(DateFormat('MMM d').format(_filterDate!)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _filterDate = null;
                            });
                          },
                        ),
                      ),
                    if (_selectedLocationName != null)
                      Chip(
                        label: Text(_selectedLocationName!.length > 20 
                          ? '${_selectedLocationName!.substring(0, 20)}...' 
                          : _selectedLocationName!),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: _clearSearchFilters,
                      ),
                  ],
                ),
              ),
            ),

          // Ride requests list
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getRideRequestsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No ride requests found'));
                      }

                      var rideRequests = snapshot.data!.docs;

                      // Filter by location proximity if location is selected
                      if (_selectedLocation != null) {
                        rideRequests = rideRequests.where((request) {
                          final data = request.data() as Map<String, dynamic>;
                          
                          // Check if this ride request has coordinates
                          if (data['coordinates'] != null) {
                            final GeoPoint coordinates = data['coordinates'] as GeoPoint;
                            // Calculate distance between selected location and ride request location
                            final distance = _calculateDistance(
                              _selectedLocation!.latitude,
                              _selectedLocation!.longitude,
                              coordinates.latitude,
                              coordinates.longitude,
                            );
                            
                            // Return true if within 5 km
                            return distance <= 5.0;
                          }
                          return false;
                        }).toList();

                        if (rideRequests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_off, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('No rides found within 5km of "${_selectedLocationName}"'),
                              ],
                            ),
                          );
                        }
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: rideRequests.length,
                        itemBuilder: (context, index) {
                          final request = rideRequests[index];
                          final data = request.data() as Map<String, dynamic>;

                          final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
                          final String location = data['location'] ?? 'Unknown location';
                          final String userName = data['userName'] ?? 'Anonymous';
                          final String? userPhotoUrl = data['userPhotoUrl'];
                          final bool isPast = dateTime.isBefore(DateTime.now());

                          // Calculate distance if we have a selected location
                          String? distanceText;
                          if (_selectedLocation != null && data['coordinates'] != null) {
                            final GeoPoint coordinates = data['coordinates'] as GeoPoint;
                            final double distance = _calculateDistance(
                              _selectedLocation!.latitude,
                              _selectedLocation!.longitude,
                              coordinates.latitude,
                              coordinates.longitude,
                            );
                            distanceText = '${distance.toStringAsFixed(1)} km away';
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                                child: userPhotoUrl == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(
                                location,
                                style: isPast ? TextStyle(color: Colors.grey[600]) : null,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormat('EEE, MMM d').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}',
                                    style: isPast ? TextStyle(color: Colors.grey[500]) : null,
                                  ),
                                  Text(
                                    'by $userName',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  if (distanceText != null)
                                    Text(
                                      distanceText,
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: isPast
                                  ? const Chip(
                                label: Text('Past', style: TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: Colors.grey,
                                padding: EdgeInsets.symmetric(horizontal: 4),
                              )
                                  : null,
                              onTap: () {
                                _showRideRequestDetails(context, data, request.id);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRideRequestPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Ride'),
      ),
    );
  }

  void _showRideRequestDetails(
      BuildContext context,
      Map<String, dynamic> data,
      String requestId,
      ) {
    final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == data['userId'];

    // Calculate distance if we have a selected location
    String? distanceText;
    if (_selectedLocation != null && data['coordinates'] != null) {
      final GeoPoint coordinates = data['coordinates'] as GeoPoint;
      final double distance = _calculateDistance(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        coordinates.latitude,
        coordinates.longitude,
      );
      distanceText = '${distance.toStringAsFixed(1)} kilometers away';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['location'] ?? 'Unknown location',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(dateTime)}',
              ),
              Text('Time: ${DateFormat('h:mm a').format(dateTime)}'),
              
              if (distanceText != null) ...[
                const SizedBox(height: 8.0),
                Text(
                  distanceText,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              const SizedBox(height: 16.0),

              // User info
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: data['userPhotoUrl'] != null ? NetworkImage(data['userPhotoUrl']) : null,
                    child: data['userPhotoUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 8.0),
                  Text('Posted by: ${data['userName'] ?? 'Anonymous'}'),
                ],
              ),
              const SizedBox(height: 16.0),

              // View on map
              if (data['coordinates'] != null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                  onPressed: () {
                    Navigator.pop(context);
                    final GeoPoint geoPoint = data['coordinates'] as GeoPoint;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapViewScreen(
                          location: LatLng(
                            geoPoint.latitude,
                            geoPoint.longitude,
                          ),
                          title: data['location'] ?? 'Location',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8.0),
              ],

              // Action buttons
              if (isOwner) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Request'),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteRideRequest(context, requestId);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    backgroundColor: Colors.red,
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Contact Requester'),
                  onPressed: () {
                    // Implement contact functionality
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contacting requester... (Not implemented)')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteRideRequest(BuildContext context, String requestId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride request deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ride request: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}