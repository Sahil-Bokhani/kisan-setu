// ignore_for_file: deprecated_member_use

import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:xml/xml.dart' as xml;

class MarketPriceService {
  static const _apiKey =
      '579b464db66ec23bdd000001f37cf80bcc404984532440ab0b35de5f';

  static Future<List<MarketPrice>> fetchGujaratPrices() async {
    final uri = Uri.parse(
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=$_apiKey&format=json&filters[state]=Gujarat&limit=100',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('API Error');

    final jsonData = json.decode(res.body);
    final List records = jsonData['records'];

    return records.map((record) {
      return MarketPrice(
        crop: record['commodity'] ?? '',
        mandi: record['market'] ?? '',
        modalPrice: double.tryParse(record['modal_price'] ?? '') ?? 0.0,
        minPrice: double.tryParse(record['min_price'] ?? '') ?? 0.0,
        maxPrice: double.tryParse(record['max_price'] ?? '') ?? 0.0,
        date: DateTime.tryParse(record['price_date'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }
}

class MarketPrice {
  final String crop, mandi;
  final double modalPrice, minPrice, maxPrice;
  final DateTime date;
  MarketPrice({
    required this.crop,
    required this.mandi,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.date,
  });
}
