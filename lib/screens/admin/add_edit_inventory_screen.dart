import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddEditInventoryScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddEditInventoryScreen({
    super.key,
    this.isEdit = false,
    this.existingData,
    this.docId,
  });

  @override
  State<AddEditInventoryScreen> createState() => _AddEditInventoryScreenState();
}

class _AddEditInventoryScreenState extends State<AddEditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  String selectedCategory = 'fertilizer';
  bool isAvailable = true;

  File? _imageFile;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.existingData != null) {
      final data = widget.existingData!;
      nameController.text = data['name'] ?? '';
      descController.text = data['description'] ?? '';
      priceController.text = data['price']?.toString() ?? '';
      quantityController.text = data['quantity']?.toString() ?? '';
      selectedCategory = data['category'] ?? 'fertilizer';
      isAvailable = data['isAvailable'] == true;
      imageUrl = data['imageUrl'];
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    final collection = FirebaseFirestore.instance.collection('store_items');
    final docRef =
        widget.isEdit && widget.docId != null
            ? collection.doc(widget.docId)
            : collection.doc();

    if (_imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('store_images')
          .child('${docRef.id}.jpg');

      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final data = {
      'name': nameController.text.trim(),
      'description': descController.text.trim(),
      'price': double.parse(priceController.text.trim()),
      'quantity': int.parse(quantityController.text.trim()),
      'category': selectedCategory,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl ?? '',
    };

    try {
      await docRef.set(data, SetOptions(merge: true));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEdit ? 'Item updated!' : 'Item added!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? "Edit Item" : "Add Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(imageUrl!, fit: BoxFit.cover)
                          : const Center(child: Text("Tap to select image")),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: const [
                  DropdownMenuItem(
                    value: 'fertilizer',
                    child: Text('Fertilizer'),
                  ),
                  DropdownMenuItem(
                    value: 'pesticide',
                    child: Text('Pesticide'),
                  ),
                  DropdownMenuItem(value: 'seeds', child: Text('Seeds')),
                ],
                onChanged: (val) => setState(() => selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: TextInputType.number,
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (Units)',
                ),
                keyboardType: TextInputType.number,
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              SwitchListTile(
                title: const Text("Available"),
                value: isAvailable,
                onChanged: (val) => setState(() => isAvailable = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submit,
                child: Text(widget.isEdit ? "Update" : "Add Item"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
