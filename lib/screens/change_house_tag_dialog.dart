import 'package:flutter/material.dart';
import '../models/house.dart';
import '../repositories/house_repository.dart';
import '../utils/logger.dart';

class ChangeHouseTagDialog extends StatefulWidget {
  final House house;
  final VoidCallback onTagChanged;

  const ChangeHouseTagDialog({
    super.key,
    required this.house,
    required this.onTagChanged,
  });

  @override
  State<ChangeHouseTagDialog> createState() => _ChangeHouseTagDialogState();
}

class _ChangeHouseTagDialogState extends State<ChangeHouseTagDialog> {
  late String _selectedTag;
  final HouseRepository _houseRepository = HouseRepository();
  bool _isLoading = false;

  // Available tags for the house
  static const List<String> AVAILABLE_TAGS = [
    'Available',
    'Rented',
    'Maintenance',
    'Sold',
    'Coming Soon',
  ];

  static const Map<String, Color> TAG_COLORS = {
    'Available': Color(0xFF4CAF50),
    'Rented': Color(0xFF2196F3),
    'Maintenance': Color(0xFFFFC107),
    'Sold': Color(0xFFF44336),
    'Coming Soon': Color(0xFF9C27B0),
  };

  static const Map<String, IconData> TAG_ICONS = {
    'Available': Icons.check_circle,
    'Rented': Icons.home,
    'Maintenance': Icons.build,
    'Sold': Icons.done_all,
    'Coming Soon': Icons.schedule,
  };

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.house.tag;
  }

  Future<void> _updateTag() async {
    if (_selectedTag == widget.house.tag) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _houseRepository.updateHouseTag(widget.house.id, _selectedTag);
      
      Logger.info('House tag updated: ${widget.house.id} -> $_selectedTag');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Call the callback to notify parent
        widget.onTagChanged();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag de la maison changé en "$_selectedTag"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      Logger.error('Error updating house tag', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le tag de la maison'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maison: ${widget.house.title}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sélectionnez le nouveau tag:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...AVAILABLE_TAGS.map((tag) {
              final isSelected = _selectedTag == tag;
              final color = TAG_COLORS[tag] ?? Colors.grey;
              final icon = TAG_ICONS[tag] ?? Icons.label;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTag = tag;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? color : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateTag,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}
