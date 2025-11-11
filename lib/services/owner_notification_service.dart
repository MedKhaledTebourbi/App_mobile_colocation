import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../utils/logger.dart';

/// Service for notifying house owners about payment confirmations
class OwnerNotificationService {
  final NotificationRepository _notificationRepo = NotificationRepository();

  /// Create a notification for the owner when payment is confirmed
  Future<bool> notifyOwnerPaymentConfirmed(
    NotificationModel originalNotification,
  ) async {
    try {
      // Create a new notification for the owner with status 'paid'
      final ownerNotification = NotificationModel(
        id: originalNotification.id,
        houseOwnerId: originalNotification.houseOwnerId,
        houseOwnerEmail: originalNotification.houseOwnerEmail,
        bookerId: originalNotification.bookerId,
        houseId: originalNotification.houseId,
        houseTitle: originalNotification.houseTitle,
        bookerName: originalNotification.bookerName,
        bookerEmail: originalNotification.bookerEmail,
        checkInDate: originalNotification.checkInDate,
        checkOutDate: originalNotification.checkOutDate,
        totalPrice: originalNotification.totalPrice,
        status: 'paid',
        createdAt: originalNotification.createdAt,
      );

      // Update the notification status to 'paid'
      final result = await _notificationRepo.updateNotificationStatus(
        originalNotification.id ?? 0,
        'paid',
      );

      if (result > 0) {
        Logger.info(
          'Owner notification created for payment confirmation: ${originalNotification.houseOwnerEmail}',
        );
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error notifying owner about payment', e);
      return false;
    }
  }

  /// Get payment confirmation notification for owner
  Future<NotificationModel?> getPaymentConfirmationNotification(
    String ownerEmail,
    int houseId,
  ) async {
    try {
      final notifications = await _notificationRepo.getNotificationsForOwner(ownerEmail);
      
      // Find the most recent 'paid' notification for this house
      final paidNotifications = notifications
          .where((n) => n.status == 'paid' && n.houseId == houseId)
          .toList();
      
      if (paidNotifications.isNotEmpty) {
        paidNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return paidNotifications.first;
      }
      return null;
    } catch (e) {
      Logger.error('Error fetching payment confirmation notification', e);
      return null;
    }
  }
}
