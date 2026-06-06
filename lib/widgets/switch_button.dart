import 'package:flutter/material.dart';

class SwitchButton extends StatefulWidget {
  // Fields:
  final String title;
  final bool readOnly;
  final bool isSelected;
  final ValueChanged onChanged; // Callback for value change

  // Constructor:
  SwitchButton({
    super.key,
    required this.title,
    required this.readOnly,
    required this.isSelected,
    required this.onChanged,
  });
  @override
  SwitchButtonState createState() => SwitchButtonState();
}

class SwitchButtonState extends State<SwitchButton> {
  late bool _isSelected =
      widget.isSelected; // Local state to track the switch value
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        Text(
          widget.title,
          style: TextStyle(fontSize: 15),
        ),
        // Switch Button:
        Switch(
          value: _isSelected,
          // Background color:
          inactiveTrackColor: Colors.white,
          // The color after clicking the button:
          activeColor: Colors.indigo,
          // Call the callback with new value:
          onChanged: widget.readOnly
              ? null
              : (bool newIsSelected) {
                  setState(() {
                    _isSelected = newIsSelected; // Update the local state
                  });
                  widget.onChanged(newIsSelected);
                },
        ),
      ],
    );
  }
}
