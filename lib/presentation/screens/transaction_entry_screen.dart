import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_cubit.dart';
import 'package:budget_pro_ai_app/presentation/managers/transaction_cubit/transaction_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  TransactionEntryScreenState createState() => TransactionEntryScreenState();
}

class TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text) ?? 0;
              final date =
                  DateTime.tryParse(_dateController.text) ?? DateTime.now();
              if (amount > 0 && _categoryController.text.isNotEmpty) {
                context.read<TransactionCubit>().addTransaction(
                  amount,
                  _categoryController.text,
                  date,
                  _isExpense,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid amount and category'),
                  ),
                );
              }
            },
            icon: Icon(Icons.add),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  _dateController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(picked);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Is Expense?'),
              value: _isExpense,
              onChanged: (value) => setState(() => _isExpense = value),
            ),
            BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state.error != null) {
                  return Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
