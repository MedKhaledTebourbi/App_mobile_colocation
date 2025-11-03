import 'package:flutter/material.dart';
import 'reset_password_screen.dart';

class CodeVerificationScreen extends StatefulWidget {
  final String email;
  final String code;

  CodeVerificationScreen({required this.email, required this.code});

  @override
  _CodeVerificationScreenState createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vérification du code")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(hintText: "Entrez le code reçu"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_codeController.text.trim() == widget.code) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResetPasswordScreen(email: widget.email),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Code incorrect"), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text("Vérifier le code"),
            ),
          ],
        ),
      ),
    );
  }
}
