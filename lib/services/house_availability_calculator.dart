import 'package:collo/models/house.dart';
import 'package:collo/repositories/notification_repository.dart';
import 'package:collo/utils/logger.dart';

/// Service to calculate house availability status dynamically
class HouseAvailabilityCalculator {
  static final HouseAvailabilityCalculator _instance = 
      HouseAvailabilityCalculator._internal();
  
  factory HouseAvailabilityCalculator() => _instance;
  HouseAvailabilityCalculator._internal();

  final NotificationRepository _notificationRepo = NotificationRepository();

  /// Calculate the dynamic status of a house
  /// Returns 'Available' or 'Réservée' based on active reservations
  Future<String> calculateHouseStatus(House house) async {
    try {
      // Get all notifications for this house
      final notifications = await _notificationRepo.getNotificationsForHouse(house.id);
      
      // Check if there's an approved (paid) reservation
      final hasApprovedReservation = notifications.any((n) => 
        n.status == 'approved' || n.status == 'paid'
      );

      if (hasApprovedReservation) {
        return 'Réservée';
      }

      // Check if there's a pending reservation
      final hasPendingReservation = notifications.any((n) => 
        n.status == 'pending'
      );

      if (hasPendingReservation) {
        return 'Pending';
      }

      // Default to available
      return 'Available';
    } catch (e) {
      Logger.error('Error calculating house status', e);
      return 'Available'; // Default to available on error
    }
  }

  /// Get all houses with their calculated status
  Future<List<House>> getHousesWithCalculatedStatus(List<House> houses) async {
    try {
      final updatedHouses = <House>[];
      
      for (final house in houses) {
        final calculatedStatus = await calculateHouseStatus(house);
        final updatedHouse = house.copyWith(tag: calculatedStatus);
        updatedHouses.add(updatedHouse);
      }
      
      return updatedHouses;
    } catch (e) {
      Logger.error('Error getting houses with calculated status', e);
      return houses; // Return original houses on error
    }
  }

  /// Check if a house is available for booking
  Future<bool> isHouseAvailable(House house) async {
    final status = await calculateHouseStatus(house);
    return status == 'Available';
  }

  /// Get status description for UI
  static String getStatusDescription(String status) {
    switch (status) {
      case 'Available':
        return 'Disponible pour la réservation';
      case 'Réservée':
        return 'Déjà réservée';
      case 'Pending':
        return 'Réservation en attente';
      default:
        return status;
    }
  }
}
