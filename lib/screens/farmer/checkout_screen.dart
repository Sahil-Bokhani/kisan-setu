import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> cartItems;
  final Map<String, dynamic> productDetails;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.productDetails,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final houseController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final pincodeController = TextEditingController();

  String paymentMethod = 'Cash-on-Delivery';
  String billingName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFarmerName();
  }

  Future<void> fetchFarmerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();

    setState(() {
      billingName = data?['name'] ?? '';
      isLoading = false;
    });
  }

  Future<void> placeOrder() async {
    final orderRef =
        FirebaseFirestore.instance.collection('input_orders').doc();

    // Prepare order data
    final orderData = {
      'farmerId': FirebaseAuth.instance.currentUser!.uid,
      'items': widget.cartItems,
      'totalAmount': widget.totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'deliveryAddress': {
        'house': houseController.text.trim(),
        'street': streetController.text.trim(),
        'city': cityController.text.trim(),
        'pincode': pincodeController.text.trim(),
      },
    };

    try {
      // 1. Save order
      await orderRef.set(orderData);

      // 2. Update stock
      for (final itemId in widget.cartItems.keys) {
        //print(itemId);
        final quantityOrdered = widget.cartItems[itemId]['quantity'];

        final itemDoc =
            await FirebaseFirestore.instance
                .collection('store_items')
                .doc(itemId.trim())
                .get();
        final currentStock = itemDoc['quantity'] ?? 0;

        print(currentStock);

        await FirebaseFirestore.instance
            .collection('store_items')
            .doc(itemId.trim())
            .update({'quantity': currentStock - quantityOrdered});
      }

      final user = FirebaseAuth.instance.currentUser;

      // 3. Clear cart
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(user!.uid)
          .delete();

      // 4. Show success and redirect
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text("Order Placed"),
              content: Text("Your order has been placed successfully."),
            ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.popUntil(context, ModalRoute.withName('/farmer'));
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error placing order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "🧾 Bill Summary",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.productDetails.entries.map((entry) {
                final data = entry.value as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['name']),
                  trailing: Text("₹${data['price']}"),
                );
              }),
              Divider(),
              ListTile(
                title: const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "₹${widget.totalAmount}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "📦 Billing Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Billing Name: $billingName"),
              TextFormField(
                controller: houseController,
                decoration: const InputDecoration(labelText: "House No."),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: streetController,
                decoration: const InputDecoration(labelText: "Street"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: pincodeController,
                decoration: const InputDecoration(labelText: "Pincode"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                items: const [
                  DropdownMenuItem(
                    value: "Cash-on-Delivery",
                    child: Text("Cash-on-Delivery"),
                  ),
                  DropdownMenuItem(value: "UPI", child: Text("UPI")),
                  DropdownMenuItem(value: "Wallet", child: Text("Wallet")),
                ],
                onChanged: (val) => setState(() => paymentMethod = val!),
                decoration: const InputDecoration(labelText: "Payment Method"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: placeOrder,
                child: const Text("Place Order"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
