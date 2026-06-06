//======================================================================================================
// DBDataModel.dart
//======================================================================================================

/*
  Define all the data model for database implementation.
  Refer to our relational model for details.
*/

// Note: DateTime class is used for fields that are of "timestamp".

// Define "Users" model

import 'package:color/color.dart'; // import Color package
import 'package:vector_math/vector_math.dart' show Vector;

class Users {
  final int identifier_id;
  final String username;
  final String password;
  final String email;
  final DateTime register_time;

  const Users({
    // initializer
    required this.identifier_id,
    required this.username,
    required this.password,
    required this.email,
    required this.register_time,
  });
}

// Define "TypeContent" model
class TypeContent {
  final int id;
  final int pageID;
  final double fontSize;
  final Color fontColour;
  final List<String> fontStyles;
  final String fontFamily;
  final Vector location;

  TypeContent({
    // initializer
    required this.id,
    required this.pageID,
    required this.fontSize,
    required this.fontColour,
    required this.fontStyles,
    required this.fontFamily,
    required this.location,
  });
}

// Define "Task" model
class Task {
  final int taskId;
  final int userId;
  final String name;
  final DateTime time;
  final DateTime date;
  final String venue;
  final String description;
  final int priority;
  final int notebookId;
  final int labelId;
  final DateTime earlyReminder;

  Task({
    // initializer
    required this.taskId,
    required this.userId,
    required this.name,
    required this.time,
    required this.date,
    required this.venue,
    required this.description,
    required this.priority,
    required this.notebookId,
    required this.labelId,
    required this.earlyReminder,
  });
}

// Define "Label" model
class Label {
  final int id;
  final int pageID;
  final Vector location;
  final Color color;
  final Shape shape;
  final String type;
  final DateTime createAt;
  final String name;
  final String description;
  final int priority;
  final DateTime lastEditTime;

  Label({
    // initializer
    required this.id,
    required this.pageID,
    required this.location,
    required this.color,
    required this.shape,
    required this.type,
    required this.createAt,
    required this.name,
    required this.description,
    required this.priority,
    required this.lastEditTime,
  });
}

// Define "HandwrittenStroke" model
class HandwrittenStroke {
  final int id;
  final int pageId;
  final String strokeData;
  final DateTime createAt;

  HandwrittenStroke({
    // initializer
    required this.id,
    required this.pageId,
    required this.strokeData,
    required this.createAt,
  });
}

// Define "ImageData" model -> "image" in the schema
class ImageData {
  final int imgId;
  final int pageId;
  final String imgUrl;
  final DateTime createdAt;

  ImageData({
    //initializer
    required this.imgId,
    required this.pageId,
    required this.imgUrl,
    required this.createdAt,
  });
}

//define the class of the shape
class Shape {
  final String name;

  Shape({required this.name});
}
