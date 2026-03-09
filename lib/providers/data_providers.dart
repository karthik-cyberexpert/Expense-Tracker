import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/notification_record.dart';
import '../services/user_service.dart';
import 'package:flutter/material.dart';

part 'data_providers.g.dart';

@Riverpod(keepAlive: true)
DatabaseService database(DatabaseRef ref) {
  return DatabaseService();
}

@riverpod
Stream<List<Transaction>> transactionList(TransactionListRef ref) {
  return ref.watch(databaseProvider).watchAllTransactions();
}

@riverpod
Stream<List<Account>> accountList(AccountListRef ref) {
  return ref.watch(databaseProvider).watchAccounts();
}

@riverpod
Stream<List<Category>> categoryList(CategoryListRef ref) {
  return ref.watch(databaseProvider).watchCategories();
}

@riverpod
Stream<List<NotificationRecord>> notificationList(NotificationListRef ref) {
  return ref.watch(databaseProvider).watchNotifications();
}

@riverpod
class TransactionFilter extends _$TransactionFilter {
  @override
  Map<String, dynamic> build() {
    return {
      'category': null,
      'startDate': null,
      'endDate': null,
      'type': null,
      'tabIndex': 0,
    };
  }

  void setCategory(String? category) {
    state = {...state, 'category': category};
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = {...state, 'startDate': start, 'endDate': end};
  }

  void setType(String? type) {
    state = {...state, 'type': type};
  }

  void setTabIndex(int index) {
    state = {...state, 'tabIndex': index};
  }
}

@riverpod
Future<List<Transaction>> filteredTransactions(FilteredTransactionsRef ref) {
  final filters = ref.watch(transactionFilterProvider);
  final db = ref.watch(databaseProvider);
  
  return db.getTransactionsFiltered(
    category: filters['category'],
    start: filters['startDate'],
    end: filters['endDate'],
    type: filters['type'],
  );
}

@riverpod
Map<String, double> balanceSummary(BalanceSummaryRef ref) {
  final transactions = ref.watch(transactionListProvider).value ?? [];
  
  double totalBalance = 0;
  double income = 0;
  double spent = 0;
  
  for (var t in transactions) {
    if (t.amount > 0) {
      income += t.amount;
    } else {
      spent += t.amount.abs();
    }
  }
  
  final accounts = ref.watch(accountListProvider).value ?? [];
  totalBalance = accounts.fold(0, (sum, acc) => sum + acc.balance);

  return {
    'total': totalBalance,
    'income': income,
    'spent': spent,
  };
}

@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<Map<String, String?>> build() async {
    final service = ref.watch(userServicePrivider);
    return {
      'name': await service.getName(),
      'email': await service.getEmail(),
      'image': await service.getProfileImage(),
    };
  }

  Future<void> updateProfileInfo(String name, String email, String? image) async {
    final service = ref.read(userServicePrivider);
    await service.updateProfile(name, email, image);
    ref.invalidateSelf();
  }
}
