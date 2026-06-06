//======================================================================================================
// db_ops.dart
//======================================================================================================

/*
  Provide abstract functions for implementing different features (such as buttons).
*/

import '../../database/db_helper.dart';

import '../Data_Model/relation_model.dart'; // Import the relation model
import '../Data_Model/node_and_edge.dart'; // Import the node and edge model

final DBHelper _dbHelper = DBHelper();

// Create a Relation
Future<int> createRelation({
  required String title,
  required DateTime createAt,
  required DateTime lastEditTime,
}) async {
  final newRelation = Relation(
    relationID: 0,  // Auto-generated ID
    title: title,
    createAt: createAt,
    lastEditTime: lastEditTime,
  );
  return await _dbHelper.insertRelation(newRelation);
}

// Read all Relations
Future<List<Relation>> readRelations() async {
  return await _dbHelper.getRelations();
}

// Update a Relation by ID
Future<int> updateRelation({
  required int relationID,
  required String title,
  required DateTime createAt,
  required DateTime lastEditTime,
}) async {
  final updatedRelation = Relation(
    relationID: relationID,
    title: title,
    createAt: createAt,
    lastEditTime: lastEditTime,
  );
  return await _dbHelper.updateRelation(updatedRelation);
}

// Abstract function to change the title of a Relation
Future<int> updateRelationTitle({
  required String title,
  required int relationID,
}) async {
  return await _dbHelper.updateTitle(title, relationID);
}

// Delete a Relation by ID
Future<int> deleteRelation(int relationID) async {
  return await _dbHelper.deleteRelation(relationID);
}

// Create a MindMapNode
Future<int> createMindMapNode(MindMapNode node) async {
  return await _dbHelper.insertMindMapNode(node);
}

// Read all MindMapNodes for a given relationID
Future<List<MindMapNode>> readAllMindMapNodesbyRelation(int relationID) async {
  return await _dbHelper.getAllMindMapNodesbyRelation(relationID);
}

// Read a single MindMapNode by its ID
Future<MindMapNode?> readMindMapNodeById(int id) async {
  return await _dbHelper.getMindMapNodeById(id);
}

// Update a MindMapNode by its ID
Future<void> updateMindMapNode(MindMapNode node) async {
  await _dbHelper.updateMindMapNode(node);
}

// Create a MindMapEdge
Future<void> createMindMapEdge(MindMapEdge edge) async {
  await _dbHelper.insertMindMapEdge(edge);
}

// Read all MindMapEdges by relation
Future<List<Map<String, dynamic>>> readAllMindMapEdgesbyRelation(int relationID) async {
  return await _dbHelper.getAllMindMapEdgesbyRelation(relationID);
}

// Read a single MindMapEdge by its ID
Future<MindMapEdge?> readMindMapEdgeById(int id) async {
  return await _dbHelper.getMindMapEdgeById(id);
}

Future<List<int>> deleteNodesAssociatedwithNotebook(int notebookID) async {
  return await _dbHelper.deleteNodesByNotebookId(notebookID);
}

Future<List<int>> deleteNodesAssociatedwithSection(String sectionID) async {
  return await _dbHelper.deleteNodesBySectionId(sectionID);
}

Future<List<int>> deleteNodesAssociatedwithPage(String pageID) async {
  return await _dbHelper.deleteNodesByPageId(pageID);
}

Future<List<int>> deleteNodesAssociatedwithLabel(int labelID) async {
  return await _dbHelper.deleteNodesByLabelId(labelID);
}

Future<void> deleteEdgeByNodes(int id) async {
  await _dbHelper.deleteMindMapEdgeByNodes(id);
}