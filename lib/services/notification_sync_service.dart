import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../utils/logger.dart';

/// Service for synchronizing notifications across the app
class NotificationSyncService {
  final NotificationRepository _notificationRepo = NotificationRepository();

  /// Get all notifications for a user (as owner or booker)
  Future<List<NotificationModel>> getAllNotificationsForUser(String userEmail) async {
    try {
      // Get notifications where user is the owner
      final ownerNotifications = await _notificationRepo.getNotificationsForOwner(userEmail);
      
      // Get notifications where user is the booker
      final bookerNotifications = await _notificationRepo.getNotificationsForBooker(userEmail);
      
      // Combine and remove duplicates
      final allNotifications = <NotificationModel>[];
      final ids = <int>{};
      
      for (final notification in [...ownerNotifications, ...bookerNotifications]) {
        if (notification.id != null && !ids.contains(notification.id)) {
          allNotifications.add(notification);
          ids.add(notification.id!);
        }
      }
      
      // Sort by creation date (newest first)
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      Logger.info('Total notifications for $userEmail: ${allNotifications.length}');
      return allNotifications;
    } catch (e) {
      Logger.error('Error getting all notifications for user', e);
      return [];
    }
  }

  /// Get pending notifications for a user (as owner)
  Future<List<NotificationModel>> getPendingNotificationsForOwner(String ownerEmail) async {
    try {
      final notifications = await _notificationRepo.getPendingNotificationsForOwner(ownerEmail);
      Logger.info('Pending notifications for owner $ownerEmail: ${notifications.length}');
      return notifications;
    } catch (e) {
      Logger.error('Error getting pending notifications', e);
      return [];
    }
  }

  /// Get approved notifications for a booker (waiting for payment)
  Future<List<NotificationModel>> getApprovedNotificationsForBooker(String bookerEmail) async {
    try {
      final allNotifications = await _notificationRepo.getNotificationsForBooker(bookerEmail);
      final approvedNotifications = allNotifications
          .where((n) => n.status == 'approved' || n.status == 'paid')
          .toList();
      Logger.info('Approved/Paid notifications for booker $bookerEmail: ${approvedNotifications.length}');
      return approvedNotifications;
    } catch (e) {
      Logger.error('Error getting approved notifications', e);
      return [];
    }
  }

  /// Get all notifications for a booker
  Future<List<NotificationModel>> getAllNotificationsForBooker(String bookerEmail) async {
    try {
      final notifications = await _notificationRepo.getNotificationsForBooker(bookerEmail);
      Logger.info('All notifications for booker $bookerEmail: ${notifications.length}');
      return notifications;
    } catch (e) {
      Logger.error('Error getting all notifications for booker', e);
      return [];
    }
  }

  /// Update notification status
  Future<bool> updateNotificationStatus(int notificationId, String status) async {
    try {
      final result = await _notificationRepo.updateNotificationStatus(notificationId, status);
      if (result > 0) {
        Logger.info('Notification $notificationId updated to status: $status');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error updating notification status', e);
      return false;
    }
  }
}
