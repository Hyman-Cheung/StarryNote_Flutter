import 'package:flutter/material.dart';

class AddToolButton extends StatelessWidget {
  final VoidCallback onAddPen;
  final VoidCallback onAddHighlighter;

  const AddToolButton({
    super.key,
    required this.onAddPen,
    required this.onAddHighlighter,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Add Pen'),
          onTap: onAddPen,
        ),
        PopupMenuItem(
          child: const Text('Add Highlighter'),
          onTap: onAddHighlighter,
        ),
      ],
      icon: const Icon(Icons.add),
      tooltip: 'Add Pen/Highlighter',
    );
  }
}
