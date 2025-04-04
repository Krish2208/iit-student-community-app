import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String type; // T-shirt, Hoodie, Mug, etc.
  final List<String> sizesAvailable;
  final DateTime lastDateToPurchase;
  final String description;
  final List<String> colorsAvailable;
  final List<String> images;
  final String clubId;
  final String clubName;
  final int customizationFields;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.sizesAvailable,
    required this.lastDateToPurchase,
    required this.description,
    required this.colorsAvailable,
    required this.images,
    required this.clubId,
    required this.clubName,
    required this.customizationFields,
    required this.price,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      sizesAvailable: List<String>.from(data['sizesAvailable'] ?? []),
      lastDateToPurchase: (data['lastDateToPurchase'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      colorsAvailable: List<String>.from(data['colorsAvailable'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      customizationFields: data['customizationFields'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  bool isAvailable() {
    return DateTime.now().isBefore(lastDateToPurchase);
  }

  // Helper function to convert color names to Color objects
  Color getColorFromName(String colorName) {
    final Map<String, Color> colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'pink': Colors.pink,
      // Add more colors as needed
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}