import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail(String recipientEmail, String code) async {
  String username = 'ihebrezgui045@gmail.com'; // ton email
  String password = 'nslc gssm dvqq rfri'; // mot de passe d'application Gmail

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Nom App')
    ..recipients.add(recipientEmail)
    ..subject = 'Code de réinitialisation'
    ..text = 'Votre code pour réinitialiser le mot de passe est : $code';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email envoyé: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Erreur envoi email: $e');
  }
}
