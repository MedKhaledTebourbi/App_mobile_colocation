import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/house_list_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_houses_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';
import 'providers/session_provider.dart';
import 'services/notification_service.dart';

void main() {
  if (kIsWeb) {
    // Initialize sqflite for web
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collo - House Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final User user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final NotificationService _notificationService;
  late final SessionProvider _sessionProvider;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _sessionProvider = SessionProvider();
    
    // Set current user in SessionProvider
    _sessionProvider.setCurrentUser(widget.user);
    
    _screens = [
      HouseListScreen(user: widget.user),
      MyBookingsScreen(user: widget.user),
      FavoritesScreen(user: widget.user),
      const MyHousesScreen(),
    ];
    
    // Afficher les notifications au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.showStartupNotifications(context);
      _initializeUnreadMessageCount();
      _startMessagePolling();
    });
  }

  Future<void> _initializeUnreadMessageCount() async {
    try {
      final chatRepo = _notificationService.getChatRepository();
      final unreadCount = await chatRepo.getUnreadMessageCount(widget.user.email);
      if (mounted) {
        setState(() {
          _sessionProvider.setUnreadMessageCount(unreadCount);
        });
      }
    } catch (e) {
      print('Error initializing unread count: $e');
    }
  }

  void _startMessagePolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkForNewMessages();
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    if (!mounted) return;
    
    try {
      final chatRepo = _notificationService.getChatRepository();
      final unreadCount = await chatRepo.getUnreadMessageCount(widget.user.email);
      
      if (mounted) {
        final previousCount = _sessionProvider.unreadMessageCount;
        
        if (unreadCount != previousCount) {
          setState(() {
            _sessionProvider.setUnreadMessageCount(unreadCount);
          });
          
          // Show notification if new messages arrived
          if (unreadCount > previousCount) {
            _notificationService.showNewMessageNotification(context, unreadCount - previousCount);
          }
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
    
    // Schedule next check
    if (mounted) {
      _startMessagePolling();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Déconnexion'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setMainState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Collo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue[700],
            elevation: 0,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(user: widget.user),
                        ),
                      ).then((_) {
                        setMainState(() {
                          _sessionProvider.resetUnreadMessages();
                        });
                      });
                    },
                  ),
                  if (_sessionProvider.unreadMessageCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _sessionProvider.unreadMessageCount > 99
                              ? '99+'
                              : _sessionProvider.unreadMessageCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(user: widget.user),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.user.username[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.user.username,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Mon Profil'),
                      ],
                    ),
                    onTap: () {
                      // Delay navigation to avoid popup menu dismiss issues
                      Future.delayed(Duration(milliseconds: 100), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: widget.user),
                          ),
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Déconnexion'),
                      ],
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blue[700],
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_online),
                label: 'Réservations',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favoris',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_work),
                label: 'Mes maisons',
              ),
            ],
          ),
        );
      },
    );
  }
}
