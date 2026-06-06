import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int maxLines;
  final bool readOnly;
  final Icon icon;
  final VoidCallback? onTap;
  // Construtor:
  CustomTextField({
    required this.controller,
    required this.labelText,
    required this.maxLines,
    required this.readOnly,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      // Allow or limit user to edit the text field:
      readOnly: readOnly,
      decoration: InputDecoration(
        // Label text:
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.black, // Label text color
        ),
        // Border of the text field when focused:
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blueGrey, // Border color when focused
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        // Border of the text field when enabled:
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black, // Border color when enabled
          ),
          borderRadius: BorderRadius.circular(18.0),
        ),
        // Show the clock icon on the text field:
        suffixIcon: icon,
      ),
      // Text style:
      style: TextStyle(
        color: Colors.black, // Text color when entering text
      ),
      maxLines: maxLines,
      // An action after taping the text field:
      onTap: onTap,
    );
  }
}
