import 'package:flutter/material.dart';

class ColorPickerWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color> presetColors;
  final Future<Color?> Function(Color) onAdvancedColorPicker;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.presetColors,
    required this.onAdvancedColorPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((color) {
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: selectedColor == color ? Colors.indigo : Colors.grey,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
        TextButton(
          onPressed: () async {
            Color? newColor = await onAdvancedColorPicker(selectedColor);
            if (newColor != null) {
              onColorChanged(newColor);
            }
          },
          child:
              const Text('More Colors', style: TextStyle(color: Colors.indigo)),
        ),
      ],
    );
  }
}
