class ChatMessage {
  final int? id;
  final int reservationId;
  final String senderEmail;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    this.id,
    required this.reservationId,
    required this.senderEmail,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'sender_email': senderEmail,
      'sender_name': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      reservationId: map['reservation_id'] as int,
      senderEmail: map['sender_email'] as String,
      senderName: map['sender_name'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['is_read'] as int) == 1,
    );
  }
}
