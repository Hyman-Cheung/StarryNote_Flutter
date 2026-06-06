//======================================================================================================
// add_node_handler.dart
//======================================================================================================

/*

*/

import 'package:flutter/material.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart'; // Import Notebook data model
import '../../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart'; // Import Section data model
import '../../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart'; // Import Page data model
import '../../../database/data/label_data.dart'; // Import Label model
import '../../Data_Model/node_and_edge.dart'; // Import MindMapNode and MindMapEdge

class AddNodeHandler {
  static List<MindMapNode> nodesToAdd = [];
  // Function to add a node based on the selected item (Notebook, Section, Page, Label)
  static Future<void> addNode(dynamic itemToAdd, Offset position, int relationID, List<MindMapNode> nodes, Function onNodeAdded, Function() onChangesMade) async {
    // Check the type of the selected item and create a new node accordingly
    MindMapNode newNode;
    if (itemToAdd is Notebook) {
      newNode = MindMapNode(
        id: nodes.last.id + 1, 
        relationID: relationID,
        title: itemToAdd.title,
        description: '',
        position: position,
        notebookId: itemToAdd.notebook_id,
      );
    } else if (itemToAdd is Section) {
      newNode = MindMapNode(
        id: nodes.last.id + 1,
        relationID: relationID,
        title: itemToAdd.title,
        description: '',
        position: position,
        sectionId: itemToAdd.sectionId,
      );
    } else if (itemToAdd is NotePage) {
      newNode = MindMapNode(
        id: nodes.last.id + 1, 
        relationID: relationID,
        title: itemToAdd.title,
        description: '',
        position: position,
        pageId: itemToAdd.pageId,
      );
    } else if (itemToAdd is LabelData) {
      newNode = MindMapNode(
        id: nodes.last.id + 1,
        relationID: relationID,
        title: itemToAdd.name,
        description: '',
        position: position,
        labelId: itemToAdd.id,
      );
    } else {
      // Handle unknown type
      return;
    }

    nodes.add(newNode);
    nodesToAdd.add(newNode);

    onChangesMade();
    onNodeAdded(nodesToAdd);
  }
}