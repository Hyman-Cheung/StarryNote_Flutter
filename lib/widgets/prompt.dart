import 'package:flutter/material.dart';

class Prompt {
  static void show(BuildContext context, String message) {
    // Get the overlay(a transparent layer that sits above the widget/context we call) of the context:
    final overlay = Overlay.of(context);
    // Create the content of the prompt:
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        // Set the size of the prompt according to the window size:
        left: MediaQuery.of(context).size.width * 0.3,
        right: MediaQuery.of(context).size.width * 0.3,
        child: Material(
          child: Container(
            // The padding of the prompt:
            padding: EdgeInsets.all(13),
            decoration: BoxDecoration(
              // The background color of the prompt:
              color: const Color.fromARGB(255, 72, 71, 71),
            ),
            child: Text(
              message,
              // Move the textto the the center:
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
    // Show the prompt content on pop-up window:
    overlay.insert(entry);
    // Set the timer to remove the prompt:
    Future.delayed(Duration(seconds: 2), () => entry.remove());
  }
}
