import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> myBids = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyBids();
  }

  Future<void> fetchMyBids() async {
    final cropSnapshot =
        await FirebaseFirestore.instance.collection('crops').get();

    List<Map<String, dynamic>> bidList = [];

    for (var cropDoc in cropSnapshot.docs) {
      final bidsSnapshot =
          await FirebaseFirestore.instance
              .collection('crops')
              .doc(cropDoc.id)
              .collection('bids')
              .where('traderID', isEqualTo: userId)
              .get();

      if (bidsSnapshot.docs.isNotEmpty) {
        final cropData = cropDoc.data();
        final bidData = bidsSnapshot.docs.first.data();
        bidList.add({
          'cropId': cropDoc.id,
          'cropType': cropData['cropType'],
          'variety': cropData['variety'],
          'quantity': cropData['quantity'],
          'basePrice': cropData['basePrice'],
          'isAuction': cropData['isAuction'],
          'endAuction': cropData['endAuction'],
          'imageUrl': cropData['cropImageUrl'],
          'yourBidAmount': bidData['amount'],
        });
      }
    }

    setState(() {
      myBids = bidList;
      isLoading = false;
    });
  }

  String formatAuctionStatus(bool isLive, Timestamp? endTime) {
    if (!isLive) return "Ended";
    if (endTime != null && endTime.toDate().isBefore(DateTime.now()))
      return "Ended";
    return "Live";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bids")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : myBids.isEmpty
              ? const Center(child: Text("No bids placed yet."))
              : ListView.builder(
                itemCount: myBids.length,
                itemBuilder: (context, index) {
                  final bid = myBids[index];
                  final status = formatAuctionStatus(
                    bid['isAuction'] ?? false,
                    bid['endAuction'],
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading:
                          bid['imageUrl'] != null
                              ? Image.network(bid['imageUrl'], width: 60)
                              : const Icon(Icons.agriculture),
                      title: Text(bid['cropType'] ?? 'Crop'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Variety: ${bid['variety'] ?? 'N/A'}"),
                          Text("Quantity: ${bid['quantity']} qtl"),
                          Text("Base Price: ₹${bid['basePrice']}"),
                          Text("Your Bid: ₹${bid['yourBidAmount']}"),
                          Text("Auction Status: $status"),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
