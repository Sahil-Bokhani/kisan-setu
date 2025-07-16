import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String selectedFilter = "All";

  Stream<QuerySnapshot> fetchComplaints() {
    final baseQuery = FirebaseFirestore.instance
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (selectedFilter == "All") {
      return baseQuery.snapshots();
    } else {
      return baseQuery.where('status', isEqualTo: selectedFilter).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Complaints"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() => selectedFilter = value);
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'All', child: Text("All")),
                  PopupMenuItem(value: 'Pending', child: Text("Pending")),
                  PopupMenuItem(value: 'Resolved', child: Text("Resolved")),
                  PopupMenuItem(value: 'Rejected', child: Text("Rejected")),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data?.docs ?? [];

          if (complaints.isEmpty) {
            return const Center(child: Text("No complaints found."));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final data = complaints[index].data() as Map<String, dynamic>;

              final timestamp =
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate().toString()
                      : "N/A";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Subject: ${data['subject']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Category: ${data['category']}"),
                      const SizedBox(height: 8),
                      Text("Description: ${data['description']}"),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Status: ${data['status']}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  data['status'] == 'Pending'
                                      ? Colors.orange
                                      : data['status'] == 'Resolved'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                          Text(
                            timestamp.split(".")[0],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
