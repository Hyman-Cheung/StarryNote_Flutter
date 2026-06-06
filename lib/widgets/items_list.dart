import 'package:flutter/material.dart';

class ItemsList {
  //  A item list for storing priorities:
  List<DropdownMenuItem<int>> get priorityItems {
    List<DropdownMenuItem<int>> menuItems = [
      DropdownMenuItem(
        value: 0,
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: Text("High", style: TextStyle(color: Colors.red)),
        ),
      ),
      DropdownMenuItem(
        value: 1,
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: Text("Medium", style: TextStyle(color: Colors.orange)),
        ),
      ),
      DropdownMenuItem(
        value: 2,
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: Text("Low", style: TextStyle(color: Colors.black)),
        ),
      ),
    ];
    return menuItems;
  }

  //  A item list for storing Interval items:
  List<DropdownMenuItem<Duration>> get intervalItems {
    List<DropdownMenuItem<Duration>> menuItems = [
      DropdownMenuItem(
        value: Duration(minutes: 1),
        child: Text('Every Minute'),
      ),
      DropdownMenuItem(value: Duration(days: 1), child: Text('Daily')),
      DropdownMenuItem(value: Duration(days: 7), child: Text('Weekly')),
      DropdownMenuItem(value: Duration(days: 30), child: Text('Monthly')),
    ];
    return menuItems;
  }
}
