//======================================================================================================
// Page_DataModel.dart
//======================================================================================================

/*
  Define the Page data model for implementation.
  Refer to our relational model for details.
*/

import '../Data_Operation/db_ops.dart';

// Define "Page" model
class NotePage {
  String pageId;
  String title;
  DateTime createAt;
  DateTime lastEditTime;
  String sectionId;
  int notebookId;  // New field to store the notebookId
  // int relations;
  // List<Question> questionList;

  NotePage({ // initializer
    required this.pageId,
    required this.title,
    required this.createAt,
    required this.lastEditTime,
    required this.sectionId,
    required this.notebookId,  // Initialize notebookId
    // required this.relations,
    // required this.questionList,
  });

    // Convert Page object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'pageId': pageId,
      'title': title,
      'createAt': createAt.toIso8601String(),
      'lastEditTime': lastEditTime.toIso8601String(),
      'sectionId': sectionId,
      'notebookId': notebookId,  // Add notebookId to map
      // 'relations': relations,
      // 'questionList': questionList.map((q) => q.toMap()).toList(), // Convert questions to JSON-like list
    };
  }

  // Create a Page object from a map (DB retrieval)
  factory NotePage.fromMap(Map<String, dynamic> map) {
    return NotePage(
      pageId: map['pageId'],
      title: map['title'],
      createAt: DateTime.parse(map['createAt']),
      lastEditTime: DateTime.parse(map['lastEditTime']),
      sectionId: map['sectionId'],
      notebookId: map['notebookId'],  // Initialize notebookId from map
      // relations: map['relations'],
      // questionList: (map['questionList'] as List<dynamic>)
      //     .map((q) => Question.fromMap(q))
      //     .toList(),
    );
  }

  @override
  String toString() {
    return title;
  }

  Future<String> returnPosition() async {
    return '${await getNotebookName(notebookId)}, ${await getSectionName(sectionId)}, $title';
  }
}