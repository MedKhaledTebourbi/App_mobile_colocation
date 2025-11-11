import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:collo/utils/logger.dart';

// Configuration des identifiants email (à remplacer par des variables d'environnement en production)
const String EMAIL_USERNAME = 'ihebrezgui045@gmail.com';
const String EMAIL_PASSWORD = 'nslc gssm dvqq rfri';

Future<void> sendEmail(String recipientEmail, String code) async {
  try {
    // Validation de l'email destinataire
    if (recipientEmail.isEmpty || !recipientEmail.contains('@')) {
      throw Exception('Email destinataire invalide: $recipientEmail');
    }

    final smtpServer = gmail(EMAIL_USERNAME, EMAIL_PASSWORD);

    final message = Message()
      ..from = Address(EMAIL_USERNAME, 'Collo App')
      ..recipients.add(recipientEmail)
      ..subject = 'Code de réinitialisation de mot de passe'
      ..text = 'Votre code de vérification pour réinitialiser votre mot de passe est : $code\n\nCe code est valide pour une seule utilisation.\n\nSi vous n\'avez pas demandé cette réinitialisation, ignorez cet email.';

    Logger.info('Tentative d\'envoi d\'email à: $recipientEmail');
    
    final sendReport = await send(message, smtpServer);
    
    Logger.info('Email envoyé avec succès à $recipientEmail: ${sendReport.toString()}');
  } on MailerException catch (e) {
    Logger.error('Erreur Mailer lors de l\'envoi de l\'email: $e');
    for (var p in e.problems) {
      Logger.error('Problème: ${p.code}: ${p.msg}');
    }
    rethrow; // Relancer l'exception pour que l'appelant puisse la gérer
  } catch (e) {
    Logger.error('Erreur inattendue lors de l\'envoi de l\'email: $e');
    rethrow;
  }
}
