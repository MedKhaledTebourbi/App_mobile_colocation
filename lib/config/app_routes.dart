import 'package:flutter/material.dart';
import 'package:collo/screens/my_houses_screen.dart';
import 'package:collo/screens/notifications_screen.dart';
import 'package:collo/models/user.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String myHouses = '/my-houses';
  static const String notifications = '/notifications';
  static const String houseDetail = '/house-detail';
  static const String addHouse = '/add-house';
  static const String bookingForm = '/booking-form';
  static const String payment = '/payment';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case myHouses:
        return MaterialPageRoute(
          builder: (_) => const MyHousesScreen(),
        );
      case notifications:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => NotificationsScreen(user: user ?? User(
            username: 'User',
            email: 'user@example.com',
            password: '',
            role: Role.user,
          )),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
