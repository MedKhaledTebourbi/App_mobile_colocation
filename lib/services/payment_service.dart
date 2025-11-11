import '../models/payment.dart';
import '../models/transaction.dart' as app_transaction;
import '../repositories/payment_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/notification_repository.dart';
import '../utils/logger.dart';
import 'house_availability_service.dart';
import 'owner_notification_service.dart';

/// Service for handling payment processing and validation
class PaymentService {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  /// Validates card number - accepts any 16-digit card
  bool validateCardNumber(String cardNumber) {
    String digits = cardNumber.replaceAll(' ', '');
    
    // Accept any 16-digit card number
    if (digits.length != 16) {
      return false;
    }
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return false;
    }

    return true;
  }

  /// Validates expiry date format (MM/YY)
  /// For demo/testing: Accept any month 01-12 and year 23 onwards (2023+)
  bool validateExpiryDate(String expiryDate) {
    Logger.info('Validating expiry date: $expiryDate');
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiryDate)) {
      Logger.error('Invalid format - does not match MM/YY pattern', null);
      return false;
    }

    final parts = expiryDate.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    // Check if parsing was successful
    if (month == null || year == null) {
      Logger.error('Failed to parse month or year', null);
      return false;
    }

    Logger.info('Parsed - Month: $month, Year: $year');

    // Validate month (01-12)
    if (month < 1 || month > 12) {
      Logger.error('Invalid month: $month (must be 01-12)', null);
      return false;
    }

    // For demo/testing: Accept any year from 2023 onwards (23+)
    // This allows for flexible testing and covers current year (2025 = 25)
    if (year < 23) {
      Logger.error('Year too old: $year (must be >= 23)', null);
      return false;
    }

    // Optional: Check if the card is not expired (current month/year)
    final now = DateTime.now();
    final currentYear = now.year % 100; // Get last 2 digits (2025 -> 25)
    final currentMonth = now.month;

    Logger.info('Current - Month: $currentMonth, Year: $currentYear');

    // If year is less than current year, card is expired
    if (year < currentYear) {
      Logger.error('Card expired - year $year is before current year $currentYear', null);
      return false;
    }

    // If same year but month has passed, card is expired
    if (year == currentYear && month < currentMonth) {
      Logger.error('Card expired - month $month has passed in current year', null);
      return false;
    }

    Logger.info('Expiry date validation successful');
    return true;
  }

  /// Validates CVV (3 or 4 digits)
  bool validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv);
  }

  /// Validates card holder name
  bool validateCardHolderName(String name) {
    return name.trim().isNotEmpty && name.length >= 3;
  }

  /// Process payment for a transaction
  Future<bool> processPayment({
    required app_transaction.Transaction transaction,
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      Logger.info('Starting payment processing for transaction ${transaction.id}');

      // Validate all inputs
      if (!validateCardHolderName(cardHolderName)) {
        throw Exception('Nom du titulaire invalide');
      }

      if (!validateCardNumber(cardNumber)) {
        throw Exception('Numéro de carte invalide');
      }

      if (!validateExpiryDate(expiryDate)) {
        // Get current date for better error message
        final now = DateTime.now();
        final currentYear = now.year % 100;
        final currentMonth = now.month.toString().padLeft(2, '0');
        throw Exception('Date d\'expiration invalide. Utilisez le format MM/YY (ex: $currentMonth/${currentYear + 1}). La carte ne doit pas être expirée.');
      }

      if (!validateCVV(cvv)) {
        throw Exception('CVV invalide');
      }

      // Create payment record
      // Use a temporary ID if transaction.id is null (for new transactions)
      final paymentTransactionId = transaction.id ?? DateTime.now().millisecondsSinceEpoch;
      
      try {
        final payment = Payment(
          transactionId: paymentTransactionId,
          cardHolderName: cardHolderName,
          cardNumber: cardNumber.substring(cardNumber.length - 4), // Store only last 4 digits
          expiryDate: expiryDate,
          amount: transaction.totalPrice,
          status: 'pending',
          paymentMethod: 'credit_card',
        );

        // Simulate payment processing (in real app, call payment gateway API)
        await Future.delayed(const Duration(seconds: 2));

        // Simulate random success/failure for demo (in production, use actual gateway response)
        final isSuccessful = _simulatePaymentGateway();

        if (isSuccessful) {
          payment.status = 'completed';
          payment.completedAt = DateTime.now();

          // Save payment record - wrap in try-catch to handle DB errors
          try {
            await _paymentRepo.insertPayment(payment);
          } catch (dbError) {
            Logger.error('Error saving payment to database', dbError);
            // Continue anyway - payment was successful, just DB save failed
          }

          // Update transaction status to confirmed
          transaction.status = 'confirmed';
          try {
            await _transactionRepo.updateTransaction(transaction);
          } catch (dbError) {
            Logger.error('Error updating transaction', dbError);
            // Continue anyway
          }

          Logger.info('Payment processed successfully for transaction ${transaction.id}');
          return true;
        } else {
          payment.status = 'failed';
          payment.failureReason = 'Paiement refusé par la banque';

          // Save failed payment record
          try {
            await _paymentRepo.insertPayment(payment);
          } catch (dbError) {
            Logger.error('Error saving failed payment to database', dbError);
          }

          Logger.error('Payment failed for transaction ${transaction.id}', null);
          throw Exception('Paiement refusé par la banque. Veuillez vérifier vos informations.');
        }
      } catch (e) {
        Logger.error('Error in payment processing', e);
        rethrow;
      }
    } catch (e) {
      Logger.error('Error processing payment', e);
      rethrow;
    }
  }

  /// Get payment by transaction ID
  Future<Payment?> getPaymentByTransactionId(int transactionId) async {
    try {
      return await _paymentRepo.getPaymentByTransactionId(transactionId);
    } catch (e) {
      Logger.error('Error fetching payment', e);
      return null;
    }
  }

  /// Get all payments
  Future<List<Payment>> getAllPayments() async {
    try {
      return await _paymentRepo.getAllPayments();
    } catch (e) {
      Logger.error('Error fetching all payments', e);
      return [];
    }
  }

  /// Get payments by status
  Future<List<Payment>> getPaymentsByStatus(String status) async {
    try {
      return await _paymentRepo.getPaymentsByStatus(status);
    } catch (e) {
      Logger.error('Error fetching payments by status', e);
      return [];
    }
  }

  /// Refund a payment
  Future<bool> refundPayment(int paymentId) async {
    try {
      final payment = await _paymentRepo.getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Paiement non trouvé');
      }

      if (payment.status != 'completed') {
        throw Exception('Seuls les paiements complétés peuvent être remboursés');
      }

      // Simulate refund processing
      await Future.delayed(const Duration(seconds: 1));

      payment.status = 'refunded';
      await _paymentRepo.updatePayment(payment);

      Logger.info('Payment refunded successfully: $paymentId');
      return true;
    } catch (e) {
      Logger.error('Error refunding payment', e);
      rethrow;
    }
  }

  /// Get total revenue from completed payments
  Future<double> getTotalRevenue() async {
    try {
      return await _paymentRepo.getTotalRevenue();
    } catch (e) {
      Logger.error('Error calculating total revenue', e);
      return 0.0;
    }
  }

  /// Simulate payment gateway response (for demo purposes)
  /// In production, this would call actual payment gateway API
  bool _simulatePaymentGateway() {
    // For demo: 90% success rate
    return DateTime.now().millisecond % 10 != 0;
  }

  /// Format card number for display (show only last 4 digits)
  String formatCardNumberForDisplay(String lastFourDigits) {
    return '**** **** **** $lastFourDigits';
  }

  /// Get payment status in French
  String getPaymentStatusInFrench(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Complété';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status;
    }
  }
}
