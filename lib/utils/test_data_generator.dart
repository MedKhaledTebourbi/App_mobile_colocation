import 'package:collo/models/notification_model.dart';
import 'package:collo/providers/session_provider.dart';

class TestDataGenerator {
  static final SessionProvider _sessionProvider = SessionProvider();

  /// Génère des données de test pour les notifications
  static void generateTestNotifications(String ownerEmail) {
    final notifications = [
      NotificationModel(
        id: 1,
        houseOwnerEmail: ownerEmail,
        bookerId: 1,
        houseId: 1,
        houseTitle: 'Maison à Paris',
        bookerName: 'Jean Dupont',
        bookerEmail: 'jean@example.com',
        checkInDate: DateTime.now().add(const Duration(days: 5)),
        checkOutDate: DateTime.now().add(const Duration(days: 10)),
        totalPrice: 500.0,
        status: 'pending',
      ),
      NotificationModel(
        id: 2,
        houseOwnerEmail: ownerEmail,
        bookerId: 2,
        houseId: 1,
        houseTitle: 'Maison à Paris',
        bookerName: 'Marie Martin',
        bookerEmail: 'marie@example.com',
        checkInDate: DateTime.now().add(const Duration(days: 15)),
        checkOutDate: DateTime.now().add(const Duration(days: 20)),
        totalPrice: 600.0,
        status: 'pending',
      ),
      NotificationModel(
        id: 3,
        houseOwnerEmail: ownerEmail,
        bookerId: 3,
        houseId: 2,
        houseTitle: 'Appartement à Lyon',
        bookerName: 'Pierre Bernard',
        bookerEmail: 'pierre@example.com',
        checkInDate: DateTime.now().add(const Duration(days: 3)),
        checkOutDate: DateTime.now().add(const Duration(days: 8)),
        totalPrice: 400.0,
        status: 'approved',
      ),
    ];

    for (var notification in notifications) {
      _sessionProvider.addNotification(notification);
    }

    print('✅ ${notifications.length} notifications de test générées');
  }

  /// Affiche les notifications de test
  static void printTestNotifications(String ownerEmail) {
    final notifications = _sessionProvider.getNotificationsForOwnerEmail(ownerEmail);
    print('\n📋 Notifications pour $ownerEmail:');
    for (var notification in notifications) {
      print(
        '  - ${notification.bookerName} (${notification.status}): ${notification.houseTitle}',
      );
    }
  }

  /// Réinitialise les données de test
  static void clearTestData() {
    // Note: SessionProvider est un singleton, donc on ne peut pas vraiment le réinitialiser
    // Cette méthode est juste pour la documentation
    print('⚠️ Pour réinitialiser, redémarrez l\'application');
  }
}
