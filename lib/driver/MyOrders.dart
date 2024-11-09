import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MyOrdersPage extends StatelessWidget {
  final String driverEmail;

  MyOrdersPage({required this.driverEmail});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getOrders() async {
    QuerySnapshot ordersSnapshot = await _firestore
        .collection('selectedOrders')
        .where('driverEmail', isEqualTo: driverEmail)
        .get();

    List<Map<String, dynamic>> orders = ordersSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    return orders;
  }

  // Function to show the map in a popup dialog
  void _showLocationPopup(BuildContext context, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(latitude, longitude),
                zoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(latitude, longitude),
                      builder: (ctx) => GestureDetector(
                        onTap: () {
                          _showMarkerDetailsPopup(context, latitude, longitude);
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show marker details popup when marker is tapped
  void _showMarkerDetailsPopup(BuildContext context, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Marker Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Latitude: $latitude'),
                Text('Longitude: $longitude'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching orders.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          List<Map<String, dynamic>> orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> order = orders[index];
              Map<String, dynamic>? orderDetails =
                  order['orderDetails'] as Map<String, dynamic>?;

              if (orderDetails == null) {
                return const ListTile(
                  title: Text('No order details available.'),
                );
              }

              final email = orderDetails['email'] ?? 'N/A';
              final generalWaste = orderDetails['generalWasteWeight'] ?? 'N/A';
              final id = orderDetails['id'] ?? 'N/A';
              final location = orderDetails['location'] ?? 'N/A';
              final name = orderDetails['name'] ?? 'N/A';
              final organicWaste = orderDetails['organicWasteWeight'] ?? 'N/A';
              final recycleWaste = orderDetails['recycleWasteWeight'] ?? 'N/A';

              final latitude = location['latitude'] as double? ?? 0.0;
              final longitude = location['longitude'] as double? ?? 0.0;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Name: $name',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Name: $name'),
                      Text('Email: $email'),
                      Text('General Waste Weight: $generalWaste'),
                      Text('Organic Waste Weight: $organicWaste'),
                      Text('Recycle Waste Weight: $recycleWaste'),
                      const SizedBox(height: 8),
                      // Display the "See Location" button
                      ElevatedButton(
                        onPressed: () {
                          // Show the map popup when button is pressed
                          _showLocationPopup(context, latitude, longitude);
                        },
                        child: const Text('See Location'),
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${order['status'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
