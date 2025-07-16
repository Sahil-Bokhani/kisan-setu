import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AuctionDetailScreen extends StatefulWidget {
  final String cropId;
  final Map<String, dynamic> cropData;

  const AuctionDetailScreen({
    super.key,
    required this.cropId,
    required this.cropData,
  });

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  late DateTime endTime;
  late Timer _timer;
  Duration timeLeft = Duration.zero;
  bool canEndEarly = false;

  @override
  void initState() {
    super.initState();
    endTime = widget.cropData['endAuction'].toDate();
    checkEndAuctionEligibility();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        timeLeft = endTime.difference(now);
      });
    });
  }

  void checkEndAuctionEligibility() {
    final now = DateTime.now();
    final bufferEnd = now.add(const Duration(minutes: 30));
    setState(() {
      canEndEarly = bufferEnd.isBefore(endTime);
    });
  }

  Future<void> endAuctionEarly() async {
    final newEndTime = DateTime.now().add(const Duration(minutes: 30));
    try {
      final cropDoc =
          await FirebaseFirestore.instance
              .collection('crops')
              .doc(widget.cropId)
              .get();
      final cropData = cropDoc.data();
      final farmerId = cropData?['farmerId'];

      if (farmerId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Farmer ID not found.")));
        return;
      }

      await FirebaseFirestore.instance
          .collection('crops')
          .doc(widget.cropId)
          .update({'endAuction': newEndTime, 'forceClosedByFarmer': true});

      await notifyFarmer(widget.cropId, farmerId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Auction will now end in 30 minutes.")),
      );

      setState(() {
        endTime = newEndTime;
        canEndEarly = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> notifyFarmer(String cropId, String farmerId) async {
    final bidsSnapshot =
        await FirebaseFirestore.instance
            .collection('crops')
            .doc(cropId)
            .collection('bids')
            .orderBy('amount', descending: true)
            .limit(1)
            .get();

    if (bidsSnapshot.docs.isEmpty) return;

    final topBid = bidsSnapshot.docs.first.data();
    final bidPrice = topBid['amount'];
    final bidderName = topBid['traderID'];

    final traderDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(bidderName)
            .get();

    final traderName = traderDoc.data()?['name'] ?? 'Trader';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(farmerId)
        .collection('notifications')
        .add({
          'title': 'Auction Ended',
          'message':
              'Your crop received the highest bid of ₹$bidPrice/qtl by $traderName.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'auction_result',
          'cropId': cropId,
        });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    final h = d.inHours.remainder(60).toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.cropData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Auction"),
        actions: const [Icon(Icons.notifications), SizedBox(width: 12)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Auction ends in: ${formatDuration(timeLeft)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                title: Text("Crop: ${crop['cropType']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (crop['variety'] != null)
                      Text("Variety: ${crop['variety']}"),
                    Text("Quantity: ${crop['quantity']} quintals"),
                    Text("Base Price: ₹${crop['basePrice']}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              "Live Bids:",
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bids = snapshot.data!.docs;

                  if (bids.isEmpty) {
                    return const Text("No bids yet.");
                  }

                  return ListView.builder(
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final bid = bids[index].data() as Map<String, dynamic>;
                      final isHighest = index == 0;

                      return ListTile(
                        leading: const Icon(Icons.monetization_on),
                        title: Text("₹${bid['amount']}"),
                        subtitle: Text(
                          "Bidder: ${bid['bidderName'] ?? 'Anonymous'}",
                        ),
                        tileColor: isHighest ? Colors.green.shade100 : null,
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            if (canEndEarly)
              ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle),
                label: const Text("End Auction Early"),
                onPressed: endAuctionEarly,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              )
            else
              const Text(
                "Cannot end early. Less than 30 mins remaining.",
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
