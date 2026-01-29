import 'package:flutter/material.dart';

class MapRefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MapRefreshButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.refresh, size: 16, color: Color(0xFF111827)),
              SizedBox(width: 6),
              Text(
                '새로고침',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
