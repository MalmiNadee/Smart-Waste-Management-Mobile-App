import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Singleton Class for Firebase Services
class FirebaseService {
  static late final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal(); 

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  // Variables for user data and loading state
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the page loads
  }

  // Fetch user data from Firestore using Singleton FirebaseService
  Future<void> _fetchUserData() async {
    String? userEmail = FirebaseService().auth.currentUser?.email;

    if (userEmail != null) {
      try {
        QuerySnapshot snapshot = await FirebaseService()
            .firestore
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _userData = snapshot.docs.first.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        } else {
          _handleEmptyUserData();
        }
      } catch (error) {
        _handleError('Error fetching user data: $error');
      }
    } else {
      _handleEmptyUserData();
    }
  }

  
  void _handleEmptyUserData() {
    setState(() {
      _isLoading = false;
      _userData = {};
    });
    _showSnackBar('No user data found.');
  }

  // Function to handle and log errors
  void _handleError(String errorMessage) {
    setState(() {
      _isLoading = false;
    });
    _showErrorSnackBar(errorMessage);
    print('Error: $errorMessage'); // Logging for debugging
  }

  // Add a new payment to Firestore
  Future<void> _makePayment() async {
    if (_areFieldsValid()) {
      try {
        String userEmail = FirebaseService().auth.currentUser!.email!;
        await FirebaseService().firestore.collection('payments').add({
          'price': _priceController.text,
          'date': _dateController.text,
          'summary': _summaryController.text,
          'userEmail': userEmail,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _clearInputFields();
        _showSnackBar('Payment Submitted Successfully');
      } catch (error) {
        _handleError('Error making payment: $error');
      }
    } else {
      _showSnackBar('Please fill all fields');
    }
  }

  // Delete a payment by document ID
  Future<void> _deletePayment(String paymentId) async {
    try {
      await FirebaseService().firestore.collection('payments').doc(paymentId).delete();
      _showSnackBar('Payment Deleted');
    } catch (error) {
      _handleError('Error deleting payment: $error');
    }
  }

  // Helper function to validate form fields
  bool _areFieldsValid() {
    return _priceController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _summaryController.text.isNotEmpty;
  }

  // Helper function to clear input fields
  void _clearInputFields() {
    _priceController.clear();
    _dateController.clear();
    _summaryController.clear();
  }

 
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
        backgroundColor: Color(0xFF66BB6A),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      color: Color(0xFFA5D6A7),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_userData != null && _userData!.isNotEmpty) _buildWelcomeText(),
          _buildInputField(_priceController, 'Enter Price', TextInputType.number),
          _buildDateInputField(),
          _buildInputField(_summaryController, 'Enter Summary', TextInputType.multiline, maxLines: 3),
          SizedBox(height: 16),
          _buildMakePaymentButton(),
          SizedBox(height: 20),
          _buildPaymentList(),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        'Welcome, ${_userData!['name'] ?? 'User'}',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDateInputField() {
    return _buildInputField(
      _dateController,
      'Select Date',
      TextInputType.datetime,
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (selectedDate != null) {
          setState(() {
            _dateController.text = "${selectedDate.toLocal()}".split(' ')[0]; // YYYY-MM-DD
          });
        }
      },
    );
  }

  Widget _buildMakePaymentButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
      onPressed: _makePayment,
      child: Text(
        'Make Payment',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentList() {
    String userEmail = FirebaseService().auth.currentUser?.email ?? '';
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService()
            .firestore
            .collection('payments')
            .where('userEmail', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No payments found'));
          }

          var paymentDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: paymentDocs.length,
            itemBuilder: (context, index) {
              var payment = paymentDocs[index];
              return _buildPaymentCard(payment);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(QueryDocumentSnapshot payment) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        title: Text('Price: ${payment['price']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${payment['date']}'),
            Text('Summary: ${payment['summary']}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.black),
          onPressed: () {
            _deletePayment(payment.id);
          },
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, TextInputType keyboardType,
      {int maxLines = 1, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
