import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login.dart'; 

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Singleton Firebase Auth instance
  static final FirebaseAuth _authInstance = FirebaseAuth.instance;
  static final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  Future<void> _fetchUserData() async {
    try {
     
      String? userEmail = _authInstance.currentUser?.email;

      if (userEmail != null) {
        // Fetch user data from Firestore using QuerySnapshot
        QuerySnapshot snapshot = await _firestoreInstance
            .collection('users') // Replace with your Firestore collection name
            .where('email', isEqualTo: userEmail) 
            .get();

        // Check if any documents are returned
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _userData = snapshot.docs.first.data() as Map<String, dynamic>?; 
            _isLoading = false; // Set loading to false once data is fetched
          });
        } else {
          _handleError('No user document found for the current user.');
        }
      } else {
        _handleError('No user is currently signed in.');
      }
    } catch (e) {
      _handleError('Error fetching user data: $e');
    }
  }

  void _handleError(String errorMessage) {
    print(errorMessage); 
    setState(() {
      _isLoading = false; 
    });
   
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _logout() async {
    try {
      await _authInstance.signOut(); 
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      ); 
    } catch (e) {
      _handleError('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF66BB6A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA5D6A7), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                   
                    _buildProfilePicture(),
                    const SizedBox(height: 20), 
                    Text(
                      "Current Email: ${_authInstance.currentUser?.email ?? 'N/A'}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20), 
                    // User Info Cards
                    _buildUserInfoCard("Name: ${_userData?['name'] ?? 'N/A'}"),
                    _buildUserInfoCard("NIC: ${_userData?['NIC'] ?? 'N/A'}"),
                    _buildUserInfoCard("Location: ${_userData?['location'] ?? 'N/A'}"),
                    _buildUserInfoCard("My Points: ${_userData?['myPoints'] ?? 'N/A'}"),
                    _buildUserInfoCard("Number of Items Recycled: ${_userData?['noItems'] ?? 'N/A'}"),
                    _buildUserInfoCard("Phone: ${_userData?['phone'] ?? 'N/A'}"),
                    const SizedBox(height: 20), 
                    // Logout Button
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, 
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 18, color: Colors.white), // Change text color here
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture() {
    // Replace 'profilePictureUrl' with the actual URL or path from your Firestore data
    String profilePictureUrl = _userData?['profilePictureUrl'] ?? 'https://via.placeholder.com/150'; 

    return Container(
      width: double.infinity, // Full width
      child: CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(profilePictureUrl), // Load the image from URL
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildUserInfoCard(String text) {
    return Container(
      width: double.infinity, // Full width for the card
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), 
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
