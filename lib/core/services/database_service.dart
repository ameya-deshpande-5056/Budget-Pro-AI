import 'package:budget_pro_ai_app/core/models/transaction_model.dart';
import 'package:path/path.dart';
import 'package:budget_pro_ai_app/core/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  Database? _database;

  Future<void> initDatabase() async {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
        _database = await databaseFactory.openDatabase(
          Constants.databaseFileName,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE ${Constants.transactionsTbl} (
                  id TEXT PRIMARY KEY,
                  amount REAL,
                  category TEXT,
                  date INTEGER,
                  isExpense INTEGER
                )
              ''');
            },
          ),
        );
      } else {
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, Constants.databaseFileName);
        _database = await openDatabase(
          path,
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
                CREATE TABLE ${Constants.transactionsTbl} (
                  id TEXT PRIMARY KEY,
                  amount REAL,
                  category TEXT,
                  date INTEGER,
                  isExpense INTEGER
                )
              ''');
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        Constants.transactionsTbl,
      );
      return maps
          .map(
            (map) => TransactionModel(
              id: map['id'],
              amount: map['amount'],
              category: map['category'],
              date: DateTime.fromMillisecondsSinceEpoch(map['date']),
              isExpense: map['isExpense'] == 1,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _database!.insert(Constants.transactionsTbl, {
        'id': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category.toLowerCase(),
        'date': transaction.date.millisecondsSinceEpoch,
        'isExpense': transaction.isExpense ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<void> clearTransactions() async {
    try {
      if (kIsWeb) {
        await _database!.execute('DELETE FROM transactions');
      } else {
        await _database!.delete('transactions');
      }
    } catch (e) {
      throw Exception('Failed to clear transactions: $e');
    }
  }

  Future<String> exportToCsv() async {
    try {
      final transactions = await getTransactions();
      final csvRows = <String>[];
      csvRows.add('id,amount,category,date,isExpense'); // CSV Header
      for (var tx in transactions) {
        final row = [
          tx.id,
          tx.amount.toString(),
          '"${tx.category.replaceAll('"', '""')}"', // Escape quotes in category
          tx.date.millisecondsSinceEpoch.toString(),
          tx.isExpense ? "1" : "0",
        ].join(",");
        csvRows.add(row);
      }
      return csvRows.join("\n");
    } catch (e) {
      throw Exception('Failed to export transactions to CSV: $e');
    }
  }

  Future<void> importFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split("\n");
      if (lines.isEmpty ||
          lines[0].trim() !=
              'id,amount,category,date,isExpense') {
        throw Exception('Invalid CSV format');
      }
      final batch = _database!.batch();
      for (var line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        final parts = _parseCsvLine(line);
        if (parts.length != 5) {
          throw Exception("Invalid CSV row: $line");
        }
        final transaction = {
          'id': parts[0],
          'amount': double.tryParse(parts[1]) ?? 0,
          'category': parts[2].toLowerCase(),
          'date': int.tryParse(parts[3]) ?? 0,
          'isExpense': parts[4] == '1' ? 1 : 0,
        };
        if (transaction['amount'] == 0 || transaction['date'] == 0) {
          throw Exception('Invalid data in CSV row: $line');
        }
        batch.insert(
          'transactions',
          transaction,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Failed to import transactions from CSV: $e');
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        inQuotes = !inQuotes;
      } else if (line[i] == "," && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(line[i]);
      }
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }
    return result;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
