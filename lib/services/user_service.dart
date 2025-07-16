import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//import '../screens/farmer/farmer_dashboard.dart';
//import '../screens/trader/trader_dashboard.dart';
//import '../screens/admin/admin_dashboard.dart';
import '../screens/role_selection_screen.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> handleUser(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || !doc.data()!.containsKey('role')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleSelectionScreen(user: user)),
      );
      return;
    }

    final role = doc['role'];
    if (role == 'Farmer') {
      Navigator.pushReplacementNamed(context, '/farmer');
    } else if (role == 'Trader') {
      Navigator.pushReplacementNamed(context, '/trader');
    } else if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown role. Please contact support.')),
      );
    }
  }
}
