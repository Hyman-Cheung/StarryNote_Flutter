//======================================================================================================
// relation_model.dart
//======================================================================================================

/*
  Define the relation data model for implementation.
  Refer to our relational model for details.
*/

import 'node_and_edge.dart';

// Define "relation" model
class Relation {
  int relationID;
  String title;
  DateTime createAt;
  DateTime lastEditTime;
  List<MindMapNode> nodes; // List of nodes in this relation
  List<MindMapEdge> edges; // List of edges in this relation

  Relation({ // initializer
    required this.relationID,
    required this.title,
    required this.createAt,
    required this.lastEditTime,
    this.nodes = const [], // Initialize with empty lists
    this.edges = const [],
  });

  // Convert relation object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'relationID': relationID,
      'title': title,
      'createAt': createAt.toIso8601String(), // store as String
      'lastEditTime': lastEditTime.toIso8601String(), // store as String
    };
  }

  // Create a relation object from a map (DB retrieval)
  factory Relation.fromMap(Map<String, dynamic> map) {
    return Relation(
      relationID: map['relationID'],
      title: map['title'],
      createAt: DateTime.parse(map['createAt']),
      lastEditTime: DateTime.parse(map['lastEditTime']),
    );
  }

  @override
  String toString() {
    return title;
  }
}