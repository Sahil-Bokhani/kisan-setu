import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AuctionBidScreen extends StatefulWidget {
  final String cropId;

  const AuctionBidScreen({super.key, required this.cropId});

  @override
  State<AuctionBidScreen> createState() => _AuctionBidScreenState();
}

class _AuctionBidScreenState extends State<AuctionBidScreen> {
  final TextEditingController bidController = TextEditingController();
  Map<String, dynamic>? cropData;

  @override
  void initState() {
    super.initState();
    fetchCropData();
  }

  Future<void> fetchCropData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('crops')
            .doc(widget.cropId)
            .get();

    if (doc.exists) {
      setState(() => cropData = doc.data());
    }
  }

  Future<void> placeBid() async {
    final bidAmount = double.tryParse(bidController.text);
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid bid amount")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('crops')
          .doc(widget.cropId)
          .collection('bids')
          .add({
            'amount': bidAmount,
            'timestamp': FieldValue.serverTimestamp(),
            'traderID': user.uid,
          });

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Bid Placed"),
              content: const Text("Your bid has been placed successfully."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/trader');
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error placing bid: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final endTime = cropData?['endAuction']?.toDate();
    final timeRemaining =
        endTime != null
            ? endTime.difference(DateTime.now())
            : const Duration(seconds: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Auction'),
        actions: const [Icon(Icons.notifications), SizedBox(width: 12)],
      ),
      body:
          cropData == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer
                    Text(
                      "⏳ Time Left: ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Crop Info
                    Text(
                      "${cropData!['cropType']} – ${cropData!['variety'] ?? 'N/A'}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Quantity: ${cropData!['quantity']} quintals"),
                    Text("Base Price: ₹${cropData!['basePrice']} /quintal"),
                    Text("Location: ${cropData!['location']}"),
                    const Divider(height: 24),

                    // Live Bids
                    const Text(
                      "📈 Top Bids",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('crops')
                                .doc(widget.cropId)
                                .collection('bids')
                                .orderBy('amount', descending: true)
                                .limit(5)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final bids = snapshot.data!.docs;

                          if (bids.isEmpty) {
                            return const Text("No bids yet");
                          }

                          return ListView.builder(
                            itemCount: bids.length,
                            itemBuilder: (context, index) {
                              final data =
                                  bids[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: Icon(
                                  index == 0 ? Icons.star : Icons.circle,
                                  color: index == 0 ? Colors.green : null,
                                ),
                                title: Text("₹${data['amount']}"),
                                subtitle: Text(
                                  "Trader ID: ${data['traderID']}",
                                ),
                                trailing: Text(
                                  DateFormat.jm().format(
                                    data['timestamp']?.toDate() ??
                                        DateTime.now(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    // Bid Field
                    TextField(
                      controller: bidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Enter Bid Amount (₹)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: placeBid,
                      child: const Text("Place Bid"),
                    ),
                  ],
                ),
              ),
    );
  }
}
