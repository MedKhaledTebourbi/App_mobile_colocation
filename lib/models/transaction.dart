class Transaction {
  int? id;
  int houseId;
  String houseTitle;
  String houseImage;
  String customerName;
  String customerEmail;
  String customerPhone;
  DateTime checkInDate;
  DateTime checkOutDate;
  int numberOfGuests;
  double totalPrice;
  String status; // pending, confirmed, cancelled
  DateTime createdAt;

  Transaction({
    this.id,
    required this.houseId,
    required this.houseTitle,
    required this.houseImage,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalPrice,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'house_id': houseId,
      'house_title': houseTitle,
      'house_image': houseImage,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'number_of_guests': numberOfGuests,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: _toInt(map['id']),
      houseId: _toInt(map['house_id'])!,
      houseTitle: map['house_title'] as String,
      houseImage: map['house_image'] as String,
      customerName: map['customer_name'] as String,
      customerEmail: map['customer_email'] as String,
      customerPhone: map['customer_phone'] as String,
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: DateTime.parse(map['check_out_date'] as String),
      numberOfGuests: _toInt(map['number_of_guests'])!,
      totalPrice: _toDouble(map['total_price'])!,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
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

  int get numberOfDays {
    return checkOutDate.difference(checkInDate).inDays;
  }
}
