import 'package:budget_pro_ai_app/core/models/transaction_model.dart';
import 'package:budget_pro_ai_app/core/services/database_service.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final DatabaseService databaseService = DatabaseService();

  TransactionCubit() : super(TransactionState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await databaseService.initDatabase();
      await loadTransactions();
    } catch (e) {
      emit(
        TransactionState(transactions: state.transactions, error: e.toString()),
      );
    }
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await databaseService.getTransactions();
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
      await databaseService.addTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      emit(TransactionState(transactions: state.transactions, error: e.toString()));
    }
  }

  Future<void> clearTransactions() async {
    try {
      await databaseService.clearTransactions();
      await loadTransactions();
    } catch (e) {
      emit(TransactionState(transactions: state.transactions, error: e.toString()));
    }
  }
}
