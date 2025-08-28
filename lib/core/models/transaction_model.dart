class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense; // true for expense, false for income

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      amount: data['amount'].toDouble(),
      category: data['category'],
      date: DateTime.fromMillisecondsSinceEpoch(data['date']),
      isExpense: data['isExpense'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'ixExpense': isExpense,
    };
  }
}
