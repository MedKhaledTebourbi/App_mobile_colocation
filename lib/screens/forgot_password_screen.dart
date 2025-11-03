import 'package:flutter/material.dart';
import 'package:gestion_user_app/utils//utils.dart';
import'package:gestion_user_app/services/email_service.dart';
import 'code_verification_screen.dart';

import 'package:gestion_user_app/services/database_helper.dart';


class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mot de passe oublié")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(hintText: "Entrez votre email"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Veuillez entrer votre email";
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String code = generateCode();
                    await sendEmail(_emailController.text.trim(), code);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CodeVerificationScreen(
                          email: _emailController.text.trim(),
                          code: code,
                        ),
                      ),
                    );
                  }
                },
                child: Text("Envoyer le code"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
