import 'package:budget_pro_ai_app/core/models/transaction_model.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final String? error;

  TransactionState({this.transactions = const [], this.error});
}
