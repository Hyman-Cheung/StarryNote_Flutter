import 'package:flutter/material.dart';

class EraserButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback onSettingsPressed;
  final bool isActive;

  const EraserButton({
    super.key,
    required this.onPressed,
    required this.onSettingsPressed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The backgrould color of the window
      color: Colors.white,
      decoration: isActive
          ? BoxDecoration(
              color: const Color.fromRGBO(33, 150, 243, 0.2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: isActive ? Colors.blue : Colors.grey[700],
              size: 28,
            ),
            onPressed: onPressed,
            tooltip: 'Eraser',
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_drop_down,
              color: isActive ? Colors.blue : Colors.grey[700],
            ),
            onPressed: onSettingsPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Eraser Settings',
          ),
        ],
      ),
    );
  }
}
