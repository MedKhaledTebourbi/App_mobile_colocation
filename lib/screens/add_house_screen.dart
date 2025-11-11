import 'package:flutter/material.dart';
import 'package:collo/models/house.dart';
import 'package:collo/providers/house_provider.dart';

class AddHouseScreen extends StatefulWidget {
  final House? houseToEdit;

  const AddHouseScreen({Key? key, this.houseToEdit}) : super(key: key);

  @override
  _AddHouseScreenState createState() => _AddHouseScreenState();
}

class _AddHouseScreenState extends State<AddHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedImageUrl;
  String _selectedPropertyType = 'House';
  bool _isLoading = false;
  final HouseProvider _houseProvider = HouseProvider();

  @override
  void initState() {
    super.initState();
    if (widget.houseToEdit != null) {
      _titleController.text = widget.houseToEdit!.title;
      _descriptionController.text = widget.houseToEdit!.description;
      _priceController.text = widget.houseToEdit!.price.toString();
      _locationController.text = widget.houseToEdit!.address;
      _bedroomsController.text = widget.houseToEdit!.bedrooms.toString();
      _bathroomsController.text = widget.houseToEdit!.bathrooms.toString();
      _areaController.text = widget.houseToEdit!.area.toString();
      _selectedImageUrl = widget.houseToEdit!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _addHouse() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImageUrl == null || _selectedImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.houseToEdit != null;
      final houseId = isEditing 
          ? widget.houseToEdit!.id 
          : DateTime.now().millisecondsSinceEpoch.toInt();

      House house = House(
        id: houseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        address: _locationController.text.trim(),
        bedrooms: int.parse(_bedroomsController.text.trim()),
        bathrooms: int.parse(_bathroomsController.text.trim()),
        area: double.parse(_areaController.text.trim()),
        imageUrl: _selectedImageUrl!,
        isFavorite: widget.houseToEdit?.isFavorite ?? false,
        ownerEmail: widget.houseToEdit?.ownerEmail ?? '',
        propertyType: _selectedPropertyType,
        ownershipStatus: 'For Rent',
      );

      if (isEditing) {
        await _houseProvider.updateHouse(house);
      } else {
        await _houseProvider.addHouse(house);
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Maison modifiée avec succès !' : 'Maison ajoutée avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  void _selectImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionner une image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Galerie d\'images'),
              subtitle: const Text('Sélectionner une image URL'),
              onTap: () {
                Navigator.pop(context);
                _showImageUrlDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_search, color: Colors.blue),
              title: const Text('Images d\'exemple'),
              subtitle: const Text('Utiliser une image d\'exemple'),
              onTap: () {
                Navigator.pop(context);
                _showSampleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrer l\'URL de l\'image'),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                setState(() {
                  _selectedImageUrl = urlController.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSampleImages() {
    final sampleImages = [
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800',
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une image'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: sampleImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageUrl = sampleImages[index];
                  });
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    sampleImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajouter une maison",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                Text(
                  "Détails de la maison",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),

                // Sélection d'image
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue[700]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue[50],
                    ),
                    child: _selectedImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _selectedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Erreur de chargement'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Cliquez pour ajouter une image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'URL ou galerie d\'images',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Titre de la maison
                _buildTextField(
                  controller: _titleController,
                  label: "Titre",
                  hint: "Ex: Maison moderne avec jardin",
                  icon: Icons.home_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir le titre";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: "Description",
                  hint: "Décrivez votre maison...",
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir une description";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Prix
                _buildTextField(
                  controller: _priceController,
                  label: "Prix (€/mois)",
                  hint: "Ex: 1200",
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir le prix";
                    }
                    if (double.tryParse(value) == null) {
                      return "Veuillez entrer un nombre valide";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Localisation
                _buildTextField(
                  controller: _locationController,
                  label: "Localisation",
                  hint: "Ex: Paris, 75001",
                  icon: Icons.location_on_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir la localisation";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Chambres et Salles de bain
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _bedroomsController,
                        label: "Chambres",
                        hint: "Ex: 3",
                        icon: Icons.bed_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Requis";
                          }
                          if (int.tryParse(value) == null) {
                            return "Nombre invalide";
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _bathroomsController,
                        label: "Salles de bain",
                        hint: "Ex: 2",
                        icon: Icons.bathroom_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Requis";
                          }
                          if (int.tryParse(value) == null) {
                            return "Nombre invalide";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Surface
                _buildTextField(
                  controller: _areaController,
                  label: "Surface (m²)",
                  hint: "Ex: 150",
                  icon: Icons.square_foot_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir la surface";
                    }
                    if (double.tryParse(value) == null) {
                      return "Veuillez entrer un nombre valide";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Property Type Dropdown
                _buildDropdownField(
                  label: "Type de propriété",
                  value: _selectedPropertyType,
                  items: ['House', 'Villa', 'Apartment', 'Condo'],
                  onChanged: (value) {
                    setState(() {
                      _selectedPropertyType = value!;
                    });
                  },
                  icon: Icons.home_rounded,
                ),
                SizedBox(height: 32),

                // Bouton Ajouter
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addHouse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Ajouter la maison",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: maxLines == 1
                  ? Container(
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.blue[700],
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: maxLines == 1 ? 18 : 16,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue[700],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
