import 'package:flutter/material.dart';
import 'package:gestion_user_app/services/database_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réinitialiser le mot de passe")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(hintText: "Nouveau mot de passe"),
              obscureText: true,
            ),
            TextFormField(
              controller: _confirmController,
              decoration: InputDecoration(hintText: "Confirmer le mot de passe"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text == _confirmController.text) {
                  await DatabaseHelper().updateUserPassword(widget.email, _passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Mot de passe réinitialisé"), backgroundColor: Colors.green),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Les mots de passe ne correspondent pas"), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text("Réinitialiser"),
            ),
          ],
        ),
      ),
    );
  }
}
