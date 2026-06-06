import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for rootBundle

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _aboutContent = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAboutContent();
  }

  Future<void> _loadAboutContent() async {
    try {
      String content = await rootBundle
          .loadString('assets/aboutourapp.txt'); // Ensure correct path
      setState(() {
        _aboutContent = content; // Update state with the file content
      });
    } catch (e) {
      setState(() {
        _aboutContent = "Failed to load about content.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.black), // Change text color to black
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _aboutContent,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
