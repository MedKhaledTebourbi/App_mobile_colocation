import 'dart:math';

String generateCode() {
  return (Random().nextInt(900000) + 100000).toString(); // 6 chiffres
}
