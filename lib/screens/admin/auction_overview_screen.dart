import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auction_detail_screen.dart';

class AuctionOverviewScreen extends StatefulWidget {
  const AuctionOverviewScreen({super.key});

  @override
  State<AuctionOverviewScreen> createState() => _AuctionOverviewScreenState();
}

class _AuctionOverviewScreenState extends State<AuctionOverviewScreen> {
  String _selectedFilter = 'All'; // All, Live, Ended

  Stream<QuerySnapshot> fetchAuctions() {
    Query query = FirebaseFirestore.instance
        .collection('crops')
        .where('isAuction', whereIn: [true, false]);

    if (_selectedFilter == 'Live') {
      query = query.where('isAuction', isEqualTo: true);
    } else if (_selectedFilter == 'Ended') {
      query = query.where('isAuction', isEqualTo: false);
    }

    return query.snapshots();
  }

  Future<String> fetchFarmerName(String farmerId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(farmerId)
            .get();
    return doc.data()?['name'] ?? 'Farmer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Oversight'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'All', child: Text('All')),
                  const PopupMenuItem(value: 'Live', child: Text('Live')),
                  const PopupMenuItem(value: 'Ended', child: Text('Ended')),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final crops = snapshot.data?.docs ?? [];

          // Filter only those with valid auction data
          final auctionCrops =
              crops.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['startAuction'] != null &&
                    data['endAuction'] != null;
              }).toList();

          if (crops.isEmpty) {
            return const Center(child: Text("No auctions found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: auctionCrops.length,
            itemBuilder: (context, index) {
              final data = auctionCrops[index].data() as Map<String, dynamic>;
              final docId = auctionCrops[index].id;

              final cropType = data['cropType'] ?? '';
              final variety = data['variety'] ?? '';
              final quantity = data['quantity'] ?? 0;
              final basePrice = data['basePrice'] ?? 0;
              final isLive = data['isAuction'] ?? false;
              final farmerId = data['farmerId'] ?? '';

              return FutureBuilder<String>(
                future: fetchFarmerName(farmerId),
                builder: (context, snapshot) {
                  final farmerName = snapshot.data ?? 'Farmer';

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🌾 Crop - $cropType ${variety != '' ? ": $variety" : ""}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("👨‍🌾 Farmer - $farmerName"),
                          Text("📦 Quantity - $quantity Quintals"),
                          Text("💰 Base Price - ₹$basePrice"),
                          FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('crops')
                                    .doc(docId)
                                    .collection('bids')
                                    .orderBy('amount', descending: true)
                                    .limit(1)
                                    .get(),
                            builder: (context, bidSnapshot) {
                              final topBid =
                                  bidSnapshot.data?.docs.firstOrNull?.data()
                                      as Map<String, dynamic>?;

                              final highestBid = topBid?['amount'] ?? "—";

                              return Text("📈 Highest Bid - ₹$highestBid");
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "⏱ Status - ${isLive ? "🟢 Live" : "🔴 Ended"}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isLive ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AuctionDetailScreen(
                                          cropId: docId,
                                          cropData: data,
                                        ),
                                  ),
                                );
                              },
                              child: const Text("View Details"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
