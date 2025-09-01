import 'package:budget_pro_ai_app/core/models/transaction_model.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/matrix.dart';

class PredictionService {
  Future<double> predictNextMonthExpenses(
    List<TransactionModel> transactions,
  ) async {
    Map<int, double> monthlyExpenses = {};
    for (var tx in transactions) {
      if (tx.isExpense) {
        int monthKey = tx.date.year * 100 + tx.date.month;
        monthlyExpenses[monthKey] =
            (monthlyExpenses[monthKey] ?? 0) + tx.amount;
      }
    }

    List<List<double>> data = [];
    int index = 0;
    for (var entry in monthlyExpenses.entries) {
      data.add([index.toDouble(), entry.value]);
      index++;
    }

    if (data.length < 2) return 0;

    final dataMatrix = Matrix.fromList(data);
    final df = DataFrame.fromMatrix(
      dataMatrix,
      header: ['month_index', 'expenses'],
    );

    // final regressor = LinearRegressor(df, 'expenses', fitIntercept: true);
    final regressor = KnnRegressor(df, 'expenses', 5);
    final nextMonth = DataFrame.fromMatrix(
      Matrix.fromList([
        [index.toDouble()],
      ]),
      header: ['month_index'],
    );
    final prediction = regressor.predict(nextMonth);

    return prediction.rows.first.first as double;
  }
}
