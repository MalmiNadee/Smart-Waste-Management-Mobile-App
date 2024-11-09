import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pie_chart/pie_chart.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  Barcode? result;
  bool isScanned = false; // Flag to avoid duplicate processing

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanned) {
      final Barcode? barcode = capture.barcodes.first;
      if (barcode != null && barcode.rawValue != null) {
        setState(() {
          result = barcode;
          isScanned = true; // Set the flag to true after a successful scan
        });

        // Retrieve user data from Firestore
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(result!.rawValue)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          // Now, retrieve order data using the email from user data
          QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('orders') // Replace with your Firestore collection name
              .where('email', isEqualTo: userData['email']) // Assuming 'email' is the field name
              .get();

          var orderData = snapshot.docs.isNotEmpty ? snapshot.docs.first.data() as Map<String, dynamic>? : null;

          // Navigate to DustbinDetailsPage with both user and order data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DustbinDetailsPage(
                userData: userData,
                orderData: orderData,
              ),
            ),
          ).then((_) {
            setState(() {
              isScanned = false; // Reset the flag after returning from details page
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null) ? Text('Scanning Complete') : Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}

class DustbinDetailsPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? orderData; // New parameter for order data

  DustbinDetailsPage({required this.userData, this.orderData});

  @override
  Widget build(BuildContext context) {
    double generalWasteWeight = orderData?['generalWasteWeight']?.toDouble() ?? 0.0;
    double organicWasteWeight = orderData?['organicWasteWeight']?.toDouble() ?? 0.0;
    double recycleWasteWeight = orderData?['recycleWasteWeight']?.toDouble() ?? 0.0;

    // Calculate total weight
    double totalWeight = generalWasteWeight + organicWasteWeight + recycleWasteWeight;

    // Pie chart data
    Map<String, double> dataMap = {
      "General Waste": generalWasteWeight,
      "Organic Waste": organicWasteWeight,
      "Recycle Waste": recycleWasteWeight,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Dustbin Details'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildUserInfoBox('Customer Name', userData['name']),
            _buildUserInfoBox('Customer Email', userData['email']),
            _buildUserInfoBox('Customer City', userData['location']),
            _buildUserInfoBox('Customer Phone Number', userData['phone']),
            SizedBox(height: 20), // Add space between user and order data
            _buildOrderInfoBox('General Waste Percentage', generalWasteWeight),
            _buildOrderInfoBox('Organic Waste Percentage', organicWasteWeight),
            _buildOrderInfoBox('Recycle Waste Percentage', recycleWasteWeight),
            SizedBox(height: 20), // Space before total weight box
            _buildOrderInfoBox('Total Weight', totalWeight), // Display total weight
            SizedBox(height: 20), // Space before pie chart
            Container(
              height: 300, // Height for the pie chart
              child: PieChart(
                dataMap: dataMap,
                chartType: ChartType.ring,
                colorList: [Colors.red, Colors.green, Colors.blue],
                legendOptions: LegendOptions(
                  legendPosition: LegendPosition.right,
                  showLegends: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoBox(String title, String? value) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Increased font size
            Text(value ?? 'N/A', style: TextStyle(fontSize: 18)), // Increased font size
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoBox(String title, dynamic value) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align title to the left
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Increased font size
            SizedBox(height: 8), // Space between title and value
            Container(
              padding: EdgeInsets.all(12), // Padding inside the box
              color: Colors.lightGreen[100], // Background color for the data box
              child: Text(
                value?.toString() ?? 'N/A',
                style: TextStyle(fontSize: 20), // Increased font size for the value
              ),
            ),
          ],
        ),
      ),
    );
  }
}
