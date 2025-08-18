import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Budget {
  final String id;
  final String title;
  final double totalAmount;
  final Map<String, double> categoryAllocations;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;

  Budget({
    String? id,
    required this.title,
    required this.totalAmount,
    required this.categoryAllocations,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
  }) : id = id ?? const Uuid().v4();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'categoryAllocations': categoryAllocations,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
    };
  }

  // Create from Firestore document
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      title: data['title'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      categoryAllocations: Map<String, double>.from(data['categoryAllocations'] ?? {}),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }
}