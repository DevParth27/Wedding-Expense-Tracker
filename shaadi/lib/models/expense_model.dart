import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String createdBy;
  final String? imageUrl;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdBy,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'imageUrl': imageUrl,
    };
  }

  // Create from Firestore document
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
}