import 'package:flutter/material.dart';
import 'about_page.dart';
import 'help_page.dart';
import 'acknowledgement_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget _currentPage = HelpPage(); // Default page

  void _onItemTapped(String item) {
    setState(() {
      switch (item) {
        case 'Help':
          _currentPage = HelpPage();
          break;
        case 'About':
          _currentPage = AboutPage();
          break;
        case 'Acknowledgement':
          _currentPage = AcknowledgementPage();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 71, 70, 70),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  'assets/logo.png', // Ensure this path is correct
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text("Help / Contact us"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped('Help');
              },
            ),
            Divider(thickness: 1, height: 0),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("About our app"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped('About');
              },
            ),
            Divider(thickness: 1, height: 0),
            ListTile(
              leading: Icon(Icons.handshake_outlined),
              title: Text("Acknowledgement"),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped('Acknowledgement');
              },
            ),
            Divider(thickness: 1, height: 0),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: _currentPage, // Display the currently selected page
            ),
          ),
        ],
      ),
    );
  }
}
