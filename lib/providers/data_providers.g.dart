// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'199952ceed7ee90a4328658218eeb2fec278b7dc';

/// See also [database].
@ProviderFor(database)
final databaseProvider = Provider<DatabaseService>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseRef = ProviderRef<DatabaseService>;
String _$transactionListHash() => r'df00ab76be31a3e7023e37a2ffaf09d539ced614';

/// See also [transactionList].
@ProviderFor(transactionList)
final transactionListProvider =
    AutoDisposeStreamProvider<List<Transaction>>.internal(
  transactionList,
  name: r'transactionListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TransactionListRef = AutoDisposeStreamProviderRef<List<Transaction>>;
String _$accountListHash() => r'c38bddc0b44cad199745b31810bf58e813aeec95';

/// See also [accountList].
@ProviderFor(accountList)
final accountListProvider = AutoDisposeStreamProvider<List<Account>>.internal(
  accountList,
  name: r'accountListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$accountListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AccountListRef = AutoDisposeStreamProviderRef<List<Account>>;
String _$categoryListHash() => r'5eb7627ddd7846b0f55aa66923ae87711c2b93b2';

/// See also [categoryList].
@ProviderFor(categoryList)
final categoryListProvider = AutoDisposeStreamProvider<List<Category>>.internal(
  categoryList,
  name: r'categoryListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$categoryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CategoryListRef = AutoDisposeStreamProviderRef<List<Category>>;
String _$notificationListHash() => r'7bbe4b8303f321967100c30ec5582ca48a515c74';

/// See also [notificationList].
@ProviderFor(notificationList)
final notificationListProvider =
    AutoDisposeStreamProvider<List<NotificationRecord>>.internal(
  notificationList,
  name: r'notificationListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NotificationListRef
    = AutoDisposeStreamProviderRef<List<NotificationRecord>>;
String _$filteredTransactionsHash() =>
    r'4824496bdcb97eb46da201b992893d01120b7fb8';

/// See also [filteredTransactions].
@ProviderFor(filteredTransactions)
final filteredTransactionsProvider =
    AutoDisposeFutureProvider<List<Transaction>>.internal(
  filteredTransactions,
  name: r'filteredTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredTransactionsRef
    = AutoDisposeFutureProviderRef<List<Transaction>>;
String _$balanceSummaryHash() => r'273e585ba0755abceb13418a200f727e41f1c061';

/// See also [balanceSummary].
@ProviderFor(balanceSummary)
final balanceSummaryProvider =
    AutoDisposeProvider<Map<String, double>>.internal(
  balanceSummary,
  name: r'balanceSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$balanceSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BalanceSummaryRef = AutoDisposeProviderRef<Map<String, double>>;
String _$transactionFilterHash() => r'89c72ce13c90f6e0a33e04aab8919b0802a71811';

/// See also [TransactionFilter].
@ProviderFor(TransactionFilter)
final transactionFilterProvider = AutoDisposeNotifierProvider<TransactionFilter,
    Map<String, dynamic>>.internal(
  TransactionFilter.new,
  name: r'transactionFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transactionFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TransactionFilter = AutoDisposeNotifier<Map<String, dynamic>>;
String _$userProfileHash() => r'1148985aad4efa9e9b090ad508d48fe6f4ffbbec';

/// See also [UserProfile].
@ProviderFor(UserProfile)
final userProfileProvider = AutoDisposeAsyncNotifierProvider<UserProfile,
    Map<String, String?>>.internal(
  UserProfile.new,
  name: r'userProfileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserProfile = AutoDisposeAsyncNotifier<Map<String, String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
