import 'package:isar/isar.dart';
import 'account.dart';
import 'category.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  
  @Index()
  late DateTime date;

  final account = IsarLink<Account>();
  final category = IsarLink<Category>();

  // Helper for filtering
  late String categoryName;
  late String accountName;
}
