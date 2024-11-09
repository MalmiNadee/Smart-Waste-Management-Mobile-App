import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste/customer/PaymentPage.dart';
import 'package:smart_waste/customer/ProfilePage.dart';
import 'package:smart_waste/customer/RequestPage.dart';

// Singleton pattern for FirestoreService to handle fetching user data
class FirestoreService {
  
  FirestoreService._privateConstructor();
  static final FirestoreService _instance = FirestoreService._privateConstructor();
  
  factory FirestoreService() {
    return _instance;
  }

  // Method to fetch user data by email
  Future<Map<String, dynamic>?> fetchUserDetails(String userEmail) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null; // No user found
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null; // Return null if an error occurs
    }
  }
}

class CustomerHome extends StatefulWidget {
  @override
  _CustomerHomeState createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String _address = "Loading...";
  String _profileImage = 'https://example.com/profile-image.png'; // Replace with your image URL
  String _co2Saved = "800 g";
  String _points = "Loading..."; 
  String _itemsRecycled = "Loading...";
  bool _isLoading = true;

  int _selectedIndex = 0; 

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); //retrieve the user details from Firebase
  }

  Future<void> _fetchUserDetails() async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      // Use the singleton service to fetch user details
      Map<String, dynamic>? userData = await FirestoreService().fetchUserDetails(userEmail);

      if (userData != null) {
        setState(() {
          _address = userData['location'] ?? "No address";
          _points = userData['myPoints']?.toString() ?? "0";
          _co2Saved = userData['name']?.toString() ?? "no";
          _itemsRecycled = userData['noItems']?.toString() ?? "0";
          _isLoading = false; 
        });
      } else {
        print('No user document found');
        setState(() {
          _isLoading = false; 
        });
      }
    } else {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Waste Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF43A047), 
      ),
      body: _getBodyContent(), 
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF43A047), 
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; 
          });
          _onItemTapped(index); 
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Payment',
          ),
        ],
      ),
    );
  }

  Widget _getBodyContent() {
    if (_selectedIndex == 0) {
      return _buildHomeContent(); 
    } else if (_selectedIndex == 1) {
      return ProfilePage(); 
    } else {
      return PaymentPage(); 
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address and profile section
          Container(
            color: Color(0xFF43A047), 
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.white),
                    Text(
                      _address,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(_profileImage),
                  radius: 30,
                ),
              ],
            ),
          ),

          // CO2 Saved section
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF66BB6A), 
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  'Welcome ' + _co2Saved,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Current Email: ${FirebaseAuth.instance.currentUser?.email ?? 'No email'}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'CO2 Saved',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Points and Items Recycled section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('My Points', _points, Color(0xFF66BB6A)),
                _buildStatCard('Items Recycled', _itemsRecycled, Color(0xFF66BB6A)),
              ],
            ),
          ),

          // Request Garbage Collection section
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RequestPage()));
            },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF66BB6A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Garbage Collection',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap here to submit a request',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward_ios, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),

          
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage()));
            },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF66BB6A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make Payment for your recycling service',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward_ios, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle navigation based on the selected index
  void _onItemTapped(int index) {
    if (index == 0) {
      // Home is already displayed
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage()));
    }
  }

  // Helper method to create stat cards
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
