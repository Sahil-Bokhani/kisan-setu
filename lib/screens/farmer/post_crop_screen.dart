import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCropScreen extends StatefulWidget {
  const PostCropScreen({super.key});

  @override
  State<PostCropScreen> createState() => _PostCropScreenState();
}

class _PostCropScreenState extends State<PostCropScreen> {
  final _formKey = GlobalKey<FormState>();

  File? cropImageFile;
  File? gradeCertificateFile;
  bool isLoading = false;
  bool isAuction = false;
  DateTime? auctionStart;
  DateTime? auctionEnd;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(bool isCropImage) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isCropImage) {
          cropImageFile = File(picked.path);
        } else {
          gradeCertificateFile = File(picked.path);
        }
      });
    }
  }

  Future<String> uploadFileToStorage(File file, String folderName) async {
    final user = FirebaseAuth.instance.currentUser;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = file.path.split('/').last;

    final ref = FirebaseStorage.instance.ref().child(
      '$folderName/${user!.uid}/$timestamp-$fileName',
    );

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<DateTime?> showDateTimePicker() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Controllers
  String selectedCrop = '';
  final varietyController = TextEditingController();
  final quantityController = TextEditingController();
  final basePriceController = TextEditingController();
  final locationController = TextEditingController();
  final mandiController = TextEditingController();

  List<String> cropOptions = [
    "Paddy",
    "Jowar",
    "Bajra",
    "Ragi",
    "Maize",
    "Tur (Arhar)",
    "Moong",
    "Urad",
    "Groundnut",
    "Sunflower Seed",
    "Soyabean (Yellow)",
    "Sesamum",
    "Nigerseed",
    "Cotton",
    "Wheat",
    "Barley",
    "Gram",
    "Masur (Lentil)",
    "Rapeseed & Mustard",
    "Safflower",
    "Copra",
    "Jute",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Your Crop")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Crop Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Crop Type *"),
                value: selectedCrop.isEmpty ? null : selectedCrop,
                items:
                    cropOptions.map((crop) {
                      return DropdownMenuItem(value: crop, child: Text(crop));
                    }).toList(),
                onChanged: (val) => setState(() => selectedCrop = val ?? ''),
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              TextFormField(
                controller: varietyController,
                decoration: const InputDecoration(labelText: "Variety"),
              ),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity (in Quintals) *",
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              TextFormField(
                controller: basePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Base Price (₹/Quintal) *",
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Farm Location *"),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              TextFormField(
                controller: mandiController,
                decoration: const InputDecoration(labelText: "Mandi"),
              ),

              const SizedBox(height: 16),
              Text(
                "Upload Crop Image *",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Choose Crop Image"),
                onPressed: () => pickImage(true),
              ),
              if (cropImageFile != null)
                Text("Image Selected: ${cropImageFile!.path.split('/').last}"),

              const SizedBox(height: 16),
              Text(
                "KisanSetu Certificate (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Choose Certificate"),
                onPressed: () => pickImage(false),
              ),
              if (gradeCertificateFile != null)
                Text(
                  "File Selected: ${gradeCertificateFile!.path.split('/').last}",
                ),

              SwitchListTile(
                title: const Text("Enable Auction?"),
                value: isAuction,
                onChanged: (val) => setState(() => isAuction = val),
              ),

              if (isAuction) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    auctionStart == null
                        ? "Select Auction Start Time"
                        : "Start: ${auctionStart.toString()}",
                  ),
                  onPressed: () async {
                    final picked = await showDateTimePicker();
                    if (picked != null) {
                      setState(() => auctionStart = picked);
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    auctionEnd == null
                        ? "Select Auction End Time"
                        : "End: ${auctionEnd.toString()}",
                  ),
                  onPressed: () async {
                    final picked = await showDateTimePicker();
                    if (picked != null) {
                      setState(() => auctionEnd = picked);
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (cropImageFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select a Crop Image"),
                      ),
                    );
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final cropImageUrl = await uploadFileToStorage(
                      cropImageFile!,
                      "crops",
                    );
                    String? certificateUrl;
                    if (gradeCertificateFile != null) {
                      certificateUrl = await uploadFileToStorage(
                        gradeCertificateFile!,
                        "certificates",
                      );
                    }

                    final cropData = {
                      'farmerId': user.uid,
                      'cropType': selectedCrop,
                      'variety': varietyController.text.trim(),
                      'quantity': int.parse(quantityController.text.trim()),
                      'basePrice': double.parse(
                        basePriceController.text.trim(),
                      ),
                      'location': locationController.text.trim(),
                      'mandi': mandiController.text.trim(),
                      'cropImageUrl': cropImageUrl,
                      'gradeCertificateUrl': certificateUrl ?? '',
                      'createdAt': FieldValue.serverTimestamp(),
                      'isAuction': isAuction,
                      'startAuction': isAuction ? auctionStart : null,
                      'endAuction': isAuction ? auctionEnd : null,
                    };

                    await FirebaseFirestore.instance
                        .collection('crops')
                        .add(cropData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Crop Posted Successfully")),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
