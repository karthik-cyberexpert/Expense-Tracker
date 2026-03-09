import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/notification_record.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'notification_service.dart';

class DatabaseService {
  late Isar isar;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      isar = await Isar.open(
        [AccountSchema, CategorySchema, TransactionSchema, NotificationRecordSchema],
        directory: dir.path,
      );
    } catch (e) {
      debugPrint("Isar primary open failed: $e");
      // If primary fails, try to clear and open fresh or use a fallback name
      // This handles schema mismatches after updates
      isar = await Isar.open(
        [AccountSchema, CategorySchema, TransactionSchema, NotificationRecordSchema],
        directory: dir.path,
        name: 'expense_tracker_v3', // Changed version to trigger fresh start if v2 had different schema
      );
      debugPrint("Opened fallback database.");
    }

    // Always ensure we have exactly 24 categories on every startup
    // This is safer than just checking if any exist, as it fixes half-seeded states.
    final count = await isar.categorys.count();
    if (count != 24) {
      debugPrint("Database sync: Category count mismatch ($count/24). Fixing...");
      await _seedData();
    }
  }

  Future<void> forceReseed() async {
    await _seedData();
  }

  Future<void> _seedData() async {
    debugPrint("DATABASE: Starting _seedData process...");
    try {
      await isar.writeTxn(() async {
        debugPrint("DATABASE: Inside txn... clearing data...");
        // CLEAR EVERYTHING FIRST to ensure it's really fresh
        await isar.categorys.clear();
        await isar.accounts.clear();
        await isar.transactions.clear();
        
        debugPrint("DATABASE: Seeding categories...");
        final categories = [
          // 12 SPENT Categories (typeIndex = 0)
          Category()..name = 'Food'..iconCode = Icons.restaurant.codePoint..typeIndex = 0,
          Category()..name = 'Grocery'..iconCode = Icons.local_grocery_store.codePoint..typeIndex = 0,
          Category()..name = 'Transport'..iconCode = Icons.directions_car.codePoint..typeIndex = 0,
          Category()..name = 'Shopping'..iconCode = Icons.shopping_bag.codePoint..typeIndex = 0,
          Category()..name = 'Bills'..iconCode = Icons.electrical_services.codePoint..typeIndex = 0,
          Category()..name = 'Entertainment'..iconCode = Icons.movie.codePoint..typeIndex = 0,
          Category()..name = 'Medical'..iconCode = Icons.medical_services.codePoint..typeIndex = 0,
          Category()..name = 'Invest'..iconCode = Icons.trending_up.codePoint..typeIndex = 0,
          Category()..name = 'Fuel'..iconCode = Icons.local_gas_station.codePoint..typeIndex = 0,
          Category()..name = 'Rent'..iconCode = Icons.home.codePoint..typeIndex = 0,
          Category()..name = 'Travel'..iconCode = Icons.flight.codePoint..typeIndex = 0,
          Category()..name = 'Others'..iconCode = Icons.more_horiz.codePoint..typeIndex = 0,

          // 12 INCOME Categories (typeIndex = 1)
          Category()..name = 'Salary'..iconCode = Icons.account_balance_wallet.codePoint..typeIndex = 1,
          Category()..name = 'Business'..iconCode = Icons.business.codePoint..typeIndex = 1,
          Category()..name = 'Freelance'..iconCode = Icons.work_outline.codePoint..typeIndex = 1,
          Category()..name = 'Dividend'..iconCode = Icons.insights.codePoint..typeIndex = 1,
          Category()..name = 'Interest'..iconCode = Icons.savings.codePoint..typeIndex = 1,
          Category()..name = 'Rent'..iconCode = Icons.real_estate_agent.codePoint..typeIndex = 1,
          Category()..name = 'Gift'..iconCode = Icons.redeem.codePoint..typeIndex = 1,
          Category()..name = 'Refund'..iconCode = Icons.settings_backup_restore.codePoint..typeIndex = 1,
          Category()..name = 'Grant'..iconCode = Icons.school.codePoint..typeIndex = 1,
          Category()..name = 'Sale'..iconCode = Icons.sell.codePoint..typeIndex = 1,
          Category()..name = 'Bonus'..iconCode = Icons.card_giftcard.codePoint..typeIndex = 1,
          Category()..name = 'Others'..iconCode = Icons.more_horiz.codePoint..typeIndex = 1,
        ];
        await isar.categorys.putAll(categories);

        debugPrint("DATABASE: Seeding default accounts...");
        final accounts = [
          Account()..name = 'SBI'..owner = 'User'..balance = 0.0..displayName = 'SBI Bank'..colorValue = const Color(0xFF233266).value..type = AccountType.bank,
          Account()..name = 'PhonePe'..owner = 'User'..balance = 0.0..displayName = 'PhonePe UPI'..colorValue = const Color(0xFF5F259F).value..type = AccountType.upi,
          Account()..name = 'Cash'..owner = 'User'..balance = 0.0..displayName = 'Cash'..colorValue = Colors.teal.value..type = AccountType.cash,
        ];
        await isar.accounts.putAll(accounts);
      });
      debugPrint("DATABASE: _seedData completed SUCCESS.");
    } catch (e) {
      debugPrint("DATABASE: _seedData FAILED: $e");
    }
  }

  // Accounts
  Future<void> addAccount(Account account) async {
    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });
  }

  Future<void> removeAccount(int id) async {
    await isar.writeTxn(() async {
      await isar.accounts.delete(id);
    });
  }

  Future<List<Account>> getAllAccounts() => isar.accounts.where().findAll();
  Stream<List<Account>> watchAccounts() => isar.accounts.where().watch(fireImmediately: true);

  // Transactions
  Future<void> addTransaction(Transaction transaction) async {
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();

      // Update account balance
      final account = transaction.account.value;
      if (account != null) {
        account.balance += transaction.amount;
        await isar.accounts.put(account);
      }
    });

    // Trigger notification
    await NotificationService.showTransactionNotification(
      title: transaction.title,
      amount: transaction.amount.abs(),
      isIncome: transaction.amount >= 0,
    );
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return isar.transactions.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Future<List<Transaction>> getTransactionsFiltered({
    String? category,
    DateTime? start,
    DateTime? end,
    String? type,
  }) async {
    var query = isar.transactions.where();
    
    final all = await query.sortByDateDesc().findAll();
    return all.where((t) {
      bool catMatch = category == null || t.categoryName == category;
      bool dateMatch = true;
      if (start != null) dateMatch &= (t.date.isAfter(start) || t.date.isAtSameMomentAs(start));
      if (end != null) {
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        dateMatch &= (t.date.isBefore(endOfDay) || t.date.isAtSameMomentAs(endOfDay));
      }
      
      bool typeMatch = true;
      if (type != null) {
        if (type == 'Spent') typeMatch = t.amount < 0;
        if (type == 'Income') typeMatch = t.amount > 0;
      }

      return catMatch && dateMatch && typeMatch;
    }).toList();
  }

  // Categories
  Future<List<Category>> getAllCategories() => isar.categorys.where().findAll();
  Stream<List<Category>> watchCategories() => isar.categorys.where().watch(fireImmediately: true);

  // Notifications History
  Future<void> addNotificationRecord(NotificationRecord record) async {
    await isar.writeTxn(() async {
      await isar.notificationRecords.put(record);
    });
  }

  Stream<List<NotificationRecord>> watchNotifications() {
    return isar.notificationRecords.where().sortByTimestampDesc().watch(fireImmediately: true);
  }

  Future<void> clearNotifications() async {
    await isar.writeTxn(() async {
      await isar.notificationRecords.clear();
    });
  }

  // Maintenance
  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.transactions.clear();
      await isar.accounts.clear();
      await isar.categorys.clear();
    });
    // Reseed categories and accounts to have a clean start
    await _seedData();
  }

  Future<String> exportDataToJson() async {
    final accounts = await isar.accounts.where().findAll();
    final transactions = await isar.transactions.where().findAll();

    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => {
        'name': a.name,
        'balance': a.balance,
        'type': a.type.name,
        'displayName': a.displayName,
      }).toList(),
      'transactions': transactions.map((t) => {
        'title': t.title,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'category': t.categoryName,
        'account': t.accountName,
      }).toList(),
    };

    final jsonStr = jsonEncode(data);
    
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getDownloadsDirectory();
    }

    final file = File('${directory!.path}/expense_tracker_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    return file.path;
  }

  Future<int> getDataSize() async {
    final accounts = await isar.accounts.where().findAll();
    final transactions = await isar.transactions.where().findAll();
    final categories = await isar.categorys.where().findAll();
    
    // Rough estimate in bytes (each field roughly)
    int size = accounts.length * 200; 
    size += transactions.length * 150;
    size += categories.length * 100;
    return size;
  }
}
