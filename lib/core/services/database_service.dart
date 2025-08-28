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
        'category': transaction.category,
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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
