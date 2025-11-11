import 'dart:math';

/// Génère un code de vérification aléatoire à 6 chiffres
String generateCode() {
  return (Random().nextInt(900000) + 100000).toString();
}
