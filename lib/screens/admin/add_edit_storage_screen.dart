import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEditStorageScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddEditStorageScreen({
    super.key,
    required this.isEdit,
    this.existingData,
    this.docId,
  });

  @override
  State<AddEditStorageScreen> createState() => _AddEditStorageScreenState();
}

class _AddEditStorageScreenState extends State<AddEditStorageScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final pincodeController = TextEditingController();
  final capacityController = TextEditingController();
  final rentController = TextEditingController();
  String status = 'active';
  bool isAvailable = true;

  File? imageFile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.existingData != null) {
      final data = widget.existingData!;
      nameController.text = data['name'] ?? '';
      cityController.text = data['location']?['city'] ?? '';
      districtController.text = data['location']?['district'] ?? '';
      pincodeController.text = data['location']?['pincode'] ?? '';
      capacityController.text = data['capacity'].toString();
      rentController.text = data['rent'].toString();
      status = data['status'] ?? 'active';
      isAvailable = data['isAvailable'] ?? true;
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<String?> uploadImage(String docId) async {
    if (imageFile == null) return widget.existingData?['imageUrl'];
    final ref = FirebaseStorage.instance.ref('storage_images/$docId.jpg');
    await ref.putFile(imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> saveStorage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef =
          widget.isEdit
              ? firestore.collection('cold_storages').doc(widget.docId)
              : firestore.collection('cold_storages').doc();

      final imageUrl = await uploadImage(docRef.id);

      final data = {
        'name': nameController.text.trim(),
        'location': {
          'city': cityController.text.trim(),
          'district': districtController.text.trim(),
          'pincode': pincodeController.text.trim(),
        },
        'capacity': int.parse(capacityController.text),
        'available_space':
            widget.isEdit
                ? (widget.existingData?['available_space'] as int? ??
                    int.parse(capacityController.text))
                : int.parse(capacityController.text),
        'rent': double.parse(rentController.text),
        'status': status,
        'isAvailable': isAvailable,
        'imageUrl': imageUrl,
        'storageUnitID':
            widget.isEdit
                ? widget.existingData!['storageUnitID']
                : "SID${docRef.id.substring(0, 5).toUpperCase()}",
      };

      await docRef.set(data);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEdit ? "Storage Updated" : "Storage Added"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Storage Unit" : "Add Storage Unit"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child:
                    imageFile != null
                        ? Image.file(imageFile!, height: 160, fit: BoxFit.cover)
                        : widget.isEdit &&
                            widget.existingData?['imageUrl'] != null
                        ? Image.network(
                          widget.existingData!['imageUrl'],
                          height: 160,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          height: 160,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text("Tap to upload image"),
                          ),
                        ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Storage Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity (quintals)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: rentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rent (₹ per day)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text("Active")),
                  DropdownMenuItem(value: 'inactive', child: Text("Inactive")),
                ],
                onChanged: (val) => setState(() => status = val!),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              SwitchListTile(
                value: isAvailable,
                onChanged: (val) => setState(() => isAvailable = val),
                title: const Text("Is Available?"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : saveStorage,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : Text(widget.isEdit ? "Update" : "Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
