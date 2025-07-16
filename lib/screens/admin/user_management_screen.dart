import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String selectedRole = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search logic
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  ["All", "Farmer", "Trader", "Government Officer"]
                      .map(
                        (role) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ChoiceChip(
                            label: Text(role),
                            selected: selectedRole == role,
                            onSelected: (_) {
                              setState(() {
                                selectedRole = role;
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  selectedRole == "All"
                      ? FirebaseFirestore.instance
                          .collection("users")
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection("users")
                          .where("role", isEqualTo: selectedRole)
                          .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final isApproved = data['kycApproved'] == true;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(data['name'] ?? 'Unnamed User'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone: ${data['phone']}"),
                            Text("Location: ${data['location']?['district']}"),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (!isApproved)
                              ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.id)
                                      .update({'kycApproved': true});
                                },
                                child: const Text("Approve"),
                              )
                            else
                              const Text(
                                "✔ Approved",
                                style: TextStyle(color: Colors.red),
                              ),
                            IconButton(
                              icon: const Icon(Icons.block, color: Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.id)
                                    .delete();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UserDetailAdminScreen(
                                          userId: user.id,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
