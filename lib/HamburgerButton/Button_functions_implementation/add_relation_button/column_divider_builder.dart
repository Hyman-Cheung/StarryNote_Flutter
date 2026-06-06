//======================================================================================================
// column_divider_builder.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';

// Function to build a vertical column with items
Widget buildVerticalColumn(BuildContext context, List items, String title,
    Function onItemSelected, dynamic selectedItem) {
  return Container(
    padding: EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start, // Align to top
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            bool isSelected = item == selectedItem;
            return GestureDetector(
              onTap: () => onItemSelected(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    item.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.indigo : Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Function to build a vertical divider between the columns
Widget buildVerticalDivider(BuildContext context) {
  return Container(
    width: 1, // Thickness of the divider line
    height: MediaQuery.of(context)
        .size
        .height, // Adjust height to the screen size (or dialog height)
    color: Colors.black, // Divider color
    margin: EdgeInsets.symmetric(horizontal: 10), // Spacing between columns
  );
}
