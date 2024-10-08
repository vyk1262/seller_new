import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore timestamp

class Item {
  final String id;
  final String name;
  final String type;
  final double price;
  final int quantity;
  final List<File> images;
  final List<String> imageUrls;
  final Timestamp timestamp;

  Item({
    this.id = '',
    required this.name,
    required this.type,
    required this.price,
    required this.quantity,
    this.images = const [],
    this.imageUrls = const [],
    required this.timestamp,
  });

  // Copy with method for modifying an existing item
  Item copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    int? quantity,
    List<File>? images,
    List<String>? imageUrls,
    Timestamp? timestamp,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      images: images ?? this.images,
      imageUrls: imageUrls ?? this.imageUrls,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Convert Item to a map for Firestore (e.g., when adding/updating an item)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'quantity': quantity,
      'imageUrls': imageUrls,
      'timestamp': timestamp,
    };
  }

  // Create an Item from Firestore data (e.g., when reading an item)
  factory Item.fromMap(Map<String, dynamic> map, String documentId) {
    return Item(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
