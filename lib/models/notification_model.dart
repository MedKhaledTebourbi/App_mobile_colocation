class NotificationModel {
  int? id;
  int houseOwnerId; // legacy numeric owner id (optional)
  String houseOwnerEmail; // email du propriétaire
  int bookerId; // ID de la personne qui réserve
  int houseId;
  String houseTitle;
  String bookerName;
  String bookerEmail;
  DateTime checkInDate;
  DateTime checkOutDate;
  double totalPrice;
  String status; // pending, approved, rejected, paid
  DateTime createdAt;

  NotificationModel({
    this.id,
    this.houseOwnerId = 0,
    required this.houseOwnerEmail,
    required this.bookerId,
    required this.houseId,
    required this.houseTitle,
    required this.bookerName,
    required this.bookerEmail,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
