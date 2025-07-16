import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  final Map<String, dynamic> complaintData;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    required this.complaintData,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  String userName = "Loading...";
  final replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      final userId = widget.complaintData['userId'];
      //print(userId);
      if (userId != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
        setState(() {
          userName = userDoc.data()?['name'] ?? 'Unknown User';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
      });
    }
  }

  Future<void> markAsResolved() async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .update({'status': 'resolved'});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as resolved")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> sendReply() async {
    final reply = replyController.text.trim();
    if (reply.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.complaintData['userId'])
          .collection('notifications')
          .add({
            'title': 'Response to your complaint',
            'message': reply,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'admin_reply',
          });

      replyController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Reply sent")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.complaintData;
    final date = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedDate =
        date != null ? DateFormat.yMMMd().add_jm().format(date) : 'N/A';
    final isResolved = data['status'] == 'resolved';

    return Scaffold(
      appBar: AppBar(title: const Text("Complaint Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "📂 Category: ${data['category']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text("🧑‍💼 Submitted By: $userName"),
            Text("📅 Submitted On: $formattedDate"),
            const Divider(height: 24),
            const Text(
              "📝 Description:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              data['description'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Status: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    isResolved ? "Resolved" : "Pending",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isResolved ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              "Admin Reply",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: "Write a response...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: sendReply,
                  child: const Text("Send Reply"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isResolved ? null : markAsResolved,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Mark Resolved"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
