import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'complaint_detail_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String filterStatus = 'all';

  Stream<QuerySnapshot> fetchComplaints() {
    final collection = FirebaseFirestore.instance.collection('complaints');
    if (filterStatus == 'pending') {
      return collection.where('status', isEqualTo: 'pending').snapshots();
    } else if (filterStatus == 'resolved') {
      return collection.where('status', isEqualTo: 'resolved').snapshots();
    } else {
      return collection.snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => filterStatus = val),
            icon: const Icon(Icons.filter_list),
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'all', child: Text('All')),
                  PopupMenuItem(value: 'pending', child: Text('Pending')),
                  PopupMenuItem(value: 'resolved', child: Text('Resolved')),
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
            return const Center(child: Text('No complaints found.'));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final data = complaint.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final desc = data['description'] ?? '';
              final category = data['category'] ?? 'General';

              //print(data['userID']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📂 Category: $category",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc.length > 100
                                  ? "${desc.substring(0, 100)}..."
                                  : desc,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            status == 'Pending' ? '🟡 Pending' : '✅ Resolved',
                            style: TextStyle(
                              color:
                                  status == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ComplaintDetailScreen(
                                        complaintId: complaint.id,
                                        complaintData: data,
                                      ),
                                ),
                              );
                            },
                            child: const Text("View Details"),
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
