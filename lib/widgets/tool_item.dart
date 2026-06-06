import 'package:flutter/material.dart';
import '../models/models.dart';

class ToolItem extends StatelessWidget {
  final WritingTool tool;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ToolItem({
    super.key,
    required this.tool,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData = tool.isHighlighter ? Icons.brush : Icons.create;
    String tooltipText = tool.isHighlighter ? 'Highlighter' : 'Pen';

    return Tooltip(
      message: tooltipText, // Display "Pen" or "Highlighter" based on tool type
      child: GestureDetector(
        onTap: onSelect,
        onDoubleTap: onEdit,
        onLongPress: onDelete,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(
            iconData,
            color: tool.color,
            size: 28,
          ),
        ),
      ),
    );
  }
}
