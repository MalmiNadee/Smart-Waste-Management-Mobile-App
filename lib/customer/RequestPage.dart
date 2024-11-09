import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Singleton class for Firebase operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  FirebaseService._internal();

  static FirebaseService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add waste collection request
  Future<void> addWasteRequest({
    required String name,
    required double recycleWasteWeight,
    required double organicWasteWeight,
    required double generalWasteWeight,
    required LatLng location,
  }) async {
    String? userEmail = _auth.currentUser?.email;

    if (userEmail == null) {
      throw Exception('User is not logged in');
    }

    await _firestore.collection('orders').add({
      'name': name,
      'recycleWasteWeight': recycleWasteWeight,
      'organicWasteWeight': organicWasteWeight,
      'generalWasteWeight': generalWasteWeight,
      'email': userEmail,
      'location': {
        'latitude': location.latitude, //north-south
        'longitude': location.longitude, //east-west
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class RequestPage extends StatefulWidget {
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  
  double _recycleWasteWeight = 1; 
  double _organicWasteWeight = 1;
  double _generalWasteWeight = 1;

 
  LatLng _selectedLocation = LatLng(6.9271, 79.8612); // Default location (Colombo)
  String _locationText = "Tap on map to select a location";

  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseService.instance.addWasteRequest(
          name: _nameController.text,
          recycleWasteWeight: _recycleWasteWeight,
          organicWasteWeight: _organicWasteWeight,
          generalWasteWeight: _generalWasteWeight,
          location: _selectedLocation,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully!')),
        );
        Navigator.pop(context); 
      } catch (e) {
        // error handling 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Garbage Collection'),
        backgroundColor: Colors.green[600],
      ),
      body: Container(
        color: Color(0xFFA5D6A7),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                _buildNameField(),
                SizedBox(height: 20),
                _buildWasteSlider(
                  'Recycle Waste (kg)',
                  _recycleWasteWeight,
                  (newValue) {
                    setState(() {
                      _recycleWasteWeight = newValue;
                    });
                  },
                ),
                SizedBox(height: 20),
                _buildWasteSlider(
                  'Organic Waste (kg)',
                  _organicWasteWeight,
                  (newValue) {
                    setState(() {
                      _organicWasteWeight = newValue;
                    });
                  },
                ),
                SizedBox(height: 20),
                _buildWasteSlider(
                  'General Waste (kg)',
                  _generalWasteWeight,
                  (newValue) {
                    setState(() {
                      _generalWasteWeight = newValue;
                    });
                  },
                ),
                SizedBox(height: 20),
                _buildMapSection(),
                Text(
                  _locationText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

 
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Enter your name',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  // Method to build waste slider widget
  Widget _buildWasteSlider(String label, double currentValue, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Slider(
          value: currentValue,
          min: 1,
          max: 10,
          divisions: 9,
          label: '${currentValue.round()} kg',
          onChanged: onChanged,
          activeColor: const Color.fromARGB(255, 15, 84, 19),
          inactiveColor: Colors.grey[300],
        ),
        Text(
          'Weight: ${currentValue.toStringAsFixed(1)} kg',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }


  Widget _buildMapSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            center: _selectedLocation,
            zoom: 13.0,
            onTap: (_, newLatLng) {
              setState(() {
                _selectedLocation = newLatLng;
                _locationText = "Location Selected: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}";
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation,
                  builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
      child: Text('Submit Request'),
    );
  }
}
