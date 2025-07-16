import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:intl/intl.dart';
import 'package:kisansetu/screens/trader/auction_bid_screen.dart';

class AllAuctionsScreen extends StatelessWidget {
  const AllAuctionsScreen({super.key});

  Stream<QuerySnapshot> fetchLiveAuctions() {
    final now = Timestamp.now();
    return FirebaseFirestore.instance
        .collection('crops')
        .where('isAuction', isEqualTo: true)
        .where('endAuction', isGreaterThan: now)
        .orderBy('endAuction')
        .snapshots();
  }

  String calculateTimeLeft(Timestamp endTime) {
    final now = DateTime.now();
    final end = endTime.toDate();
    final difference = end.difference(now);

    if (difference.isNegative) return "Ended";

    if (difference.inHours > 0) {
      return "${difference.inHours}h ${difference.inMinutes % 60}m left";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ${difference.inSeconds % 60}s left";
    } else {
      return "${difference.inSeconds}s left";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auction List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              // TODO: Implement filter dialog (future enhancement)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Filtering coming soon...")),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchLiveAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final crops = snapshot.data?.docs ?? [];

          if (crops.isEmpty) {
            return const Center(child: Text("No live auctions available."));
          }

          return ListView.builder(
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              final data = crop.data() as Map<String, dynamic>;

              final cropName = data['cropType'] ?? 'Crop';
              final variety = data['variety'] ?? '';
              final quantity = data['quantity']?.toString() ?? '0';
              final basePrice = data['basePrice']?.toString() ?? '0';
              final imageUrl = data['cropImageUrl'];
              final auctionID = crop.id;

              final Timestamp? endTime = data['endAuction'];
              final String timeLeft =
                  endTime != null ? calculateTimeLeft(endTime) : "No timer";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading:
                      imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(Icons.agriculture),
                  title: Text(
                    "$cropName ${variety.isNotEmpty ? "– $variety" : ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quantity: $quantity quintals"),
                      Text("Base Price: ₹$basePrice/qtl"),
                      Text(
                        "⏱️ $timeLeft",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuctionBidScreen(cropId: auctionID),
                        ),
                      );
                    },
                    child: const Text("Bid"),
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
