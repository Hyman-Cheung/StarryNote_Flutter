import 'package:flutter/material.dart';
import 'package:notes_taking_app/Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';

import '../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';

enum LabelType { concept, question, review }

class LabelData {
  // Feilds:
  final int id;
  final LabelType labelType;
  final String name;
  final String description;
  final int priority;
  final Offset position;
  final String createAt;
  final String? lastEditTime;
  final String pageId;
  final String sectionId;
  final int notebookId;

  // Constructor:
  LabelData(
      {required this.id,
      required this.labelType,
      required this.name,
      required this.description,
      required this.priority,
      required this.position,
      required this.createAt,
      required this.lastEditTime,
      required this.pageId,
      required this.sectionId,
      required this.notebookId});

  // A method for maping the object to the database format:
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labelType': labelType.name, // Convert enum to string
      'name': name,
      'description': description,
      'position_x': position.dx,
      'position_y': position.dy,
      'priority': priority,
      'createAt': createAt,
      'lastEditTime': lastEditTime,
      'pageId': pageId,
      'sectionId': sectionId,
      'notebookId': notebookId
    };
  }

  // To String Method:
  @override
  String toString() {
    return name;
  }

  Future<String> returnPosition() async {
    NotePage temp = await fetchPageById(pageId);
    return '${await temp.returnPosition()}, $name';
  }
}
