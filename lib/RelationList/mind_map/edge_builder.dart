//======================================================================================================
// edge_builder.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import '../Data_Model/node_and_edge.dart';
import '../Data_Operation/db_ops.dart';

class EdgeBuilder {
  static Future<List<MindMapEdge>> buildEdge(List<MindMapNode> nodeList, int relationID) async {
    List<MindMapEdge> edgeList = [];

    final List<Map<String, dynamic>> edgeMaps = await readAllMindMapEdgesbyRelation(relationID);

    for (var edgeMap in edgeMaps) {
      // Fetch the fromNode and toNode by their IDs
      int fromId = edgeMap['fromID'];
      int toId = edgeMap['toID'];

      // Retrieve the corresponding nodes from the database
      MindMapNode fromNode = _nodeBinarySearch(nodeList, fromId);
      MindMapNode toNode = _nodeBinarySearch(nodeList, toId);

      // Create the edge object
      MindMapEdge edge = MindMapEdge(
        id: edgeMap['id'],
        relationID: edgeMap['relationID'],
        from: fromNode,
        to: toNode,
      );
      edgeList.add(edge);
    }

    return edgeList;
  }

  static MindMapNode _nodeBinarySearch(List<MindMapNode> nodeList, int nodeId) {
    int low = 0;
    int high = nodeList.length - 1;
    
    while (low <= high) {
      int mid = low + (high - low) ~/ 2;

      // Check if nodeId is present at mid
      if (nodeList[mid].id == nodeId) {
        return nodeList[mid];
      }

      // If nodeId greater, ignore left half
      if (nodeList[mid].id < nodeId) {
          low = mid + 1;
      }
      // If nodeId is smaller, ignore right half
      else {
        high = mid - 1;
      }
    }
    // return dummy if not found.
    return MindMapNode(id: -1, relationID: -1, title: 'Error', description: '', position: Offset(0,0));
  }
}