import 'package:isar/isar.dart';

part 'account.g.dart';

enum AccountType { bank, upi, card, cash }

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name;
  late double balance;
  late String owner;
  late int colorValue;

  @Index(unique: true)
  late String displayName;

  @enumerated
  late AccountType type;

  // Bank Specific
  String? ifscCode;
  String? accountNumber;
  
  // UPI Specific
  String? upiId;

  // Card Specific
  String? cardNumber;
  String? expiryDate;
  String? cardType; // Visa, Mastercard, RuPay
  bool? isCredit; // true for Credit, false for Debit

  // Shared
  String? accountHolderName;
}
