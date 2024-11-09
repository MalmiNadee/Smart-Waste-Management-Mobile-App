import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For handling geographic coordinates
import 'MyOrders.dart'; // Import MyOrders.dart
import 'QRScannerPage.dart'; // Import QRScannerPage.dart
import '../login.dart'; // Import your LoginPage here

class DriverHome extends StatelessWidget {
  final String driverEmail; // Pass email to the home page

  const DriverHome({super.key, required this.driverEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context); // Show logout confirmation dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DriverLocationMap(driverEmail: driverEmail), // Display the map here
          ),
          const SizedBox(height: 20),
          // My Orders Box
          _buildNavigationButton(
            context,
            'My Orders',
            Icons.list,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyOrdersPage(driverEmail: driverEmail),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Scan QR Code Box
          _buildNavigationButton(
            context,
            'QR Scan',
            Icons.qr_code_scanner,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScannerPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call the logout method
                _logout(context);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Logout method
  void _logout(BuildContext context) {
    // Clear any session data here, if applicable.
    // For example: AuthService().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to login page
    );
  }
}

class DriverLocationMap extends StatefulWidget {
  final String driverEmail;

  const DriverLocationMap({Key? key, required this.driverEmail}) : super(key: key);

  @override
  _DriverLocationMapState createState() => _DriverLocationMapState();
}

class _DriverLocationMapState extends State<DriverLocationMap> {
  List<DocumentSnapshot> _orders = []; // Store the orders
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchOrders(); // Fetch orders from Firestore on initialization
  }

  Future<void> _fetchOrders() async {
    try {
      // Fetch orders where the driverEmail matches the logged-in driver email
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('selectedOrders') // Your Firestore collection name
          .where('driverEmail', isEqualTo: widget.driverEmail)
          .get();

      setState(() {
        _orders = snapshot.docs; // Set the orders in state
        _isLoading = false; // Set loading to false
      });
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator()) // Display loading indicator while fetching
        : Container(
            margin: const EdgeInsets.all(10), // Add margin around the map
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5), // Shadow position
                ),
              ],
            ),
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(6.927079, 79.861244), // Default center: Coordinates of Sri Lanka
                zoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                  additionalOptions: {
                    'attribution': '© OpenStreetMap contributors',
                  },
                ),
                MarkerLayer(
                  markers: _orders.map((order) {
                    if (order.exists) {
                      final data = order.data() as Map<String, dynamic>?;

                      if (data != null) {
                        if (data['orderDetails'] is Map<String, dynamic>) {
                          final orderDetails = data['orderDetails'] as Map<String, dynamic>;

                          if (orderDetails['location'] is Map<String, dynamic>) {
                            final location = orderDetails['location'] as Map<String, dynamic>;

                            final lat = location['latitude'] as double?;
                            final lon = location['longitude'] as double?;

                            if (lat != null && lon != null) {
                              return Marker(
                                point: LatLng(lat, lon),
                                width: 40.0,
                                height: 40.0,
                                builder: (ctx) => GestureDetector(
                                  onTap: () => _showOrderDetails(context, orderDetails),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      }
                    }
                    return null;
                  }).whereType<Marker>().toList(),
                ),
              ],
            ),
          );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center( // Center the popup
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Order Name: ${orderDetails['name'] ?? 'N/A'}'),
                const SizedBox(height: 5),
                Text('Customer Email Address: ${orderDetails['email'] ?? 'N/A'}'),
                const SizedBox(height: 5),
                Text('General Waste Weight: ${orderDetails['generalWasteWeight'] ?? 'N/A'}'),
                const SizedBox(height: 5),
                Text('Organic Waste Weight: ${orderDetails['organicWasteWeight'] ?? 'N/A'}'),
                const SizedBox(height: 5),
                Text('Recycle Waste Weight: ${orderDetails['recycleWasteWeight'] ?? 'N/A'}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
