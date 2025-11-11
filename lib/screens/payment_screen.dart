import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/transaction.dart' as app_transaction;
import '../services/payment_service.dart';
import '../services/house_availability_service.dart';
import '../services/owner_notification_service.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/house_repository.dart';
import '../utils/logger.dart';

class PaymentScreen extends StatefulWidget {
  final NotificationModel notification;

  const PaymentScreen({super.key, required this.notification});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = false;
  bool _isCardValid = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _validateCard() {
    setState(() {
      // Accept any 16-digit card number (with or without spaces)
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      _isCardValid = cardNumber.length == 16 &&
          _expiryController.text.length == 5 &&
          _cvvController.text.length == 3 &&
          _cardHolderController.text.isNotEmpty;
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Veuillez remplir tous les champs correctement'),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryDate = _expiryController.text;
      final cvv = _cvvController.text;
      final cardHolderName = _cardHolderController.text;

      // Create a temporary transaction object for payment processing
      final transaction = app_transaction.Transaction(
        houseId: widget.notification.houseId,
        houseTitle: widget.notification.houseTitle,
        houseImage: '',
        customerName: widget.notification.bookerName,
        customerEmail: widget.notification.bookerEmail,
        customerPhone: '',
        checkInDate: widget.notification.checkInDate,
        checkOutDate: widget.notification.checkOutDate,
        numberOfGuests: 1,
        totalPrice: widget.notification.totalPrice,
        status: 'pending',
      );

      // Process payment using PaymentService
      final isSuccessful = await _paymentService.processPayment(
        transaction: transaction,
        cardHolderName: cardHolderName,
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (isSuccessful) {
          // Update notification status to 'paid'
          final notificationRepo = NotificationRepository();
          await notificationRepo.updateNotificationStatus(
            widget.notification.id ?? 0,
            'paid',
          );

          // Update transaction status to 'confirmed' (reserved)
          final transactionRepo = TransactionRepository();
          final transactions = await transactionRepo.getTransactionsByCustomerEmail(
            widget.notification.bookerEmail,
          );
          
          // Find the matching transaction and update it
          for (var trans in transactions) {
            if (trans.houseId == widget.notification.houseId &&
                trans.customerEmail == widget.notification.bookerEmail &&
                trans.status != 'confirmed') {
              trans.status = 'confirmed';
              await transactionRepo.updateTransaction(trans);
              break;
            }
          }

          // Update house availability to 'unavailable'
          final houseAvailabilityService = HouseAvailabilityService();
          await houseAvailabilityService.markHouseAsUnavailable(
            widget.notification.houseId,
          );

          // Update house status to 'Rented'
          final houseRepo = HouseRepository();
          final house = await houseRepo.getHouseById(widget.notification.houseId);
          if (house != null) {
            final rentedHouse = house.copyWith(tag: 'Rented');
            await houseRepo.updateHouse(rentedHouse);
          }

          // Notify owner about payment confirmation
          final ownerNotificationService = OwnerNotificationService();
          await ownerNotificationService.notifyOwnerPaymentConfirmed(
            widget.notification,
          );

          if (mounted) {
            // Show success notification overlay
            _showPaymentSuccessNotification();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Paiement effectué avec succès!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Le propriétaire a été notifié',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 4),
              ),
            );

            Logger.info('Payment successful - Notification ID: ${widget.notification.id}, Status: paid');

            // Return success to previous screen with a delay to ensure DB is updated
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                Logger.info('Returning from payment screen with success');
                Navigator.pop(context, true);
              }
            });
          }
        }
      }
    } catch (e) {
      Logger.error('Payment error', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Erreur de paiement',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$e',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    if (value.length > 16) value = value.substring(0, 16);
    
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length > 4) value = value.substring(0, 4);
    
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  void _showPaymentSuccessNotification() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              overlayEntry.remove();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Paiement confirmé ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Votre réservation est finalisée',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => overlayEntry.remove(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé de la commande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      children: [
                        Text(
                          widget.notification.houseTitle,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant:'),
                        Flexible(
                          child: Text(
                            '${widget.notification.totalPrice.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${widget.notification.totalPrice.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Form
              const Text(
                'Informations de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Card Holder Name
                    TextFormField(
                      controller: _cardHolderController,
                      decoration: InputDecoration(
                        labelText: 'Nom du titulaire',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => _validateCard(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom du titulaire';
                        }
                        if (value.length < 3) {
                          return 'Le nom doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card Number
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numéro de carte',
                        prefixIcon: const Icon(Icons.credit_card),
                        hintText: '0000 0000 0000 0000',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        suffixIcon: _cardNumberController.text.replaceAll(' ', '').length == 16
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _cardNumberController.value = TextEditingValue(
                          text: _formatCardNumber(value),
                          selection: TextSelection.fromPosition(
                            TextPosition(offset: _formatCardNumber(value).length),
                          ),
                        );
                        _validateCard();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le numéro de carte';
                        }
                        if (value.replaceAll(' ', '').length != 16) {
                          return 'Le numéro de carte doit contenir 16 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiry and CVV
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: InputDecoration(
                              labelText: 'Expiration',
                              hintText: 'MM/YY',
                              helperText: 'Ex: 12/25',
                              helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              suffixIcon: _expiryController.text.length == 5
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _expiryController.value = TextEditingValue(
                                text: _formatExpiry(value),
                                selection: TextSelection.fromPosition(
                                  TextPosition(offset: _formatExpiry(value).length),
                                ),
                              );
                              _validateCard();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              if (value.length != 5) {
                                return 'Format: MM/YY';
                              }
                              // Additional validation for month
                              final parts = value.split('/');
                              if (parts.length == 2) {
                                final month = int.tryParse(parts[0]);
                                if (month == null || month < 1 || month > 12) {
                                  return 'Mois invalide (01-12)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              hintText: '000',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              suffixIcon: const Tooltip(
                                message: 'Les 3 chiffres au dos de votre carte',
                                child: Icon(Icons.help_outline, size: 20),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscureText: true,
                            onChanged: (_) => _validateCard(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              if (value.length != 3) {
                                return '3 chiffres';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Security Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Votre paiement est sécurisé avec le chiffrement SSL',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.blue.withOpacity(0.4),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Traitement en cours...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline, size: 22),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Confirmer le paiement',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.notification.totalPrice.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
