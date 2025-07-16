import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String docId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.docId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int selectedPack = 1;

  final farmerId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addToCart(String farmerId, String itemId) async {
    final cartRef = FirebaseFirestore.instance.collection('cart').doc(farmerId);

    await cartRef.set({
      'items': {
        '$itemId ': {'quantity': quantity},
      },
      'farmerId': farmerId,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to cart")));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productData;
    final basePrice = product['price'] ?? 0;
    final productID = widget.docId;

    double getPriceForPack(int packSize) {
      // Just an example pricing logic; replace with your actual logic
      return basePrice * packSize;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child:
                product['imageUrl'] != null
                    ? Image.network(product['imageUrl'], height: 180)
                    : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 60),
                    ),
          ),
          const SizedBox(height: 16),
          Text(
            product['name'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            product['category'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            "₹${(product['price'] as num).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Pack options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                [1, 10, 20].map((pack) {
                  return ChoiceChip(
                    label: Text(
                      "Pack of $pack\n₹${getPriceForPack(pack)}",
                      textAlign: TextAlign.center,
                    ),
                    selected: selectedPack == pack,
                    onSelected: (_) => setState(() => selectedPack = pack),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Quantity selector
          Row(
            children: [
              const Text(
                "Quantity:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (quantity > 1) setState(() => quantity--);
                },
              ),
              Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => quantity++),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          const Text(
            "Product Overview:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(product['description'] ?? "No description available."),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  addToCart(farmerId, productID);
                },
                child: const Text("Add to Cart"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final Map<String, dynamic> tempCartItems = {
                    productID: {
                      'quantity': quantity,
                    }, // selectedQuantity should be state-managed
                  };

                  final Map<String, dynamic> tempProductDetails = {
                    productID: {
                      'id': productID,
                      'name': product['name'],
                      'category': product['category'],
                      'price': product['price'],
                      'imageUrl': product['imageUrl'],
                      'quantity': quantity,
                    },
                  };

                  final double price =
                      (product['price'] is int)
                          ? (product['price'] as int).toDouble()
                          : (product['price'] ?? 0.0);
                  final totalAmount = quantity * price;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CheckoutScreen(
                            cartItems: tempCartItems,
                            productDetails: tempProductDetails,
                            totalAmount: totalAmount,
                          ),
                    ),
                  );
                },
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
