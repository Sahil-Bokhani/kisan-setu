import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailScreen extends StatefulWidget {
  final String role;
  const UserDetailScreen({super.key, required this.role});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final aadharController = TextEditingController();
  final districtController = TextEditingController();
  final pincodeController = TextEditingController();

  final landSizeController = TextEditingController();
  final cropsController = TextEditingController();
  final kisanIdController = TextEditingController();

  final licenseController = TextEditingController();

  bool isLoading = false;

  Future<void> submitDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'aadhar': aadharController.text.trim(),
      'role': widget.role,
      'location': {
        'district': districtController.text.trim(),
        'pincode': pincodeController.text.trim(),
      },
    };

    if (widget.role == 'Farmer') {
      data.addAll({
        'landSize': landSizeController.text.trim(),
        'crops': cropsController.text.trim(),
        'kisanId': kisanIdController.text.trim(),
      });
    } else if (widget.role == 'Trader') {
      data['license'] = licenseController.text.trim();
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Details saved successfully")),
      );

      Navigator.pushReplacementNamed(context, '/${widget.role.toLowerCase()}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: aadharController,
                decoration: const InputDecoration(labelText: 'Aadhar Number'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pincode'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              if (widget.role == 'Farmer') ...[
                const Divider(),
                const Text(
                  "Farmer Specific",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: landSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Land Size (acres)',
                  ),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: cropsController,
                  decoration: const InputDecoration(labelText: 'Crops Grown'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: kisanIdController,
                  decoration: const InputDecoration(labelText: 'Kisan ID'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
              ],

              if (widget.role == 'Trader') ...[
                const Divider(),
                const Text(
                  "Trader Specific",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    labelText: 'APMC License Number',
                  ),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : submitDetails,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
