## Exemples d'utilisation des nouvelles fonctionnalités

### 1. Navigation vers le profil depuis n'importe quel écran

```dart
import 'package:collo/screens/profile_screen.dart';
import 'package:collo/providers/session_provider.dart';

// Dans votre widget, ajoutez un bouton ou un menu pour accéder au profil
ElevatedButton(
  onPressed: () {
    final currentUser = SessionProvider().currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(user: currentUser),
        ),
      );
    }
  },
  child: Text('Mon Profil'),
)

// Ou dans un AppBar avec une icône
AppBar(
  title: Text('Accueil'),
  actions: [
    IconButton(
      icon: Icon(Icons.person),
      onPressed: () {
        final currentUser = SessionProvider().currentUser;
        if (currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(user: currentUser),
            ),
          );
        }
      },
    ),
  ],
)

// Ou dans un Drawer (menu latéral)
Drawer(
  child: ListView(
    children: [
      UserAccountsDrawerHeader(
        accountName: Text(SessionProvider().currentUser?.username ?? ''),
        accountEmail: Text(SessionProvider().currentUser?.email ?? ''),
        currentAccountPicture: CircleAvatar(
          child: Text(SessionProvider().currentUser?.username[0] ?? 'U'),
        ),
      ),
      ListTile(
        leading: Icon(Icons.person),
        title: Text('Mon Profil'),
        onTap: () {
          final currentUser = SessionProvider().currentUser;
          if (currentUser != null) {
            Navigator.pop(context); // Ferme le drawer
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(user: currentUser),
              ),
            );
          }
        },
      ),
      ListTile(
        leading: Icon(Icons.logout),
        title: Text('Déconnexion'),
        onTap: () {
          // Logique de déconnexion
        },
      ),
    ],
  ),
)
```

### 2. Mot de passe oublié dans l'écran de connexion

Le lien "Mot de passe oublié ?" devrait déjà être présent dans votre écran de connexion. Si ce n'est pas le cas, ajoutez :

```dart
// Dans login_screen.dart, ajoutez ce TextButton après le bouton de connexion
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(),
      ),
    );
  },
  child: Text(
    'Mot de passe oublié ?',
    style: TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### 3. Exemple de BottomNavigationBar avec accès au profil

```dart
import 'package:collo/screens/profile_screen.dart';
import 'package:collo/providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) { // Si c'est l'onglet profil
            final currentUser = SessionProvider().currentUser;
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: currentUser),
                ),
              );
            }
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HouseListScreen();
      case 1:
        return FavoritesScreen();
      case 2:
        return NotificationsScreen();
      default:
        return Container(); // Le profil est géré par navigation
    }
  }
}
```

### 4. Test du flux complet de réinitialisation de mot de passe

```dart
// 1. L'utilisateur clique sur "Mot de passe oublié"
// 2. Il entre son email : test@example.com
// 3. Un code est généré (exemple : 123456) et envoyé par email
// 4. Il entre le code reçu
// 5. Il peut définir un nouveau mot de passe
// 6. Il est redirigé vers l'écran de connexion

// Pour tester sans email réel, vous pouvez temporairement modifier
// code_verification_screen.dart pour afficher le code dans un SnackBar
```

### 5. Mise à jour du profil - Exemple de code

```dart
// Le ProfileScreen gère déjà tout automatiquement
// L'utilisateur peut :
// 1. Cliquer sur l'icône de caméra pour changer sa photo
// 2. Cliquer sur l'icône d'édition à côté de chaque champ pour le modifier
// 3. Confirmer avec ✓ ou annuler avec ✗
// 4. Aller dans l'onglet "Sécurité" pour changer le mot de passe
// 5. Se déconnecter

// Exemple de récupération du profil mis à jour après modification
final updatedUser = await DatabaseHelper().getUserByEmail(user.email);
if (updatedUser != null) {
  SessionProvider().setCurrentUser(updatedUser);
}
```

### 6. Gestion de la photo de profil

```dart
// La photo de profil est automatiquement sauvegardée
// Pour afficher la photo ailleurs dans l'app :

import 'dart:io';

class UserAvatar extends StatelessWidget {
  final User user;

  UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey[300],
      backgroundImage: user.imagePath != null
          ? FileImage(File(user.imagePath!))
          : null,
      child: user.imagePath == null
          ? Text(
              user.username[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
```

### 7. Configuration de l'email SMTP

Pour utiliser la fonctionnalité d'envoi d'email, configurez vos identifiants dans `lib/services/email_service.dart` :

```dart
// Méthode 1 : Gmail (recommandé pour le développement)
String username = 'votre-email@gmail.com';
String password = 'xxxx xxxx xxxx xxxx'; // Mot de passe d'application

// Méthode 2 : Autre fournisseur SMTP
final smtpServer = SmtpServer(
  'smtp.votredomaine.com',
  port: 587,
  username: 'votre-email@votredomaine.com',
  password: 'votre-mot-de-passe',
  ssl: false,
  allowInsecure: true,
);
```

### 8. Personnalisation du design

Pour personnaliser les couleurs et le style :

```dart
// Dans profile_screen.dart, changez :
// - Colors.black pour la couleur principale
// - Colors.grey[600] pour la couleur secondaire
// - BorderRadius.circular(16) pour les arrondis

// Exemple de personnalisation avec votre thème
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).primaryColor, // Au lieu de Colors.black
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.person, color: Colors.white),
)
```

---

**Note** : Assurez-vous que `SessionProvider` est correctement configuré dans votre application pour gérer l'utilisateur connecté.
