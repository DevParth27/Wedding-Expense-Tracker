import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shaadi/models/expense_model.dart';
import 'package:shaadi/models/user_model.dart';
import 'package:shaadi/models/budget_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference usersCollection;
  final CollectionReference expensesCollection;
  final CollectionReference budgetsCollection;

  DatabaseService()
      : usersCollection = FirebaseFirestore.instance.collection('users'),
        expensesCollection = FirebaseFirestore.instance.collection('expenses'),
        budgetsCollection = FirebaseFirestore.instance.collection('budgets');

  // User methods
  Future<void> createUser(UserModel user) async {
    return await usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Expense methods
  Future<void> addExpense(Expense expense) async {
    return await expensesCollection.doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    return await expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    return await expensesCollection.doc(expenseId).delete();
  }

  Stream<List<Expense>> getExpenses() {
    return expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }

  Stream<List<Expense>> getExpensesByCategory(String category) {
    return expensesCollection
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }

  // Budget methods
  Future<void> addBudget(Budget budget) async {
    return await budgetsCollection.doc(budget.id).set(budget.toMap());
  }

  Future<void> updateBudget(Budget budget) async {
    return await budgetsCollection.doc(budget.id).update(budget.toMap());
  }

  Stream<Budget?> getCurrentBudget() {
    return budgetsCollection
        .orderBy('endDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Budget.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Summary methods
  Future<Map<String, double>> getExpenseSummaryByCategory() async {
    QuerySnapshot snapshot = await expensesCollection.get();
    Map<String, double> categorySummary = {};

    for (var doc in snapshot.docs) {
      Expense expense = Expense.fromFirestore(doc);
      if (categorySummary.containsKey(expense.category)) {
        categorySummary[expense.category] = 
            categorySummary[expense.category]! + expense.amount;
      } else {
        categorySummary[expense.category] = expense.amount;
      }
    }

    return categorySummary;
  }

  Future<double> getTotalExpenses() async {
    QuerySnapshot snapshot = await expensesCollection.get();
    double total = 0;

    for (var doc in snapshot.docs) {
      Expense expense = Expense.fromFirestore(doc);
      total += expense.amount;
    }

    return total;
  }
  
  // Get expenses by user
  Future<double> getTotalExpensesByUser(String userId) async {
    QuerySnapshot snapshot = await expensesCollection
        .where('createdBy', isEqualTo: userId)
        .get();
    double total = 0;

    for (var doc in snapshot.docs) {
      Expense expense = Expense.fromFirestore(doc);
      total += expense.amount;
    }

    return total;
  }

  // Get expense count by user
  Future<int> getExpenseCountByUser(String userId) async {
    QuerySnapshot snapshot = await expensesCollection
        .where('createdBy', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }
  
  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return usersCollection
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    // First, delete all expenses created by this user
    QuerySnapshot userExpenses = await expensesCollection
        .where('createdBy', isEqualTo: userId)
        .get();
    
    // Delete all user's expenses
    for (var doc in userExpenses.docs) {
      await doc.reference.delete();
    }
    
    // Then delete the user
    return await usersCollection.doc(userId).delete();
  }
}