import 'package:collo/models/user.dart';
import 'package:collo/models/notification_model.dart';

class SessionProvider {
  static final SessionProvider _instance = SessionProvider._internal();
  
  factory SessionProvider() {
    return _instance;
  }
  
  SessionProvider._internal();
  
  User? _currentUser;
  List<NotificationModel> _notifications = [];
  Map<int, List<int>> _userHouses = {}; // userId -> list of houseIds
  int _unreadMessageCount = 0; // Count of unread messages

  User? get currentUser => _currentUser;
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get pendingNotifications => 
    _notifications.where((n) => n.status == 'pending').toList();
  int get unreadMessageCount => _unreadMessageCount;

  // Get notifications for current user (as owner)
  List<NotificationModel> get myNotifications {
    if (_currentUser == null) return [];
    return _notifications.where((n) => n.houseOwnerEmail == _currentUser!.email).toList();
  }

  // Get pending notifications for current user (as owner)
  List<NotificationModel> get myPendingNotifications {
    if (_currentUser == null) return [];
    return _notifications.where((n) => 
      n.houseOwnerEmail == _currentUser!.email && n.status == 'pending'
    ).toList();
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }

  void addHouseToUser(int userId, int houseId) {
    if (!_userHouses.containsKey(userId)) {
      _userHouses[userId] = [];
    }
    _userHouses[userId]!.add(houseId);
  }

  List<int> getUserHouses(int userId) {
    return _userHouses[userId] ?? [];
  }

  void addNotification(NotificationModel notification) {
    _notifications.add(notification);
  }

  void approveNotification(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].status = 'approved';
    }
  }

  void rejectNotification(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].status = 'rejected';
    }
  }

  List<NotificationModel> getNotificationsForUser(int userId) {
    return _notifications.where((n) => n.houseOwnerId == userId).toList();
  }

  List<NotificationModel> getNotificationsForOwnerEmail(String email) {
    return _notifications.where((n) => n.houseOwnerEmail == email).toList();
  }

  // Message notification methods
  void incrementUnreadMessages() {
    _unreadMessageCount++;
  }

  void decrementUnreadMessages() {
    if (_unreadMessageCount > 0) {
      _unreadMessageCount--;
    }
  }

  void resetUnreadMessages() {
    _unreadMessageCount = 0;
  }

  void setUnreadMessageCount(int count) {
    _unreadMessageCount = count;
  }
}
