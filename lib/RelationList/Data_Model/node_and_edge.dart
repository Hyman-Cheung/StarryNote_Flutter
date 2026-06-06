//======================================================================================================
// node_and_edge.dart
//======================================================================================================

/*
  Define the node data model and edge for implementation.
  Refer to our relational model for details.
*/

import 'package:flutter/material.dart';

class MindMapNode {
  int id;
  int relationID;
  String title;
  String description;
  Offset position;
  int? notebookId;  // Reference to the notebook this node belongs to
  String? sectionId;   // Reference to the section this node belongs to
  String? pageId;      // Reference to the page this node belongs to
  int? labelId;     // Reference to the label this node is associated with

  MindMapNode({
    required this.id,
    required this.relationID,
    required this.title, 
    required this.description, 
    required this.position,
    this.notebookId,
    this.sectionId,
    this.pageId,
    this.labelId,
    });

  // Convert MindMapNode object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'relationID': relationID,
      'title': title,
      'description': description,
      'position_x': position.dx,
      'position_y': position.dy,
      'notebookId': notebookId,  // Optional foreign key
      'sectionId': sectionId,    // Optional foreign key
      'pageId': pageId,          // Optional foreign key
      'labelId': labelId,        // Optional foreign key
    };
  }

  // Create a MindMapNode object from a map (DB retrieval)
  factory MindMapNode.fromMap(Map<String, dynamic> map) {
    return MindMapNode(
      id: map['id'],
      relationID: map['relationID'],
      title: map['title'],
      description: map['description'],
      position: Offset(map['position_x'], map['position_y']),
      notebookId: map['notebookId'],
      sectionId: map['sectionId'],
      pageId: map['pageId'],
      labelId: map['labelId'],
    );
  }

  @override
  String toString() {
    return 'id: $id';
  }
}

class MindMapEdge {
  int id;
  int relationID;
  final MindMapNode from;
  final MindMapNode to;

  MindMapEdge({required this.id, required this.relationID, required this.from, required this.to});

  // Convert MindMapEdge object to map (for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'relationID': relationID,
      'fromID': from.id,
      'toID': to.id,
    };
  }
  
  @override
  String toString() {
    return 'id: $id, relationID: $relationID, fromID: ${from.id}, toID: ${to.id}';
  }
}