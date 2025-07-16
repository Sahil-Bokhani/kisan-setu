import 'package:flutter/material.dart';
import 'package:kisansetu/services/market_price_service.dart';
import 'package:intl/intl.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  late Future<List<MarketPrice>> _prices;

  @override
  void initState() {
    super.initState();
    _prices = MarketPriceService.fetchGujaratPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Market Prices (Gujarat)')),
      body: FutureBuilder<List<MarketPrice>>(
        future: _prices,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final data = snap.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final p = data[i];
              return ListTile(
                title: Text('${p.crop} @ ${p.modalPrice.toStringAsFixed(0)} ₹'),
                subtitle: Text(
                  '${p.mandi}, on ${DateFormat.yMMMd().format(p.date)}',
                ),
                trailing: Icon(Icons.trending_up),
              );
            },
          );
        },
      ),
    );
  }
}
