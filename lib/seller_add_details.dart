import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:trade_seller/seller_item_widget.dart';

class AddDetails extends StatefulWidget {
  final Item? item;

  const AddDetails({Key? key, this.item}) : super(key: key);

  @override
  _AddDetailsState createState() => _AddDetailsState();
}

class _AddDetailsState extends State<AddDetails> {
  final _itemPriceController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Dropdown items
  List<String> itemNames = [
    "Kale",
    "Spinach",
    "Spirulina",
    "Chlorella",
    "Pears",
    "Grapes",
    "Berries",
    "Pomegranates",
    "Arugula",
    "Collard Greens",
    "Mustard Greens",
    "Radish Greens",
    "Swiss Chard",
    "Turnip Greens",
    "Avocados",
    "Bananas",
    "Cantaloupe",
    "Cherries",
    "Figs",
    "Grapefruit",
    "Honeydew",
    "Kiwi",
    "Mangoes",
    "Nectarines",
    "Oranges",
    "Papaya",
    "Peaches",
    "Plums",
    "Pineapple",
    "Raspberries",
    "Strawberries",
    "Tangerines",
    "Watermelon",
    "Moringa"
  ];
  List<String> itemTypes = [
    "Leafy Greens",
    "Algae",
    "Fruits",
    "Vegetables",
    "Nuts",
    "Seeds",
    "Legumes",
    "Grains",
    "Dairy",
    "Meat",
    "Seafood",
    "Spices",
    "Herbs"
  ];

  String? selectedItemName;
  String? selectedItemType;

  List<File> selectedImages = [];
  List<String> existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      selectedItemName = widget.item!.name;
      selectedItemType = widget.item!.type;
      _itemPriceController.text = widget.item!.price.toString();
      _itemQuantityController.text = widget.item!.quantity.toString();

      selectedImages = widget.item!.images;
      existingImageUrls = widget.item!.imageUrls;
    }
  }

  @override
  void dispose() {
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  void _addImages() async {
    final pickedImages = await _picker.pickMultiImage();
    if (pickedImages != null) {
      setState(() {
        selectedImages.addAll(pickedImages.map((e) => File(e.path)).toList());
      });
    }
  }

  void _submit() {
    final itemPrice = double.tryParse(_itemPriceController.text) ?? 0.0;
    final itemQuantity = int.tryParse(_itemQuantityController.text) ?? 1;

    if (selectedItemName != null && selectedItemType != null) {
      final newItem = Item(
        name: selectedItemName!,
        type: selectedItemType!,
        price: itemPrice,
        quantity: itemQuantity,
        images: selectedImages,
        imageUrls: existingImageUrls,
        timestamp: Timestamp.fromDate(DateTime.now()),
      );
      Navigator.pop(context, newItem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both an item name and type.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              label: 'Item Name',
              value: selectedItemName,
              items: itemNames,
              onChanged: (value) => setState(() => selectedItemName = value),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Item Type',
              value: selectedItemType,
              items: itemTypes,
              onChanged: (value) => setState(() => selectedItemType = value),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _itemPriceController,
              label: 'Item Price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _itemQuantityController,
              label: 'Item Quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text('Add Images'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _addImages,
              ),
            ),
            const SizedBox(height: 24),
            _buildImagePreview(),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(widget.item == null ? 'Add Item' : 'Update Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to display existing and selected images
  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Images:',
          // style: Theme.of(context)
          //     .textTheme
          //     .subtitle1!
          //     .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        selectedImages.isEmpty && existingImageUrls.isEmpty
            ? const Text('No images selected.',
                style: TextStyle(color: Colors.grey))
            : SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...existingImageUrls
                        .map((url) => _buildNetworkImage(url))
                        .toList(),
                    ...selectedImages
                        .map((file) => _buildFileImage(file))
                        .toList(),
                  ],
                ),
              ),
      ],
    );
  }

  // Build a widget for displaying a network image (existing uploaded image)
  Widget _buildNetworkImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  existingImageUrls.remove(imageUrl);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(Icons.cancel, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a widget for displaying a File image (newly added image)
  Widget _buildFileImage(File imageFile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              imageFile,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedImages.remove(imageFile);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: const Icon(Icons.cancel, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((name) {
        return DropdownMenuItem(
          value: name,
          child: Text(name),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
