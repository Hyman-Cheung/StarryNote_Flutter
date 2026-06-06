import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  // Construtor:
  CustomSearchBar({required this.controller, required this.labelText});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 20), // The padding of the search bar
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.black, // Label text color
          ),
          // Border of the search bar when focused:
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.blueGrey, // Border color when focused
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          border: OutlineInputBorder(), // The border of the search bar
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
