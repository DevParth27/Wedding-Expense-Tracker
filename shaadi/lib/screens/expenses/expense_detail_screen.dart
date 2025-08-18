import 'package:flutter/material.dart';
import 'package:shaadi/models/expense_model.dart';
import 'package:shaadi/models/user_model.dart';
import 'package:shaadi/services/database_service.dart';
import 'package:shaadi/screens/expenses/add_expense_screen.dart';
import 'package:intl/intl.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  ExpenseDetailScreen({Key? key, required this.expense}) : super(key: key);

  @override
  _ExpenseDetailScreenState createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _creator;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreator();
  }

  Future<void> _loadCreator() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _creator = await _databaseService.getUser(widget.expense.createdBy);
    } catch (e) {
      print('Error loading creator: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.pink[100],
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and amount section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.expense.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.pink[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currencyFormat.format(widget.expense.amount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        backgroundColor: Colors.pink[50],
                        label: Text(
                          widget.expense.category,
                          style: TextStyle(color: Colors.pink[800]),
                        ),
                        avatar: Icon(
                          _getCategoryIcon(widget.expense.category),
                          color: Colors.pink[800],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Details section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        DateFormat.yMMMMd().format(widget.expense.date),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        Icons.person,
                        'Added by',
                        _isLoading
                            ? 'Loading...'
                            : (_creator?.displayName ?? 'Unknown User'),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        Icons.description,
                        'Description',
                        widget.expense.description.isEmpty
                            ? 'No description provided'
                            : widget.expense.description,
                      ),
                      if (widget.expense.imageUrl != null) ...[
                        const Divider(),
                        _buildDetailRow(
                          Icons.image,
                          'Receipt',
                          'View Image',
                          isLink: true,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image viewing coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Delete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Expense'),
                  onPressed: () => _confirmDelete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "edit_fab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddExpenseScreen(expense: widget.expense),
                ),
              );
            },
            backgroundColor: Colors.blue[400],
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "delete_fab",
            onPressed: () => _confirmDelete(context),
            backgroundColor: Colors.red[400],
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final textWidget = Text(
      value,
      style: TextStyle(
        fontSize: 16,
        color: isLink ? Colors.blue : Colors.black87,
        decoration: isLink ? TextDecoration.underline : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.pink[300], size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              isLink
                  ? GestureDetector(onTap: onTap, child: textWidget)
                  : textWidget,
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final DatabaseService databaseService = DatabaseService();
                databaseService
                    .deleteExpense(widget.expense.id)
                    .then((_) {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense deleted')),
                      );
                    })
                    .catchError((error) {
                      Navigator.of(context).pop(); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting expense: $error'),
                        ),
                      );
                    });
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Icons.location_city;
      case 'catering':
        return Icons.restaurant;
      case 'decoration':
        return Icons.celebration;
      case 'attire':
        return Icons.checkroom;
      case 'photography':
        return Icons.camera_alt;
      case 'transportation':
        return Icons.directions_car;
      case 'gifts':
        return Icons.card_giftcard;
      default:
        return Icons.receipt;
    }
  }
}
