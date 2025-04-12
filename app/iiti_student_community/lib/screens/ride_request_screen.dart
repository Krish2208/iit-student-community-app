import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:iiti_student_community/models/places_suggestion.dart';
import 'package:iiti_student_community/components/location_picker.dart';

final String kGoogleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

class CreateRideRequestPage extends StatefulWidget {
  const CreateRideRequestPage({Key? key}) : super(key: key);

  @override
  State<CreateRideRequestPage> createState() => _CreateRideRequestPageState();
}

class _CreateRideRequestPageState extends State<CreateRideRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _displayMap = false;
  
  // For location suggestions
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void dispose() {
    _locationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
          _locationController.text = result['formatted_address'] ?? result['name'];
          _displayMap = true;
          _showSuggestions = false;
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
    }
  }

  // Get place name from coordinates
  Future<void> _getPlaceFromCoordinates(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${position.latitude},${position.longitude}&'
        'key=$kGoogleApiKey'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        setState(() {
          _locationController.text = data['results'][0]['formatted_address'];
        });
      } else {
        // If no places found, set the coordinates as text
        setState(() {
          _locationController.text = 'Location at (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _displayMap = true;
      });
      
      // Get and set the address for the selected coordinates
      await _getPlaceFromCoordinates(result);
    }
  }

  Future<void> _submitRideRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to create a ride request'),
            ),
          );
          return;
        }

        // Combine date and time
        final DateTime rideDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Create ride request document
        await FirebaseFirestore.instance.collection('ride_requests').add({
          'userId': user.uid,
          'userName': user.displayName,
          'userEmail': user.email,
          'userPhotoUrl': user.photoURL,
          'location': _locationController.text,
          'dateTime': Timestamp.fromDate(rideDateTime),
          'coordinates': _selectedLocation != null
              ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude)
              : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Return to previous screen
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ride request: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride Request'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location input
              const Text(
                'Where are you going?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Enter destination',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Add debounce to prevent too many API calls
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          _getPlaceSuggestions(value);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: _selectLocationOnMap,
                    tooltip: 'Select on map',
                  ),
                ],
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

              // Show map preview if location is selected
              if (_displayMap && _selectedLocation != null) ...[
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: _selectedLocation!,
                        ),
                      },
                      myLocationEnabled: false,
                      compassEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      tiltGesturesEnabled: false,
                      liteModeEnabled: true,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Date and time section
              const Text(
                'When are you traveling?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
                ),
              ),

              const SizedBox(height: 16),

              // Time picker
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_selectedTime.format(context)),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRideRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('CREATE RIDE REQUEST'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}