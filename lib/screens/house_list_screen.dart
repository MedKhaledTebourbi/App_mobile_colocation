import 'package:flutter/material.dart';
import '../models/house.dart';
import '../models/user.dart';
import '../data/sample_houses.dart';
import '../providers/house_provider.dart';
import 'house_detail_screen.dart';
import 'add_house_screen.dart';

class HouseListScreen extends StatefulWidget {
  final User user;

  const HouseListScreen({super.key, required this.user});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  List<House> allHouses = [];
  List<House> filteredHouses = [];
  String selectedFilter = 'All';
  String ownershipFilter = 'All'; // 'All', 'Owned', 'For Rent'
  String searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final HouseProvider _houseProvider = HouseProvider();

  @override
  void initState() {
    super.initState();
    _initializeHouses();
  }

  void _initializeHouses() async {
    try {
      await _houseProvider.initialize();
      // Get houses with dynamically calculated status
      final housesWithStatus = await _houseProvider.getHousesWithDynamicStatus();
      setState(() {
        allHouses = housesWithStatus;
        filteredHouses = allHouses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing houses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterHouses() {
    setState(() {
      filteredHouses = allHouses.where((house) {
        // Filtre par type
        bool typeMatch = true;
        if (selectedFilter != 'All') {
          typeMatch = house.title.toLowerCase().contains(selectedFilter.toLowerCase());
        }

        // Filtre par propriété (Owned or For Rent)
        // "Owned" means houses owned by the current user
        bool ownershipMatch = true;
        if (ownershipFilter == 'Owned') {
          ownershipMatch = house.ownerEmail == widget.user.email;
        } else if (ownershipFilter == 'For Rent') {
          ownershipMatch = house.ownershipStatus == 'For Rent';
        }

        // Filtre par recherche
        bool searchMatch = house.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            house.address.toLowerCase().contains(searchQuery.toLowerCase());

        return typeMatch && ownershipMatch && searchMatch;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    searchQuery = value;
    _filterHouses();
  }

  void _onFilterChanged(String filter) {
    selectedFilter = filter;
    _filterHouses();
  }

  void _onOwnershipFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        ownershipFilter = filter;
      });
      _filterHouses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maisons'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Mes maisons',
            icon: const Icon(Icons.home_work_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/my-houses');
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Champ de recherche
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Rechercher une maison...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ownership Filter Dropdown
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: ownershipFilter,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.filter_list,
                        color: Colors.blue[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All Properties'),
                      ),
                      DropdownMenuItem(
                        value: 'Owned',
                        child: Text('Owned Houses'),
                      ),
                      DropdownMenuItem(
                        value: 'For Rent',
                        child: Text('For Rent'),
                      ),
                    ],
                    onChanged: _onOwnershipFilterChanged,
                  ),
                ),
                const SizedBox(height: 16),
                // Filtres
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('House'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Apartment'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Villa'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Condo'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des maisons
          Expanded(
            child: filteredHouses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune maison trouvée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Essayez une autre recherche ou filtre',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredHouses.length,
                    itemBuilder: (context, index) {
                      return _buildHouseCard(filteredHouses[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHouseScreen()),
          ).then((result) {
            // Rafraîchir la liste après ajout
            if (result == true) {
              setState(() {
                allHouses = _houseProvider.houses;
                _filterHouses();
              });
            }
          });
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter une maison'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHouseCard(House house) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseDetailScreen(
              house: house,
              userEmail: widget.user.email,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Bigger
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    house.imageUrl,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 280,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                // Property Type Tag (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildTag(house.propertyType, Colors.blue),
                ),
                // House Tag Badge (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildHouseTagBadge(house.tag),
                ),
                // Ownership Status Badge (bottom right)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _buildOwnershipBadge(house.ownershipStatus),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Name
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Propriétaire: ${house.ownerUsername.isNotEmpty ? house.ownerUsername : house.agentName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          house.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            house.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          house.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFeature(Icons.bed, house.bedrooms.toString()),
                      const SizedBox(width: 16),
                      _buildFeature(Icons.bathtub, house.bathrooms.toString()),
                      const SizedBox(width: 16),
                      _buildFeature(Icons.square_foot, house.area.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${house.price}/month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHouseTagBadge(String tag) {
    final tagColors = {
      'Available': Color(0xFF4CAF50),
      'Rented': Color(0xFF2196F3),
      'Maintenance': Color(0xFFFFC107),
      'Sold': Color(0xFFF44336),
      'Coming Soon': Color(0xFF9C27B0),
    };

    final tagIcons = {
      'Available': Icons.check_circle,
      'Rented': Icons.home,
      'Maintenance': Icons.build,
      'Sold': Icons.done_all,
      'Coming Soon': Icons.schedule,
    };

    final backgroundColor = tagColors[tag] ?? Colors.grey;
    final icon = tagIcons[tag] ?? Icons.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnershipBadge(String status) {
    final isOwned = status == 'Owned';
    final backgroundColor = isOwned ? Colors.green : Colors.orange;
    final icon = isOwned ? Icons.check_circle : Icons.home_outlined;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
