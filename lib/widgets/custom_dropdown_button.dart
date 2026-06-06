import 'package:flutter/material.dart';

class CustomDropdownButton extends StatelessWidget {
  // Fields:
  final String title;
  final dynamic value; // Marking value as final
  final List<DropdownMenuItem<dynamic>> items; // Specify the type for items
  final bool readOnly;
  final ValueChanged onChanged; // Callback for value change

  // Constructor:
  CustomDropdownButton({
    required this.title,
    required this.value,
    required this.items,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title of the Dropdown Button:
        Text(title, style: TextStyle(fontSize: 15)),
        //Dropdown Button:
        DropdownButton<dynamic>(
          dropdownColor: Colors.white,
          value: value,
          items: items,
          borderRadius: BorderRadius.circular(8.0),
          // Change and show the selected item on the menu bar:
          onChanged:
              readOnly ? null : onChanged, // Call the callback with new value
        ),
      ],
    );
  }
}
