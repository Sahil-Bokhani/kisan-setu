import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final subjectController = TextEditingController();
  final descController = TextEditingController();
  String selectedCategory = 'General';

  String userName = '';
  String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        userName = userDoc['name'] ?? 'User';
        isLoading = false;
      });
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'name': userName,
        'subject': subjectController.text.trim(),
        'category': selectedCategory,
        'description': descController.text.trim(),
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: const Text("Complaint Submitted"),
              content: const Text(
                "Your complaint has been raised successfully.",
              ),
            ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.popUntil(context, ModalRoute.withName('/farmer'));
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Raise Complaint"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/my_complaints');
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text("Name: $userName"),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(labelText: "Subject"),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: "Category",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'Order',
                            child: Text('Order Issue'),
                          ),
                          DropdownMenuItem(
                            value: 'Auction',
                            child: Text('Auction Dispute'),
                          ),
                          DropdownMenuItem(
                            value: 'Storage',
                            child: Text('Cold Storage'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: submitComplaint,
                        child: const Text("Submit Complaint"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
