import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String farmerName = '';
  String winnerName = '';
  bool isEnded = false;

  @override
  void initState() {
    super.initState();
    final endTimestamp = widget.cropData['endAuction'];
    endTime = endTimestamp.toDate();
    _startTimer();
    _fetchFarmerAndWinner();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        timeLeft = endTime.difference(now);
        isEnded = timeLeft.isNegative;
      });
    });
  }

  Future<void> _fetchFarmerAndWinner() async {
    final farmerId = widget.cropData['farmerID'];
    if (farmerId != null) {
      final farmerSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get();
      farmerName = farmerSnap.data()?['name'] ?? 'Unknown Farmer';
    }

    final bidsSnap =
        await FirebaseFirestore.instance
            .collection('crops')
            .doc(widget.cropId)
            .collection('bids')
            .orderBy('amount', descending: true)
            .limit(1)
            .get();

    if (bidsSnap.docs.isNotEmpty) {
      final topBid = bidsSnap.docs.first.data();
      final traderId = topBid['traderID'];
      final traderSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(traderId)
              .get();
      winnerName = traderSnap.data()?['name'] ?? 'Unknown Trader';
    }

    if (mounted) setState(() {});
  }

  String formatDuration(Duration d) {
    if (d.isNegative) return "Auction Ended";
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.cropData;

    return Scaffold(
      appBar: AppBar(title: const Text("Auction Detail")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Crop: ${crop['cropType']} – ${crop['variety'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Farmer: $farmerName"),
            Text("Quantity: ${crop['quantity']} quintals"),
            Text("Base Price: ₹${crop['basePrice']}"),
            Text("Location: ${crop['location']}"),
            Text("Status: ${crop['isAuction'] == true ? "Live" : "Ended"}"),
            const SizedBox(height: 4),
            Text(
              "Auction Duration: ${crop['startAuction']?.toDate()} to ${crop['endAuction']?.toDate()}",
            ),
            if (isEnded && winnerName.isNotEmpty)
              Text(
                "Winner: $winnerName",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

            const Divider(height: 32),
            Center(
              child: Text(
                "⏱️ ${formatDuration(timeLeft)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "Live Bids",
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
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final bids = snapshot.data!.docs;

                  if (bids.isEmpty) {
                    return const Text("No bids yet.");
                  }

                  return ListView.builder(
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final bid = bids[index].data() as Map<String, dynamic>;
                      final bidAmount = bid['amount'];
                      final traderId = bid['traderID'];

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(traderId)
                                .get(),
                        builder: (context, snapshot) {
                          final traderName =
                              snapshot.data?.data() is Map
                                  ? (snapshot.data!.data() as Map)['name'] ??
                                      'Trader'
                                  : 'Trader';

                          return ListTile(
                            title: Text("₹$bidAmount"),
                            subtitle: Text("Bidder: $traderName"),
                            tileColor:
                                index == 0 ? Colors.green.shade100 : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
