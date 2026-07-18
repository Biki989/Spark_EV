import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChargerTypeBadge extends StatelessWidget {
  final String type;
  final bool isLarge;

  const ChargerTypeBadge({super.key, required this.type, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final color = SparkTheme.getChargerColor(type);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(isLarge ? 10 : 6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: isLarge ? 18 : 14,
            color: color,
          ),
          SizedBox(width: isLarge ? 8 : 4),
          Text(
            type,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'CCS': return Icons.flash_on;
      case 'Type2': return Icons.electrical_services;
      case 'Tesla': return Icons.bolt;
      case 'CHAdeMO': return Icons.power;
      default: return Icons.ev_station;
    }
  }
}
