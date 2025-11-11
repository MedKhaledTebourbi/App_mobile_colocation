import 'package:flutter/material.dart';
import 'package:collo/providers/house_provider.dart';
import 'package:collo/providers/session_provider.dart';
import 'package:collo/models/house.dart';
import 'package:collo/models/notification_model.dart';
import 'package:collo/repositories/notification_repository.dart';
import 'package:collo/services/house_status_service.dart';
import 'house_detail_screen.dart';
import 'add_house_screen.dart';
import 'chat_screen.dart';
import 'change_house_tag_dialog.dart';

class MyHousesScreen extends StatefulWidget {
  const MyHousesScreen({super.key});

  @override
  State<MyHousesScreen> createState() => _MyHousesScreenState();
}

class _MyHousesScreenState extends State<MyHousesScreen> {
  final HouseProvider _houseProvider = HouseProvider();
  final SessionProvider _sessionProvider = SessionProvider();
  final NotificationRepository _notificationRepo = NotificationRepository();
  List<House> _owned = [];
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload houses when screen is displayed (in case user switched accounts)
    _load();
  }

  Future<void> _load() async {
    try {
      await _houseProvider.initialize();
      final email = _sessionProvider.currentUser?.email ?? '';
      final all = _houseProvider.houses;
      
      // Load notifications from database
      final notificationsFromDb = await _notificationRepo.getNotificationsForOwner(email);
      
      setState(() {
        _owned = all.where((h) => (h.ownerEmail) == email).toList();
        _notifications = notificationsFromDb;
        _loading = false;
      });
    } catch (e) {
      print('Error loading houses: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  List<NotificationModel> _getNotificationsForHouse(House house) {
    // Use notifications from database instead of session
    return _notifications
        .where((n) => n.houseId == house.id)
        .toList();
  }

  int _getTotalPendingRequests() {
    // Use notifications from database instead of session
    return _notifications
        .where((n) => n.status == 'pending')
        .length;
  }

  Future<void> _approveBooking(NotificationModel notification) async {
    try {
      // Update in database
      await _notificationRepo.updateNotificationStatus(notification.id ?? 0, 'approved');
      
      // Update in session
      _sessionProvider.approveNotification(notification.id ?? 0);

      // Update house tag to "Réservée" (Reserved)
      final houseStatusService = HouseStatusService();
      await houseStatusService.updateHouseTag(notification.houseId, 'Réservée');
      
      // Reload data
      await _load();
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réservation approuvée ! La maison est maintenant réservée.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(NotificationModel notification) async {
    try {
      // Update in database
      await _notificationRepo.updateNotificationStatus(notification.id ?? 0, 'rejected');
      
      // Update in session
      _sessionProvider.rejectNotification(notification.id ?? 0);
      
      // Reload data
      await _load();
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réservation rejetée'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editHouse(House house) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHouseScreen(houseToEdit: house),
      ),
    ).then((result) {
      if (result == true) {
        _load();
      }
    });
  }

  void _deleteHouse(House house) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la maison'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${house.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _houseProvider.deleteHouse(house.id);
              setState(() {
                _owned.removeWhere((h) => h.id == house.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Maison supprimée'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text('Êtes-vous sûr de vouloir annuler la réservation de ${notification.bookerName} ? La maison sera de nouveau disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              
              // Update notification status to cancelled
              await _notificationRepo.updateNotificationStatus(notification.id ?? 0, 'cancelled');
              
              // Reload data
              await _load();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réservation annulée. La maison est de nouveau disponible.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Annuler la réservation', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Détails de la demande',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Maison', notification.houseTitle),
              _buildDetailRow('Demandeur', notification.bookerName),
              _buildDetailRow('Email', notification.bookerEmail),
              _buildDetailRow(
                'Check-in',
                '${notification.checkInDate.day}/${notification.checkInDate.month}/${notification.checkInDate.year}',
              ),
              _buildDetailRow(
                'Check-out',
                '${notification.checkOutDate.day}/${notification.checkOutDate.month}/${notification.checkOutDate.year}',
              ),
              _buildDetailRow(
                'Montant',
                '\${notification.totalPrice.toStringAsFixed(2)}',
                isPrice: true,
              ),
              const SizedBox(height: 20),
              // Chat Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(reservation: notification),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ouvrir le chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (notification.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _rejectBooking(notification);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _approveBooking(notification);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else if (notification.status == 'approved' || notification.status == 'paid')
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notification.status == 'paid'
                            ? Colors.blue[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notification.status == 'paid'
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                      child: Text(
                        notification.status == 'paid'
                            ? 'Réservation payée'
                            : 'Réservation approuvée',
                        style: TextStyle(
                          color: notification.status == 'paid'
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show "Change House Tag" button only when payment is done
                    if (notification.status == 'paid')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final house = await _houseProvider.getHouseById(notification.houseId);
                            if (house != null && mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => ChangeHouseTagDialog(
                                  house: house,
                                  onTagChanged: () {
                                    _load();
                                  },
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.label_outline),
                          label: const Text('Changer le tag de la maison'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showCancelConfirmation(notification);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Annuler la réservation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red,
                    ),
                  ),
                  child: Text(
                    'Réservation rejetée',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPrice ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _getTotalPendingRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes maisons'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _owned.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_work_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune maison',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des maisons pour les gérer ici',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _owned.length,
                    itemBuilder: (context, index) {
                      final house = _owned[index];
                      final notifications = _getNotificationsForHouse(house);
                      final pendingNotifications = notifications
                          .where((n) => n.status == 'pending')
                          .toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Section - Bigger
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    house.imageUrl,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: double.infinity,
                                      height: 220,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.home, size: 80),
                                    ),
                                  ),
                                ),
                                // Property Type Badge
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      house.propertyType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Pending Requests Badge
                                if (pendingNotifications.isNotEmpty)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.notifications,
                                              color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pendingNotifications.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Details Section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Price
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              house.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    house.address,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${house.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            '/month',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Features Row
                                  Row(
                                    children: [
                                      _buildFeatureBadge(
                                          Icons.bed, '${house.bedrooms}'),
                                      const SizedBox(width: 12),
                                      _buildFeatureBadge(
                                          Icons.bathtub, '${house.bathrooms}'),
                                      const SizedBox(width: 12),
                                      _buildFeatureBadge(Icons.square_foot,
                                          '${house.area.toStringAsFixed(0)}m²'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _editHouse(house),
                                          icon: const Icon(Icons.edit,
                                              size: 18),
                                          label: const Text('Modifier'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[700],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _deleteHouse(house),
                                          icon: const Icon(Icons.delete,
                                              size: 18),
                                          label: const Text('Supprimer'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Bookings Section
                            if (notifications.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Demandes de location (${notifications.length})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Icon(
                                            Icons.expand_more,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...notifications.map((notification) {
                                      final isPending =
                                          notification.status == 'pending';
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                                color: Colors.grey[200]!),
                                          ),
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _showBookingDetails(notification),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.bookerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${notification.checkInDate.day}/${notification.checkInDate.month} - ${notification.checkOutDate.day}/${notification.checkOutDate.month}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '\$${notification.totalPrice.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isPending
                                                          ? Colors.orange
                                                          : notification
                                                                      .status ==
                                                                  'approved'
                                                              ? Colors.green
                                                              : Colors.red,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(12),
                                                    ),
                                                    child: Text(
                                                      isPending
                                                          ? 'En attente'
                                                          : notification
                                                                      .status ==
                                                                  'approved'
                                                              ? 'Approuvée'
                                                              : 'Rejetée',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
