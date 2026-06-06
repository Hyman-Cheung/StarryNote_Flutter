//======================================================================================================
// Section_DataModel.dart
//======================================================================================================

/*
  Define the Section data model for implementation.
  Refer to our relational model for details.
*/

import '../Data_Operation/db_ops.dart';

// Define "Section" model
class Section {
  String sectionId;
  String title;
  DateTime createAt;
  DateTime lastEditTime;
  int notebookId;
  // int relations;

  Section({ // initializer
    required this.sectionId,
    required this.title,
    required this.createAt,
    required this.lastEditTime,
    required this.notebookId,
    // required this.relations,
  });

  // Convert Section object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'sectionId': sectionId,
      'title': title,
      'createAt': createAt.toIso8601String(),
      'lastEditTime': lastEditTime.toIso8601String(),
      'notebookId': notebookId,
      // 'relations': relations,
    };
  }

  // Create a Section object from a map (DB retrieval)
  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      sectionId: map['sectionId'],
      title: map['title'],
      createAt: DateTime.parse(map['createAt']),
      lastEditTime: DateTime.parse(map['lastEditTime']),
      notebookId: map['notebookId'],
      // relations: map['relations'],
    );
  }

  @override
  String toString() {
    return title;
  }

  Future<String> returnPosition() async {
    return '${await getNotebookName(notebookId)}, $title';
  }
}