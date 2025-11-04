class Transaction {
  int? id;
  String houseId;
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
    return {
      'id': id,
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
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      houseId: map['house_id'] as String,
      houseTitle: map['house_title'] as String,
      houseImage: map['house_image'] as String,
      customerName: map['customer_name'] as String,
      customerEmail: map['customer_email'] as String,
      customerPhone: map['customer_phone'] as String,
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: DateTime.parse(map['check_out_date'] as String),
      numberOfGuests: map['number_of_guests'] as int,
      totalPrice: map['total_price'] as double,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  int get numberOfDays {
    return checkOutDate.difference(checkInDate).inDays;
  }
}
