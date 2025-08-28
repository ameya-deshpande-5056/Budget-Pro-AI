import 'package:budget_pro_ai_app/core/utils/constants.dart';
import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_state.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_state.dart';
import 'package:budget_pro_ai_app/presentation/screens/transaction_entry_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.homescreenTitle),
        actions: [
          IconButton(
            onPressed:
                () => context.read<TransactionCubit>().clearTransactions(),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: Constants.clearAllTxnsTxt,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                ),
                child: BlocListener<TransactionCubit, TransactionState>(
                  listener: (context, state) {
                    if (state.transactions.isNotEmpty) {
                      context.read<PredictionCubit>().updatePrediction(
                        state.transactions,
                      );
                    }
                  },
                  child: Column(
                    children: [
                      BlocBuilder<PredictionCubit, PredictionState>(
                        builder:
                            (context, state) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Predicted Next Month: \$${state.predictedExpenses.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ),
                      BlocBuilder<TransactionCubit, TransactionState>(
                        builder: (context, state) {
                          if (state.transactions.isEmpty) {
                            return Center(child: Text(Constants.noTxnsYetMsg));
                          }
                          Map<String, double> categoryTotals = {};
                          for (var tx in state.transactions.where(
                            (t) => t.isExpense,
                          )) {
                            categoryTotals[tx.category] =
                                (categoryTotals[tx.category] ?? 0) + tx.amount;
                          }

                          return Column(
                            children: [
                              SizedBox(
                                height: constraints.maxWidth > 600 ? 300 : 200,
                                child: PieChart(
                                  PieChartData(
                                    sections:
                                        categoryTotals.entries
                                            .map(
                                              (entry) => PieChartSectionData(
                                                value: entry.value,
                                                title:
                                                    "${entry.key}\n\$${entry.value.toStringAsFixed(0)}",
                                                color:
                                                    Colors.primaries[entry
                                                            .key
                                                            .length %
                                                        Colors
                                                            .primaries
                                                            .length],
                                                radius:
                                                    constraints.maxWidth > 600
                                                        ? 120
                                                        : 80,
                                              ),
                                            )
                                            .toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius:
                                        constraints.maxWidth > 600 ? 60 : 40,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: constraints.maxHeight - 300,
                                child: ListView.builder(
                                  itemCount: state.transactions.length,
                                  itemBuilder: (context, index) {
                                    final tx = state.transactions[index];
                                    return ListTile(
                                      title: Text(
                                        '${tx.category}: \$${tx.amount.toStringAsFixed(2)}',
                                      ),
                                      subtitle: Text(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(tx.date),
                                      ),
                                      trailing: Text(
                                        tx.isExpense ? 'Expense' : 'Income',
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
