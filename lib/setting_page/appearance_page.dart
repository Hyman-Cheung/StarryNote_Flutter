import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for rootBundle

class AppearancePage extends StatefulWidget {
  @override
  _AppearancePageState createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String _appearanceContent = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAppearanceContent();
  }

  Future<void> _loadAppearanceContent() async {
    try {
      String content = await rootBundle.loadString('assets/appearance.txt');
      setState(() {
        _appearanceContent = content; // Update state with the file content
      });
    } catch (e) {
      setState(() {
        _appearanceContent = "Failed to load appearance content.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        surfaceTintColor: const Color.fromARGB(255, 206, 205, 205),
        title: const Text(
          'Appearance',
          style: TextStyle(color: Colors.black), // Change text color to black
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        shadowColor: const Color.fromARGB(255, 237, 236, 236),
        iconTheme: const IconThemeData(
            color: Colors.black), // Change icon color to black
        elevation: 0, // Optional: Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _appearanceContent,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
