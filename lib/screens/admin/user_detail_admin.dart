import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailAdminScreen extends StatelessWidget {
  final String userId;
  const UserDetailAdminScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) return const Center(child: Text("User not found."));

          final role = data['role'] ?? 'Unknown';
          final location = data['location'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                buildInfoTile("👤 Name", data['name']),
                buildInfoTile("📧 Email", data['email']),
                buildInfoTile("📱 Phone", data['phone']),
                buildInfoTile("🔰 Role", role),
                buildInfoTile("🆔 Aadhar", data['aadhar']),
                buildInfoTile("📍 District", location['district']),
                buildInfoTile("📮 Pincode", location['pincode']),
                const SizedBox(height: 20),

                if (role == "Farmer") ...[
                  const Divider(),
                  const Text(
                    "🌾 Farmer Specific",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  buildInfoTile("Land Size", "${data['landSize']} acres"),
                  buildInfoTile("Crops Grown", data['crops']),
                  buildInfoTile("Kisan ID", data['kisanId']),
                ],
                if (role == "Trader") ...[
                  const Divider(),
                  const Text(
                    "🛒 Trader Specific",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  buildInfoTile("APMC License No", data['license']),
                ],
                const Divider(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text(
                      "✅ KYC Approved: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      data['kycApproved'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          data['kycApproved'] == true
                              ? Colors.green
                              : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInfoTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value != null && value.toString().trim().isNotEmpty
                  ? value.toString()
                  : "N/A",
            ),
          ),
        ],
      ),
    );
  }
}
