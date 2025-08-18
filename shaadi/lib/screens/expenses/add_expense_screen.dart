import 'package:flutter/material.dart';
import 'package:shaadi/models/expense_model.dart';
import 'package:shaadi/services/auth_service.dart';
import 'package:shaadi/services/database_service.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // Add this parameter for editing

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedCategory = 'Venue';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.expense != null; // Check if we're editing

  final Map<String, Map<String, String>> _categories = {
    'Venue': {'en': 'Venue', 'mr': 'स्थळ'},
    'Catering': {'en': 'Catering', 'mr': 'खाद्यसेवा'},
    'Decoration': {'en': 'Decoration', 'mr': 'सजावट'},
    'Attire': {'en': 'Attire', 'mr': 'पोशाख'},
    'Photography': {'en': 'Photography', 'mr': 'छायाचित्रण'},
    'Transportation': {'en': 'Transportation', 'mr': 'वाहतूक'},
    'Gifts': {'en': 'Gifts', 'mr': 'भेटवस्तू'},
    'Jewelry': {'en': 'Jewelry', 'mr': 'दागिने'},
    'Music': {'en': 'Music', 'mr': 'संगीत'},
    'Flowers': {'en': 'Flowers', 'mr': 'फुले'},
    'Makeup': {'en': 'Makeup', 'mr': 'श्रृंगार'},
    'Invitations': {'en': 'Invitations', 'mr': 'आमंत्रणे'},
    'Other': {'en': 'Other', 'mr': 'इतर'},
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Pre-fill form with existing expense data
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description;
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }
    _dateController.text = DateFormat.yMMMd().format(_selectedDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink[400]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(_selectedDate);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_isLoading) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'User not authenticated • वापरकर्ता प्रमाणीकृत नाही',
                ),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return;
        }

        final expense = Expense(
          id: _isEditing
              ? widget.expense!.id
              : null, // Use existing ID if editing
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          createdBy: _isEditing
              ? widget.expense!.createdBy
              : user.uid, // Keep original creator if editing
        );

        if (_isEditing) {
          await _databaseService.updateExpense(expense);
        } else {
          await _databaseService.addExpense(expense);
        }

        if (mounted) {
          // Reset loading state before navigation
          setState(() {
            _isLoading = false;
          });

          Navigator.pop(context, {
            'success': true,
            'message': _isEditing
                ? 'Expense updated successfully • खर्च यशस्वीरित्या अपडेट केला गेला'
                : 'Expense added successfully • खर्च यशस्वीरित्या जोडला गेला',
          });
        }
      } catch (e) {
        print('Error in _saveExpense: $e'); // Add debugging
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Error updating expense • खर्च अपडेट करताना त्रुटी: $e'
                    : 'Error adding expense • खर्च जोडताना त्रुटी: $e',
              ),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelEn,
    required String labelMr,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: '$labelEn • $labelMr',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.pink[400], size: 20),
          ),
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.pink[400]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.pink[400],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.pink[100],
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.pink[400],
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.pink[400]!, Colors.pink[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink[200]!.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Prachi\'s Wedding Expense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Playfair',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      ' प्रची लग्नाचा खर्च',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[200]!.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernTextField(
                        controller: _titleController,
                        labelEn: 'Title',
                        labelMr: 'शीर्षक',
                        icon: Icons.title_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title • कृपया शीर्षक प्रविष्ट करा';
                          }
                          return null;
                        },
                      ),

                      _buildModernTextField(
                        controller: _amountController,
                        labelEn: 'Amount',
                        labelMr: 'रक्कम',
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount • कृपया रक्कम प्रविष्ट करा';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number • कृपया वैध संख्या प्रविष्ट करा';
                          }
                          return null;
                        },
                      ),

                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Category • श्रेणी',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.category_rounded,
                                color: Colors.pink[400],
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.pink[400]!,
                                width: 2,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.pink[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          items: _categories.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.value['en']} • ${entry.value['mr']}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),

                      _buildModernTextField(
                        controller: _dateController,
                        labelEn: 'Date',
                        labelMr: 'दिनांक',
                        icon: Icons.calendar_today_rounded,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.pink[400],
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                      ),

                      _buildModernTextField(
                        controller: _descriptionController,
                        labelEn: 'Description',
                        labelMr: 'वर्णन',
                        icon: Icons.description_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[400]!, Colors.pink[600]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink[200]!.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isEditing
                                          ? 'Updating... • अपडेट करत आहे...'
                                          : 'Saving... • जतन करत आहे...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.update_rounded
                                          : Icons.save_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        _isEditing
                                            ? 'Update Expense • खर्च अपडेट करा'
                                            : 'Save Expense • खर्च जतन करा',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
