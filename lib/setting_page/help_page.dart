import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for rootBundle

class HelpPage extends StatefulWidget {
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _helpContent = "Loading...";
  late PageController
      _pageController; // Using 'late' to indicate initialization later
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHelpContent();
    _pageController = PageController(); // Initialize the PageController
    _startBannerAnimation(); // Start the banner animation
  }

  Future<void> _loadHelpContent() async {
    try {
      String content = await rootBundle
          .loadString('assets/contact.txt'); // Ensure correct path
      setState(() {
        _helpContent = content; // Update state with the file content
      });
    } catch (e) {
      setState(() {
        _helpContent = "Failed to load help content."; // Update on error
      });
    }
  }

  void _startBannerAnimation() {
    Future.delayed(Duration(seconds: 7), () {
      // Change interval to 7 seconds
      if (_currentIndex < 2) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startBannerAnimation(); // Repeat the animation
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: const Color.fromARGB(255, 206, 205, 205),
        title: const Text(
          'Help / Contact Us',
          style: TextStyle(color: Colors.black), // Change text color to black
        ),
        backgroundColor: Colors.white, // Set AppBar background color to white
        shadowColor: const Color.fromARGB(255, 237, 236, 236),
        iconTheme: const IconThemeData(
            color: Colors.black), // Change icon color to black
        elevation: 0, // Remove shadow
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _helpContent == "Loading..."
                  ? Center(child: CircularProgressIndicator())
                  : _helpContent.contains("Failed")
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _helpContent,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadHelpContent,
                              child: Text("Retry"),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Text(
                            _helpContent,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
            ),
          ),
          // Moving Banner at the bottom
          Container(
            height: 100, // Height of the banner
            child: PageView(
              controller: _pageController,
              children: [
                _buildBanner("Need Help? We're Here for You!",
                    "Contact us for any assistance you need."),
                _buildBanner("We're here to assist you!",
                    "Feel free to reach out anytime."),
                _buildBanner(
                    "Help is just a message away!", "We're happy to help you."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black, // Text color set to black
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black, // Text color set to black
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
