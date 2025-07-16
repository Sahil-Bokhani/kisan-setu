import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'checkout_screen.dart'; // Create this next

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> cartItems = {};
  bool isLoading = true;

  Map<String, dynamic> productDetails = {};
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final cartDoc =
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(user!.uid)
            .get();

    if (cartDoc.exists && cartDoc.data()?['items'] != null) {
      setState(() {
        cartItems = Map<String, dynamic>.from(cartDoc.data()!['items']);
        //print(cartItems);
        isLoading = false;
      });
    } else {
      setState(() {
        cartItems = {};
        isLoading = false;
      });
    }
  }

  Future<void> removeItem(String itemId) async {
    await FirebaseFirestore.instance.collection('cart').doc(user!.uid).update({
      'items.$itemId': FieldValue.delete(),
    });

    setState(() {
      cartItems.remove(itemId);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item removed from cart.")));
  }

  Future<List<Map<String, dynamic>>> fetchItemDetails() async {
    List<Map<String, dynamic>> products = [];
    double total = 0.0;
    Map<String, dynamic> detailsMap = {};

    //print(cartItems.keys);

    for (String itemId in cartItems.keys) {
      //print(itemId);
      final doc =
          await FirebaseFirestore.instance
              .collection('store_items')
              .doc(itemId.trim())
              .get();

      //print(doc.data());

      if (doc.exists) {
        final data = doc.data()!;

        // Safely get price and quantity
        final price =
            (data['price'] is int)
                ? (data['price'] as int).toDouble()
                : (data['price'] ?? 0.0);

        final quantity = (cartItems[itemId]['quantity'] ?? 1) as int;

        //print(quantity);

        total += price * quantity;

        final itemWithQuantity = {'id': doc.id, 'quantity': quantity, ...data};

        products.add(itemWithQuantity);
        detailsMap[itemId] = itemWithQuantity;
      }
    }

    // Save to state
    setState(() {
      productDetails = detailsMap;
      totalAmount = total;
    });

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty."))
              : FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchItemDetails(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            //print(item['id']);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading:
                                    item['imageUrl'] != null
                                        ? Image.network(
                                          item['imageUrl'],
                                          width: 50,
                                          fit: BoxFit.fill,
                                        )
                                        : const Icon(Icons.image),
                                title: Text(item['name'] ?? ''),
                                subtitle: Text(
                                  "₹${item['price']} • ${item['category']}",
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed:
                                      () => removeItem(item['id'].toString()),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CheckoutScreen(
                                      cartItems: cartItems,
                                      productDetails: productDetails,
                                      totalAmount: totalAmount,
                                    ),
                              ),
                            );
                          },
                          child: const Text("Proceed to Checkout"),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
