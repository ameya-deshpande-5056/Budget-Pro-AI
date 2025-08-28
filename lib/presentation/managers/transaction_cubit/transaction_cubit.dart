import 'package:budget_pro_ai_app/core/models/transaction_model.dart';
import 'package:budget_pro_ai_app/core/services/database_service.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final DatabaseService _databaseService = DatabaseService();

  TransactionCubit() : super(TransactionState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _databaseService.initDatabase();
      await _loadTransactions();
    } catch (e) {
      emit(
        TransactionState(transactions: state.transactions, error: e.toString()),
      );
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _databaseService.getTransactions();
      emit(TransactionState(transactions: transactions));
    } catch (e) {
      emit(
        TransactionState(transactions: state.transactions, error: e.toString()),
      );
    }
  }

  Future<void> addTransaction(double amount, String category, DateTime date, bool isExpense) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = TransactionModel(
        id: id,
        amount: amount,
        category: category,
        date: date,
        isExpense: isExpense,
      );
      await _databaseService.addTransaction(transaction);
      await _loadTransactions();
    } catch (e) {
      emit(TransactionState(transactions: state.transactions, error: e.toString()));
    }
  }

  Future<void> clearTransactions() async {
    try {
      await _databaseService.clearTransactions();
      await _loadTransactions();
    } catch (e) {
      emit(TransactionState(transactions: state.transactions, error: e.toString()));
    }
  }
}
