import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kisansetu/screens/user_detail_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final User user;
  const RoleSelectionScreen({super.key, required this.user});

  void saveRole(BuildContext context, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'uid': user.uid,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Redirect after saving role
    if (role == 'Farmer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserDetailScreen(role: role)),
      );
    } else if (role == 'Trader') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserDetailScreen(role: role)),
      );
    } else if (role == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserDetailScreen(role: role)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Column(
        children: [
          ListTile(
            title: const Text("Farmer"),
            leading: const Icon(Icons.agriculture),
            onTap: () => saveRole(context, 'Farmer'),
          ),
          ListTile(
            title: const Text("Trader"),
            leading: const Icon(Icons.store),
            onTap: () => saveRole(context, 'Trader'),
          ),
          ListTile(
            title: const Text("Admin"),
            leading: const Icon(Icons.admin_panel_settings),
            onTap: () => saveRole(context, 'Admin'),
          ),
        ],
      ),
    );
  }
}
