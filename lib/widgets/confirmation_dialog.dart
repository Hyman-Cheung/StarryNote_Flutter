import 'package:flutter/material.dart';

// A class to show the dialog and return true(click delete) and false(click cancel):
class ConfirmationDialog {
  static Future<bool?> show(BuildContext context, String content,
      String leftButton, String rightButton, bool isDelete) {
    return showDialog<bool>(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Background color:
          backgroundColor: Colors.white,
          // Adding title with close button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 28), // Spacer to center the content
              Expanded(
                child: Text(
                  'Confirmation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Close button(X):
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(), // Closes dialog
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(), // Removes default padding
              ),
            ],
          ),
          // Padding of the content:
          content: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              content,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // Buttons:
          actions: <Widget>[
            Row(
              // Separate The buttons:
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                // Cancel Button:
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  // Show color when above button:
                  style: TextButton.styleFrom(
                      overlayColor: isDelete ? Colors.black : Colors.red),
                  child: Text(
                    leftButton,
                    style:
                        TextStyle(color: isDelete ? Colors.black : Colors.red),
                  ),
                ),
                // Delete Button:
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  // Show color when above button:
                  style: TextButton.styleFrom(
                      // If the dialog is for the deletion purpose 'isDelete = true', and the right button will be set to red color, otherwise it will be set to indigo:
                      overlayColor: isDelete ? Colors.red : Colors.indigo),
                  child: Text(rightButton,
                      style: TextStyle(
                          color: isDelete ? Colors.red : Colors.indigo)),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
