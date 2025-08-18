import 'package:flutter/material.dart';
import 'package:shaadi/models/expense_model.dart';
import 'package:shaadi/models/user_model.dart';
import 'package:shaadi/screens/expenses/expense_detail_screen.dart';
import 'package:shaadi/services/database_service.dart';
import 'package:shaadi/screens/expenses/add_expense_screen.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(),
      body: Column(children: [_buildSearchSection(), _buildExpenseList()]),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      title: const Text(
        'Expenses',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses, categories...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Expanded(
      child: StreamBuilder<List<Expense>>(
        stream: _databaseService.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          List<Expense> expenses = snapshot.data!;

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            expenses = expenses.where((expense) {
              return expense.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  expense.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  expense.category.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
            }).toList();
          }

          if (expenses.isEmpty) {
            return _buildNoResultsState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: expenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseCard(expense);
            },
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Dismissible(
      key: Key(expense.id),
      background: _buildDeleteBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmation(),
      onDismissed: (direction) => _deleteExpense(expense),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToDetail(expense),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildCategoryIcon(expense.category),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a1a),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildSubtitle(expense),
                        const SizedBox(height: 8),
                        _buildCreatorInfo(expense),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildAmountSection(expense),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    final categoryColor = _getCategoryColor(category);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(_getCategoryIcon(category), color: categoryColor, size: 24),
    );
  }

  Widget _buildSubtitle(Expense expense) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            expense.category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getCategoryColor(expense.category),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          DateFormat.MMMd().format(expense.date),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCreatorInfo(Expense expense) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUser(expense.createdBy),
      builder: (context, userSnapshot) {
        String creatorName = 'Loading...';
        if (userSnapshot.hasData && userSnapshot.data != null) {
          creatorName = userSnapshot.data!.displayName ?? 'Unknown User';
        } else if (userSnapshot.hasError) {
          creatorName = 'Unknown User';
        }

        return Row(
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 14,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              creatorName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountSection(Expense expense) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          currencyFormat.format(expense.amount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 4),
        Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      ],
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          const Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
          SizedBox(height: 16),
          Text(
            'Loading expenses...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding expenses to track your wedding budget',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No matching expenses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a1a1a),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Colors.purple;
      case 'catering':
        return Colors.orange;
      case 'decoration':
        return Colors.pink;
      case 'attire':
        return Colors.teal;
      case 'photography':
        return Colors.indigo;
      case 'transportation':
        return Colors.blue;
      case 'gifts':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Icons.location_city_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'decoration':
        return Icons.celebration_rounded;
      case 'attire':
        return Icons.checkroom_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Future<bool?> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Expense',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to delete this expense? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    await _databaseService.deleteExpense(expense.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToDetail(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }
}
