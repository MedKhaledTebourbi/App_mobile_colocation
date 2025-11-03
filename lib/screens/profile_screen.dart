import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gestion_user_app/models/user.dart';
import 'package:gestion_user_app/screens/login_screen.dart';
import 'package:gestion_user_app/services/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  ProfileScreen({required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  bool _isLoading = false;
  int _currentIndex = 0;

  // États d'édition pour chaque champ
  bool _editingName = false;
  bool _editingDob = false;
  bool _editingPhone = false;
  bool _editingAddress = false;

  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _dobController.text = widget.user.dateOfBirth ?? '';
    _phoneController.text = widget.user.phone ?? '';
    _addressController.text = widget.user.address ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isLoading = true);

      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        _imageFile = File(pickedFile.path);
        widget.user.imagePath = pickedFile.path;
        _isLoading = false;
      });

      await DatabaseHelper().updateUserProfile(widget.user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo de profil mise à jour'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false);
            },
            child: Text("Déconnexion"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSingleField(String fieldName, String value) async {
    switch (fieldName) {
      case 'name':
        widget.user.username = value;
        break;
      case 'dob':
        widget.user.dateOfBirth = value;
        break;
      case 'phone':
        widget.user.phone = value;
        break;
      case 'address':
        widget.user.address = value;
        break;
    }

    await DatabaseHelper().updateUserProfile(widget.user);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName mis à jour'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final _oldController = TextEditingController();
    final _newController = TextEditingController();
    final _confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField("Ancien mot de passe", _oldController, obscureText: true),
            SizedBox(height: 12),
            _buildDialogTextField("Nouveau mot de passe", _newController, obscureText: true),
            SizedBox(height: 12),
            _buildDialogTextField("Confirmer mot de passe", _confirmController, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (_newController.text != _confirmController.text) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Les mots de passe ne correspondent pas")));
                return;
              }

              bool success = await DatabaseHelper().changePassword(
                widget.user.email,
                _oldController.text,
                _newController.text,
              );

              if (success) {
                widget.user.password = _newController.text;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Mot de passe changé avec succès")));
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Ancien mot de passe incorrect")));
              }
            },
            child: Text("Valider"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(String hintText, TextEditingController controller, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isEditing
          ? Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: onSave,
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: onCancel,
            ),
          ],
        ),
      )
          : ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : "Non renseigné",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, size: 20),
          onPressed: onEdit,
        ),
      ),
    );
  }

  // Contenu principal basé sur l'index sélectionné
  Widget _buildMainContent() {
    switch (_currentIndex) {
      case 0: // Profil
        return _buildProfileContent();
      case 1: // Mot de passe
        return _buildPasswordContent();
      default:
        return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (widget.user.imagePath != null
                      ? FileImage(File(widget.user.imagePath!))
                      : null),
                  child: (_imageFile == null && widget.user.imagePath == null)
                      ? Text(
                    widget.user.username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Modifier la photo",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 32),

          // Champs éditables inline
          _buildEditableField(
            label: "Nom complet",
            value: widget.user.username,
            controller: _usernameController,
            isEditing: _editingName,
            icon: Icons.person_rounded,
            onEdit: () => setState(() {
              _editingName = true;
              _usernameController.text = widget.user.username;
            }),
            onSave: () {
              if (_usernameController.text.trim().isNotEmpty) {
                _updateSingleField('name', _usernameController.text.trim());
                setState(() => _editingName = false);
              }
            },
            onCancel: () => setState(() {
              _editingName = false;
              _usernameController.text = widget.user.username;
            }),
          ),

          // Email (non éditable)
          Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.email_rounded, color: Colors.white, size: 20),
              ),
              title: Text(
                "Email",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              subtitle: Text(
                widget.user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          _buildEditableField(
            label: "Date de naissance",
            value: widget.user.dateOfBirth ?? '',
            controller: _dobController,
            isEditing: _editingDob,
            icon: Icons.calendar_today_rounded,
            onEdit: () => setState(() {
              _editingDob = true;
              _dobController.text = widget.user.dateOfBirth ?? '';
            }),
            onSave: () {
              _updateSingleField('dob', _dobController.text.trim());
              setState(() => _editingDob = false);
            },
            onCancel: () => setState(() {
              _editingDob = false;
              _dobController.text = widget.user.dateOfBirth ?? '';
            }),
          ),

          _buildEditableField(
            label: "Téléphone",
            value: widget.user.phone ?? '',
            controller: _phoneController,
            isEditing: _editingPhone,
            icon: Icons.phone_rounded,
            onEdit: () => setState(() {
              _editingPhone = true;
              _phoneController.text = widget.user.phone ?? '';
            }),
            onSave: () {
              _updateSingleField('phone', _phoneController.text.trim());
              setState(() => _editingPhone = false);
            },
            onCancel: () => setState(() {
              _editingPhone = false;
              _phoneController.text = widget.user.phone ?? '';
            }),
          ),

          _buildEditableField(
            label: "Adresse",
            value: widget.user.address ?? '',
            controller: _addressController,
            isEditing: _editingAddress,
            icon: Icons.home_rounded,
            onEdit: () => setState(() {
              _editingAddress = true;
              _addressController.text = widget.user.address ?? '';
            }),
            onSave: () {
              _updateSingleField('address', _addressController.text.trim());
              setState(() => _editingAddress = false);
            },
            onCancel: () => setState(() {
              _editingAddress = false;
              _addressController.text = widget.user.address ?? '';
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sécurité du compte",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Gérez la sécurité de votre compte",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 32),

          // Option changement de mot de passe
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                ),
                title: Text(
                  "Changer le mot de passe",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text("Mettez à jour votre mot de passe"),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showChangePasswordDialog,
              ),
            ),
          ),
          SizedBox(height: 20),

          // Déconnexion
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.red[50],
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                ),
                title: Text(
                  "Déconnexion",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.red),
                ),
                subtitle: Text("Se déconnecter de votre compte"),
                onTap: _showLogoutDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        elevation: 0,
        centerTitle: true,
      ),
      body: _buildMainContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_rounded),
              activeIcon: Icon(Icons.lock),
              label: 'Sécurité',
            ),
          ],
        ),
      ),
    );
  }
}