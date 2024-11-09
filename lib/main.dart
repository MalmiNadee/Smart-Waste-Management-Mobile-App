import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';

void main() async {
  // Ensures that Flutter is fully initialized before doing any work.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and catch any errors that occur during the process.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Print any Firebase initialization errors to the console for debugging.
    print("Error initializing Firebase: $e");
  }

  // Once Firebase is initialized, run the app.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Waste Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginScreen(), // Make sure CustomerHome.dart is correctly set up
    );
  }
}
