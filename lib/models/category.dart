import 'package:isar/isar.dart';

part 'category.g.dart';

enum CategoryType { spent, income }

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;
  
  late int iconCode;
  
  /// 0 = spent, 1 = income
  late int typeIndex;
}
