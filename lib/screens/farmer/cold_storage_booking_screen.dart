import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ColdStorageBookingScreen extends StatefulWidget {
  final Map<String, dynamic> storageData;

  const ColdStorageBookingScreen({super.key, required this.storageData});

  @override
  State<ColdStorageBookingScreen> createState() =>
      _ColdStorageBookingScreenState();
}

class _ColdStorageBookingScreenState extends State<ColdStorageBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController();

  String? selectedCrop;
  DateTime? bookingDate;
  DateTime? endDate;

  String farmerName = '';
  String district = '';
  bool isLoading = true;
  double calculatedRent = 0.0;

  final List<String> crops = [
    'Paddy',
    'Jowar',
    'Bajra',
    'Ragi',
    'Maize',
    'Tur (Arhar)',
    'Moong',
    'Urad',
    'Groundnut',
    'Sunflower Seed',
    'Soyabean (Yellow)',
    'Sesamum',
    'Nigerseed',
    'Cotton',
    'Wheat',
    'Barley',
    'Gram',
    'Masur (Lentil)',
    'Rapeseed & Mustard',
    'Safflower',
    'Copra',
    'Jute',
  ];

  @override
  void initState() {
    super.initState();
    fetchFarmerDetails();
  }

  Future<void> fetchFarmerDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        farmerName = data['name'] ?? '';
        district = data['location']?['district'] ?? '';
        isLoading = false;
      });
    }
  }

  void calculateRent() {
    if (bookingDate != null && endDate != null) {
      final days = endDate!.difference(bookingDate!).inDays + 1;
      final rentPerDay = widget.storageData['rent'] ?? 0;
      setState(() {
        calculatedRent = days * (rentPerDay as double);
      });
    }
  }

  Future<void> updateAvailableSpace(String storageUnitID, int quantity) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('cold_storages')
            .where('storageUnitID', isEqualTo: storageUnitID)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final docId = doc.id;

      final currentAvailable = doc['available_space'] ?? 0;
      final updatedAvailable = currentAvailable - quantity;

      await FirebaseFirestore.instance
          .collection('cold_storages')
          .doc(docId)
          .update({'available_space': updatedAvailable});
    } else {
      print("No storage unit found with ID: $storageUnitID");
    }
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (bookingDate == null || endDate == null || selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final storageID = widget.storageData['storageUnitID'];
    final quantity = int.parse(quantityController.text);

    final bookingData = {
      'farmerId': uid,
      'storageUnitID': storageID,
      'name': farmerName,
      'district': district,
      'cropType': selectedCrop,
      'quantity': quantity,
      'bookingDate': bookingDate,
      'endDate': endDate,
      'rent': calculatedRent,
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('cold_storage_bookings')
          .add(bookingData);

      await updateAvailableSpace(widget.storageData['storageUnitID'], quantity);

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Booking Confirmed"),
              content: const Text("Your cold storage booking is successful."),
            ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.storageData;

    return Scaffold(
      appBar: AppBar(title: const Text("Cold Storage Booking")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Storage Detail
                        Text(
                          storage['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Location: ${storage['location']?['district']}"),
                        Text("Capacity: ${storage['capacity']} quintals"),
                        Text(
                          "Available: ${storage['available_space']} quintals",
                        ),
                        Text("Rent: ₹${storage['rent']} per day"),
                        const Divider(height: 30),

                        const Text(
                          "Booking Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text("Name: $farmerName"),
                        Text("District: $district"),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: selectedCrop,
                          decoration: const InputDecoration(
                            labelText: "Crop Type *",
                          ),
                          items:
                              crops
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => selectedCrop = val),
                          validator:
                              (val) =>
                                  val == null ? 'Please select a crop' : null,
                        ),
                        TextFormField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: "Quantity (qtl) *",
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  bookingDate == null
                                      ? "Booking Date"
                                      : DateFormat.yMd().format(bookingDate!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 60),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      bookingDate = picked;
                                      calculateRent();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  endDate == null
                                      ? "End Date"
                                      : DateFormat.yMd().format(endDate!),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 60),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      endDate = picked;
                                      calculateRent();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Total Rent: ₹${calculatedRent.toStringAsFixed(2)}",
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: submitBooking,
                          child: const Text("Book Cold Storage"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
