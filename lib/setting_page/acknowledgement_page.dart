import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for rootBundle

class AcknowledgementPage extends StatefulWidget {
  @override
  _AcknowledgementPageState createState() => _AcknowledgementPageState();
}

class _AcknowledgementPageState extends State<AcknowledgementPage> {
  String _acknowledgementContent = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAcknowledgementContent();
  }

  Future<void> _loadAcknowledgementContent() async {
    try {
      String content = await rootBundle
          .loadString('assets/acknowledgement.txt'); // Ensure correct path
      setState(() {
        _acknowledgementContent = content; // Update state with the file content
      });
    } catch (e) {
      setState(() {
        _acknowledgementContent = "Failed to load acknowledgement content.";
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
          'Acknowledgements',
          style: TextStyle(color: Colors.black), // Change text color to black
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        shadowColor: const Color.fromARGB(255, 237, 236, 236),
        iconTheme: const IconThemeData(
            color: Colors.black), // Change icon color to black
        elevation: 0, // Remove shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _acknowledgementContent,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
