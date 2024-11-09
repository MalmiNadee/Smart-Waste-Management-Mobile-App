import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_waste/customer/PaymentPage.dart'; // Adjusted the import path
import 'package:smart_waste/main.dart';

// Mocks for Firebase
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockUser extends Mock implements User {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ensure test environment is set up

  // Initialize Firebase once for all tests
  await Firebase.initializeApp();

  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUpAll(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
  });

  setUp(() {
    // Setup common mock behaviors
    when(mockUser.email).thenReturn('test@example.com');
    when(mockAuth.currentUser).thenReturn(mockUser);
  });

  testWidgets('Should display user data when fetched successfully', (WidgetTester tester) async {
    final mockCollection = MockCollectionReference();
    final mockQuery = MockQuery();
    final mockQuerySnapshot = MockQuerySnapshot();
    final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.where('email', isEqualTo: 'test@example.com')).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Check if the widget contains welcome text
    expect(find.text('Welcome, User'), findsOneWidget);
  });

  testWidgets('Should add payment when form fields are valid', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Enter valid data into text fields
    await tester.enterText(find.byType(TextField).at(0), '100');
    await tester.enterText(find.byType(TextField).at(1), '2024-10-10');
    await tester.enterText(find.byType(TextField).at(2), 'Payment for service');

    // Tap on the "Make Payment" button
    await tester.tap(find.text('Make Payment'));
    await tester.pumpAndSettle();

    // Check if payment submission message appears
    expect(find.text('Payment Submitted Successfully'), findsOneWidget);
  });

  testWidgets('Should show payment list when payments exist', (WidgetTester tester) async {
    final mockCollection = MockCollectionReference();
    final mockQuery = MockQuery();
    final mockQuerySnapshot = MockQuerySnapshot();
    final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

    when(mockFirestore.collection('payments')).thenReturn(mockCollection);
    when(mockCollection.where('userEmail', isEqualTo: 'test@example.com')).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Ensure no "No payments found" message is displayed
    expect(find.text('No payments found'), findsNothing);
  });

  testWidgets('Should show error when payment submission fails', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Leave fields empty and try to submit payment
    await tester.tap(find.text('Make Payment'));
    await tester.pump();

    // Check if the error message appears
    expect(find.text('Please fill all fields'), findsOneWidget);
  });

  testWidgets('Should show no payments when user has no payment history', (WidgetTester tester) async {
    final mockCollection = MockCollectionReference();
    final mockQuery = MockQuery();
    final mockQuerySnapshot = MockQuerySnapshot();

    when(mockFirestore.collection('payments')).thenReturn(mockCollection);
    when(mockCollection.where('userEmail', isEqualTo: 'test@example.com')).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(mockQuerySnapshot.docs).thenReturn([]); // No payments

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Check if the "No payments found" message appears
    expect(find.text('No payments found'), findsOneWidget);
  });

  testWidgets('Should handle error when fetching user data fails', (WidgetTester tester) async {
    final mockCollection = MockCollectionReference();
    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.where('email', isEqualTo: 'test@example.com')).thenThrow(Exception('Database error'));

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(),
      ),
    );

    // Check if the error snackbar is shown
    expect(find.text('Error fetching user data: Database error'), findsOneWidget);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build your widget
    await tester.pumpWidget(MyApp());

    // Wait for the widget to settle
    await tester.pumpAndSettle();

    // Check if the counter starts at 0
    expect(find.text('0'), findsOneWidget);

    // Simulate button press to increment the counter
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Wait for the animation to complete

    // Verify the counter increment
    expect(find.text('1'), findsOneWidget);
  });
}
