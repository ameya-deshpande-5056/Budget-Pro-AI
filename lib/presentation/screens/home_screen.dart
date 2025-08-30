import 'dart:convert';
import 'dart:io';

import 'package:budget_pro_ai_app/core/utils/constants.dart';
import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/prediction_cubit/prediction_state.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_state.dart';
import 'package:budget_pro_ai_app/presentation/screens/transaction_entry_screen.dart';
import 'package:budget_pro_ai_app/presentation/widgets/dynamic_column_row.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _exportTransactions(BuildContext context) async {
    try {
      final dbService = context.read<TransactionCubit>().databaseService;
      final csvContent = await dbService.exportToCsv();
      final bytes = utf8.encode(csvContent);
      final fileName =
          "budget_export_${DateTime.now().millisecondsSinceEpoch}.csv";

      if (kIsWeb) {
        final blob = html.Blob([bytes], "text/csv");
        final url = html.Url.createObjectUrlFromBlob(blob);
        final _ =
            html.document.createElement('a') as html.AnchorElement
              ..href = url
              ..setAttribute('download', fileName)
              ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importTransactions(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String csvContent;
      if (kIsWeb) {
        csvContent = utf8.decode(file.bytes!);
      } else {
        final filePath = file.path!;
        csvContent = await File(filePath).readAsString();
      }

      if (context.mounted) {
        final dbService = context.read<TransactionCubit>().databaseService;
        await dbService.importFromCsv(csvContent);
      }
      if (context.mounted) {
        await context.read<TransactionCubit>().loadTransactions();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imported transactions successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.homescreenTitle),
        actions: [
          IconButton(
            onPressed: () => _exportTransactions(context),
            icon: const Icon(Icons.file_download, color: Colors.blueAccent),
            tooltip: Constants.exportTxnsTxt,
          ),
          IconButton(
            onPressed: () => _importTransactions(context),
            icon: const Icon(Icons.file_upload, color: Colors.blueAccent),
            tooltip: Constants.importTxnsTxt,
          ),
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
                      constraints.maxWidth > 600
                          ? MediaQuery.sizeOf(context).width
                          : constraints.maxWidth,
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
                                'Predicted Next Month: ₹${state.predictedExpenses.toStringAsFixed(2)}',
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
                          double totalExpenses = 0.0;
                          for (var tx in state.transactions.where(
                            (t) => t.isExpense,
                          )) {
                            categoryTotals[tx.category] =
                                (categoryTotals[tx.category] ?? 0) + tx.amount;
                            totalExpenses += (categoryTotals[tx.category] ?? 0);
                          }

                          return dynamicRowColumn(
                            maxWidth: MediaQuery.sizeOf(context).width,
                            children: [
                              SizedBox(
                                height:
                                    constraints.maxWidth > 600
                                        ? constraints.maxHeight * 0.9
                                        : constraints.maxHeight * 0.4,
                                width:
                                    constraints.maxWidth > 600
                                        ? MediaQuery.sizeOf(context).width * 0.5
                                        : 200,
                                child: PieChart(
                                  PieChartData(
                                    sections:
                                        categoryTotals.entries
                                            .map(
                                              (entry) => PieChartSectionData(
                                                value: entry.value,
                                                title:
                                                    "${entry.key}\n₹${entry.value.toStringAsFixed(0)}",
                                                color:
                                                    Colors
                                                        .primaries[(totalExpenses -
                                                                entry.value /
                                                                entry.key.length
                                                                    .toDouble())
                                                            .toInt() %
                                                        Colors
                                                            .primaries
                                                            .length],
                                                radius:
                                                    constraints.maxWidth > 600
                                                        ? MediaQuery.sizeOf(
                                                              context,
                                                            ).width *
                                                            0.1
                                                        : 80,
                                                titleStyle: TextStyle(
                                                  fontSize: constraints.maxWidth > 600 ? 10 : 6,
                                                  backgroundColor: Colors.white,
                                                ),
                                                titlePositionPercentageOffset:
                                                    (entry.value /
                                                                totalExpenses) >
                                                            0.02
                                                        ? 0.8
                                                        : 0.4,
                                              ),
                                            )
                                            .toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius:
                                        constraints.maxWidth > 600
                                            ? MediaQuery.sizeOf(context).width *
                                                0.05
                                            : 40,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    constraints.maxWidth > 600
                                        ? constraints.maxHeight * 0.9
                                        : constraints.maxHeight * 0.5,
                                width:
                                    constraints.maxWidth > 600
                                        ? MediaQuery.sizeOf(context).width * 0.4
                                        : constraints.maxWidth,
                                child: ListView.builder(
                                  itemCount: state.transactions.length,
                                  itemBuilder: (context, index) {
                                    final tx = state.transactions[index];
                                    return ListTile(
                                      title: Text(
                                        '${tx.category}: ₹${tx.amount.toStringAsFixed(2)}',
                                      ),
                                      subtitle: Text(
                                        DateFormat(
                                          'EEEE, d MMMM yyyy',
                                        ).format(tx.date),
                                      ),
                                      trailing: Text(
                                        tx.isExpense ? 'Expense' : 'Income',
                                        style: TextStyle(
                                          color:
                                              tx.isExpense
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
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
