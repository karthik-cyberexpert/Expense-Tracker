import 'package:isar/isar.dart';

part 'notification_record.g.dart';

@collection
class NotificationRecord {
  Id id = Isar.autoIncrement;

  late String title;
  late String body;
  
  @Index()
  late DateTime timestamp;

  bool isRead = false;
  
  late double? amount;
  late bool? isIncome;
}
