/// Payment model representing a payment transaction
class Payment {
  int? id;
  int transactionId;
  String cardHolderName;
  String cardNumber; // Last 4 digits only for security
  String expiryDate;
  double amount;
  String status; // pending, completed, failed, refunded
  String paymentMethod; // credit_card, debit_card, etc.
  DateTime createdAt;
  DateTime? completedAt;
  String? failureReason;

  Payment({
    this.id,
    required this.transactionId,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.amount,
    this.status = 'pending',
    this.paymentMethod = 'credit_card',
    DateTime? createdAt,
    this.completedAt,
    this.failureReason,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'transaction_id': transactionId,
      'card_holder_name': cardHolderName,
      'card_number': cardNumber,
      'expiry_date': expiryDate,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    final transactionId = _toInt(map['transaction_id']);
    if (transactionId == null) {
      throw Exception('Transaction ID cannot be null in Payment');
    }
    
    return Payment(
      id: _toInt(map['id']),
      transactionId: transactionId,
      cardHolderName: map['card_holder_name'] as String? ?? 'Unknown',
      cardNumber: map['card_number'] as String? ?? '0000',
      expiryDate: map['expiry_date'] as String? ?? '00/00',
      amount: _toDouble(map['amount']) ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String? ?? 'credit_card',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      failureReason: map['failure_reason'] as String?,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
