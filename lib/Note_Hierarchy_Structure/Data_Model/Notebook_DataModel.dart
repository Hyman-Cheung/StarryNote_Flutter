//======================================================================================================
// Notebook_DataModel.dart
//======================================================================================================

/*
  Define the Notebook data model for implementation.
  Refer to our relational model for details.
*/

// Define "Notebook" model
class Notebook {
  int notebook_id;
  String title;
  DateTime create_at;
  // final int user_id;
  DateTime last_editTime;
  // final List relations;
  // final List studyList;

  Notebook({ // initializer
    required this.notebook_id,
    required this.title,
    required this.create_at,
    // required this.user_id,
    required this.last_editTime,
    // required this.relations,
    // required this.studyList,
  });

  // Convert Notebook object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'notebook_id': notebook_id,
      'title': title,
      'create_at': create_at.toIso8601String(), // store as String
      // 'user_id': user_id,
      'last_editTime': last_editTime.toIso8601String(), // store as String
      // 'relations': relations,
      // 'studyList': studyList,
    };
  }

  // Create a Notebook object from a map (DB retrieval)
  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      notebook_id: map['notebook_id'],
      title: map['title'],
      create_at: DateTime.parse(map['create_at']),
      // user_id: map['user_id'],
      last_editTime: DateTime.parse(map['last_editTime']),
      // relations: List.from(map['relations']),
      // studyList: List.from(map['studyList']),
    );
  }

  @override
  String toString() {
    return title;
  }

  String returnPosition() {
    return title;
  }
}