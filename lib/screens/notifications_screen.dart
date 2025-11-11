import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collo/models/user.dart';
import 'package:collo/models/notification_model.dart';
import 'package:collo/providers/session_provider.dart';
import 'package:collo/repositories/chat_repository.dart';
import 'package:collo/repositories/notification_repository.dart';
import 'package:collo/repositories/transaction_repository.dart';
import 'package:collo/services/notification_sync_service.dart';
import 'package:collo/utils/logger.dart';
import 'chat_screen.dart';
import 'payment_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final User user;

  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final SessionProvider _sessionProvider = SessionProvider();
  final ChatRepository _chatRepository = ChatRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  late TabController _tabController;
  List<NotificationModel> _bookingNotifications = [];
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotificationsFromDatabase();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _loadNotificationsFromDatabase();
        }
      }
      return mounted;
    });
  }

  Future<void> _loadNotificationsFromDatabase() async {
    try {
      final currentUserEmail = _sessionProvider.currentUser?.email ?? '';
      if (currentUserEmail.isEmpty) {
        setState(() {
          _isLoadingNotifications = false;
        });
        return;
      }

      // Load only owner notifications (for approving/rejecting bookings)
      // and booker notifications with 'approved' or 'paid' status (for payment)
      final ownerNotifications = await _notificationRepo.getNotificationsForOwner(currentUserEmail);
      final bookerNotifications = await _notificationRepo.getNotificationsForBooker(currentUserEmail);
      
      // Filter booker notifications to only show approved and paid statuses
      final filteredBookerNotifications = bookerNotifications
          .where((n) => n.status == 'approved' || n.status == 'paid')
          .toList();
      
      final allNotifications = [...ownerNotifications, ...filteredBookerNotifications];
      
      if (mounted) {
        setState(() {
          _bookingNotifications = allNotifications;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading notifications', e);
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveBooking(int notificationId, NotificationModel notification) async {
    try {
      // Update notification status to 'approved'
      await _notificationRepo.updateNotificationStatus(notificationId, 'approved');
      _sessionProvider.approveNotification(notificationId);
      
      // Also update the corresponding transaction status to 'approved'
      final transactions = await _transactionRepo.getTransactionsByCustomerEmail(
        notification.bookerEmail,
      );
      
      for (var transaction in transactions) {
        if (transaction.houseId == notification.houseId &&
            transaction.status == 'pending') {
          transaction.status = 'approved';
          await _transactionRepo.updateTransaction(transaction);
          Logger.info('Transaction updated to approved for house ${notification.houseId}');
          break;
        }
      }
      
      _showApprovalNotificationToBooker(notification);
      await _loadNotificationsFromDatabase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réservation approuvée ! Notification envoyée au locataire'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _showNotificationSentDialog(notification);
      }
    } catch (e) {
      Logger.error('Error approving booking', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNotificationSentDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Notification Envoyée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La réservation a été approuvée avec succès!', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notification envoyée au locataire:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('📧 ${notification.bookerEmail}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('🏠 ${notification.houseTitle}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('💰 Le locataire doit maintenant procéder au paiement', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showApprovalNotificationToBooker(NotificationModel notification) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Réservation approuvée ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${notification.houseTitle} - Procédez au paiement', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => overlayEntry.remove(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  Future<void> _rejectBooking(int notificationId, NotificationModel notification) async {
    try {
      // Update notification status to 'rejected'
      await _notificationRepo.updateNotificationStatus(notificationId, 'rejected');
      _sessionProvider.rejectNotification(notificationId);
      
      // Also update the corresponding transaction status to 'rejected'
      final transactions = await _transactionRepo.getTransactionsByCustomerEmail(
        notification.bookerEmail,
      );
      
      for (var transaction in transactions) {
        if (transaction.houseId == notification.houseId &&
            transaction.status == 'pending') {
          transaction.status = 'rejected';
          await _transactionRepo.updateTransaction(transaction);
          Logger.info('Transaction updated to rejected for house ${notification.houseId}');
          break;
        }
      }
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Réservation rejetée'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showDeleteConversationDialog(int? reservationId) {
    if (reservationId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatRepository.deleteConversation(reservationId);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation supprimée'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir supprimer TOUTES les notifications de réservation ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                for (final notification in _bookingNotifications) {
                  await _notificationRepo.deleteNotification(notification.id ?? 0);
                }
                if (mounted) {
                  await _loadNotificationsFromDatabase();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toutes les notifications ont été supprimées'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Supprimer tout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotificationsFromDatabase, tooltip: 'Rafraîchir'),
          if (_bookingNotifications.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _showDeleteAllNotificationsDialog, tooltip: 'Supprimer toutes les notifications'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.calendar_today), const SizedBox(width: 8), const Text('Réservations')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.message), const SizedBox(width: 8), const Text('Messages')])),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingNotificationsTab(),
          _buildMessageNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildBookingNotificationsTab() {
    final currentUserEmail = _sessionProvider.currentUser?.email ?? '';
    final approvedReservationsNeedingPayment = _bookingNotifications
        .where((n) => n.bookerEmail == currentUserEmail && n.status == 'approved')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadNotificationsFromDatabase,
      child: _bookingNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucune notification', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Les demandes de réservation apparaîtront ici', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            )
          : Column(
              children: [
                if (approvedReservationsNeedingPayment.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.warning_amber, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Action requise!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 4),
                              Text('Vous avez ${approvedReservationsNeedingPayment.length} réservation(s) approuvée(s) en attente de paiement', style: TextStyle(fontSize: 13, color: Colors.orange[700], fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookingNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _bookingNotifications[index];
                      final isPending = notification.status == 'pending';
                      final isApproved = notification.status == 'approved';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isPending ? Colors.orange : isApproved ? Colors.green : Colors.red, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(notification.houseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('Demande de ${notification.bookerName}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPending ? Colors.orange : isApproved ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(isPending ? 'En attente' : isApproved ? 'Approuvée' : 'Rejetée', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (isPending)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _rejectBooking(notification.id ?? 0, notification),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Rejeter'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _approveBooking(notification.id ?? 0, notification),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Approuver'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (isApproved)
                                  Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green, width: 2)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Réservation approuvée ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  SizedBox(height: 4),
                                                  Text('En attente de paiement', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Show payment button only for the booker (renter)
                                      if (notification.bookerEmail == currentUserEmail)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen(notification: notification))).then((result) {
                                                if (result == true) {
                                                  _loadNotificationsFromDatabase();
                                                  Future.delayed(const Duration(milliseconds: 500), () {
                                                    if (mounted) _loadNotificationsFromDatabase();
                                                  });
                                                }
                                              });
                                            },
                                            icon: const Icon(Icons.payment, size: 20),
                                            label: const Text('Procéder au paiement'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageNotificationsTab() {
    return FutureBuilder<List>(
      future: _chatRepository.getAllMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Aucun message', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Les messages apparaîtront ici', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        final messages = snapshot.data!;
        final groupedMessages = <String, List>{};
        for (var msg in messages) {
          final key = '${msg['reservation_id']}_${msg['sender_email']}';
          if (!groupedMessages.containsKey(key)) {
            groupedMessages[key] = [];
          }
          groupedMessages[key]!.add(msg);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            final key = groupedMessages.keys.elementAt(index);
            final msgs = groupedMessages[key]!;
            final lastMsg = msgs.last;
            final senderName = lastMsg['sender_name'] ?? 'Unknown';
            final messageText = lastMsg['message'] ?? '';
            final timestamp = DateTime.parse(lastMsg['timestamp']);
            final isRead = lastMsg['is_read'] == 1;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: isRead ? 0 : 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isRead ? Colors.white : Colors.blue[50],
                  border: Border.all(color: isRead ? Colors.grey[200]! : Colors.blue, width: isRead ? 1 : 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundColor: Colors.blue[700], child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(senderName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(_formatTime(timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  'Dernier message:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              messageText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final senderEmail = lastMsg['sender_email'] as String?;
                                final reservationId = lastMsg['reservation_id'] as int?;
                                if (senderEmail != null && reservationId != null) {
                                  final tempNotification = NotificationModel(
                                    id: reservationId,
                                    houseOwnerEmail: _sessionProvider.currentUser?.email ?? '',
                                    bookerId: 0,
                                    houseId: 0,
                                    houseTitle: lastMsg['house_title'] ?? 'Réservation',
                                    bookerName: lastMsg['sender_name'] ?? 'Unknown',
                                    bookerEmail: senderEmail,
                                    checkInDate: DateTime.now(),
                                    checkOutDate: DateTime.now(),
                                    totalPrice: 0,
                                  );
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(reservation: tempNotification))).then((result) {
                                    if (result == true) setState(() {});
                                  });
                                }
                              },
                              icon: const Icon(Icons.reply),
                              label: const Text('Répondre'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(onPressed: () => _showDeleteConversationDialog(lastMsg['reservation_id'] as int?), icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Supprimer'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Aujourd\'hui ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hier ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
