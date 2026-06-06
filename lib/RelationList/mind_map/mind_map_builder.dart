//======================================================================================================
// mind_map_builder.dart
//======================================================================================================

/*
  Builds and manages the interactive mind map visualization
  Handles:
    - Rendering nodes and edges
    - Node/edge selection and manipulation
    - Adding/deleting/linking nodes
    - Zooming and panning
    - Change tracking and propagation to parent
*/

import 'package:flutter/material.dart';
import 'edge_rendering_utility.dart'; // Handles the visual rendering of nodes and edges
import 'node_adder/add_button_handler.dart'; // Manages logic for adding new nodes
import 'node_adder/select_item_interface.dart'; // Interface for node selection
import 'delete_node_edge_handler.dart'; // Handles deletion of nodes and edges
import 'edge_builder.dart'; // Constructs edges between nodes
import '../Data_Model/node_and_edge.dart'; // Data models for nodes and edges
import '../Data_Operation/db_ops.dart'; // Database operations
import 'link_node_with_edge.dart'; // Manages node linking functionality
import 'package:fluttertoast/fluttertoast.dart'; // For displaying toast messages
import 'node_rendering_utility.dart';
import 'package:defer_pointer/defer_pointer.dart';

// The builder class that will draw the mind map
class MindMapBuilder extends StatefulWidget {
  final int relationID; // Add relationID to fetch data
  final bool isEditing; // Accept the isEditing parameter
  final VoidCallback onChangesMade; // Callback to notify when changes are made
  // Callbacks for data changes:
  final ValueChanged<List<MindMapNode>> onNodesChanged; // Callback for nodes
  final ValueChanged<List<MindMapEdge>> onEdgesChanged; // Callback for edges
  final ValueChanged<List<MindMapNode>> onNodesAdded; // Callback for edges
  final ValueChanged<List<MindMapNode>> onNodesDeleted; // Callback for nodes
  final ValueChanged<List<MindMapEdge>> onEdgesDeleted; // Callback for edges
  final Function closeRelationListDialog;
  final Function closeDrawerDialog;
  final Function switchToPage;

  const MindMapBuilder({
    Key? key,
    required this.relationID,
    required this.isEditing,
    required this.onChangesMade,
    required this.onNodesChanged,
    required this.onEdgesChanged,
    required this.onNodesAdded,
    required this.onNodesDeleted,
    required this.onEdgesDeleted,
    required this.closeRelationListDialog,
    required this.closeDrawerDialog,
    required this.switchToPage
  }) : super(key: key);

  @override
  _MindMapBuilderState createState() => _MindMapBuilderState();
}

class _MindMapBuilderState extends State<MindMapBuilder> {
  List<MindMapNode> nodes = []; // All nodes in current view
  List<MindMapEdge> edges = []; // All edges/connections between nodes
  bool isLoading = true; // Loading state flag

  // Store the position of the add button
  Offset? _addButtonPosition; // Position for the "+" add node button
  // Handles zoom/pan transformations
  TransformationController _transformationController =
      TransformationController();

  // Flag to indicate if we are in linking mode
  bool isLinkingMode = false; // Whether user is currently linking nodes
  MindMapNode? nodeToLink; // The node to link to
  String promptText = ""; // Text to show when in linking mode

  // Node dragging
  MindMapNode? draggingNode; // This will store the node that is being dragged
  Offset? initialPosition; // Store the initial position when dragging starts

  late NodeRenderingUtility nodeDrawingTool;
  final _interactiveViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchRelations(); // Load initial data when widget initializes
  }

  // Fetch data using the provided relation
  Future<void> _fetchRelations() async {
    try {
      // Try fetching nodes and edges
      nodes = await readAllMindMapNodesbyRelation(widget.relationID);
      edges = await EdgeBuilder.buildEdge(nodes, widget.relationID);
      setState(() {
        isLoading = false; // Update loading state once data is fetched
        nodeDrawingTool = NodeRenderingUtility(
          context, 
          nodes, 
          edges, 
          widget.relationID, 
          _transformationController, 
          reflectChanges, 
          () => setState(() {}), 
          passItemsToDelete, 
          onbuildLinkButtonClicked, 
          onNodeClickForLinking,
          () => Navigator.of(context).pop(),
          widget.closeRelationListDialog,
          widget.closeDrawerDialog,
          widget.switchToPage,
          _interactiveViewerKey,
        );
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Hide the loading spinner if an error occurs
      });
      // Show a toast message for the error
      Fluttertoast.showToast(
        msg: "Failed to load mind map data. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // Log the error to the console (useful for debugging)
      debugPrint("Error while fetching relations: $e");
    }
  }

  // Notifies parent widget about changes in the mind map structure
  void reflectChanges() {
    widget.onChangesMade(); // General change notification
    widget.onNodesChanged(nodes); // Updated nodes list
    widget.onEdgesChanged(edges); // Updated edges list
  }

  // Propagates deletion information to parent widget
  void passItemsToDelete(
      List<MindMapNode> nodesToDelete, List<MindMapEdge> edgesToDelete) {
    widget.onNodesDeleted(nodesToDelete);
    widget.onEdgesDeleted(edgesToDelete);
  }

  // Handle the node click for linking
  void onNodeClickForLinking(MindMapNode clickedNode) {
    try {
      if (isLinkingMode && clickedNode != nodeToLink) {
        debugPrint("Waiting users' confirmation.");
        // Show confirmation dialog for the link
        LinkNodeWithEdgeHandler.showLinkConfirmationDialog(
          context,
          nodeToLink!, // Source node
          clickedNode, // Target node
          widget.relationID,
          edges,
          () {resetLinkingState();}, // Cleanup callback
          () {reflectChanges();} // Success callback
        );
      } else if (clickedNode == nodeToLink) {
        Fluttertoast.showToast(
          msg: "You cannot link a node itself.",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0
        );
        resetLinkingState(); // Reset the linking state when linking to itself
      }
      else if (LinkNodeWithEdgeHandler.isNodeConnected(edges, clickedNode, nodeToLink)) {
        Fluttertoast.showToast(
          msg: "These nodes are already connected to each other. Choose others.",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    } catch (e) {
      // Handle any errors during node linking
      Fluttertoast.showToast(
        msg: "Error linking nodes. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print("Error during node linking: $e"); // Log the error
      resetLinkingState(); // Reset the linking state to avoid unexpected behavior
    }
  }

  // Method to reset the linking state
  void resetLinkingState() {
    setState(() {
      isLinkingMode = false; // Turn off the linking mode
      nodeToLink = null; // Clear the node to link
      promptText = ""; // Clear the prompt text
    });
  }

  // Helper function for building the delete button for edges
  Widget _buildDeleteButtonForEdge() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        DeleteNodeEdgeHandler.showDeleteConfirmationDialog(
          context,
          nodes,
          edges,
          DeleteNodeEdgeHandler.selectedEdgeForDelete!,
          widget.relationID,
          () => setState(() {}),
          () => reflectChanges(),
          (nodesToDelete, edgesToDelete) =>
              passItemsToDelete(nodesToDelete, edgesToDelete),
        );
      },
      child: Container(
        width: 100,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Delete Edge", 
          overflow: TextOverflow.ellipsis, 
          style: TextStyle(fontSize: 12, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
      
  }

  // Helper function for building the link button
  void onbuildLinkButtonClicked(MindMapNode selectedNodeToLink) {
    setState(() {
      isLinkingMode = true;
      nodeToLink = selectedNodeToLink;
      // promptText = "Please select which node to link to.";
    });
  }

  // Helper function to build the add button
  Widget _buildAddButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        try {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddNodeDialog(
                relationID: widget.relationID,
                position: _addButtonPosition!,
                currentNodeList: nodes,
                onNodeAdded: (nodesToAdd) {
                  setState(() {});
                  widget.onNodesAdded(nodesToAdd);
                },
                onChangesMade: reflectChanges,
              );
            },
          );
        } catch (e) {
          // Show error message if adding node fails
          Fluttertoast.showToast(
            msg: "Error adding the node. Please try again.",
            toastLength: Toast.LENGTH_LONG,
            timeInSecForIosWeb: 3,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          print("Error while adding node: $e"); // Log the error
        } finally {
          _addButtonPosition = null;
        }
      },
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(160),
          color: Color.fromRGBO(53, 53, 51, 1),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
      ? Center(child: CircularProgressIndicator())
      : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            // Convert the tap position to the scene coordinates
            final scenePosition = _transformationController.toScene(details.localPosition);

            // Check if the tap is near a node or edge
            final isNearNode = AddButtonHandler.isTapNearNode(scenePosition, nodes);
            final isNearEdge = AddButtonHandler.isTapNearEdge(scenePosition, edges);
            // Check if the tap is near an existing node
            try {
              // Handle add button positioning
              if (widget.isEditing && !isNearNode && !isNearEdge) {
                // Show the add button only if the tap is not near a node/edge and in edit mode
                setState(() {
                  // Adjust position considering the current zoom scale
                  _addButtonPosition = scenePosition;
                });
              } else {
                // Clear the add button position if the tap is near a node
                setState(() {
                  _addButtonPosition = null;
                });
              }
            } catch (e) {
              debugPrint("Error occured when rendering add node button: $e");
              setState(() {
                  _addButtonPosition = null;
              });
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1, // Minimum zoom level
            maxScale: 5.0, // Maximum zoom level
            panEnabled: draggingNode == null, // Only enable panning when not dragging a node
            scaleEnabled: true,
            constrained: false, // Allow the child to be any size
            boundaryMargin: EdgeInsets.all(double.infinity), // Allow panning beyond the edges
            child: DeferredPointerHandler(
              child: Stack(
                clipBehavior: Clip.none, // Allow widgets to render outside bounds
                children: [
                  // Main mind map visualization surface
                  SizedBox(
                    width: 10000,
                    height: 10000,
                    child: DeferPointer(
                      child: CustomPaint(
                        painter: EdgeRenderingUtility(edges, context, widget.isEditing, _transformationController),
                      ),
                    ),
                  ),
                  for (MindMapNode node in nodes) // render the nodes
                    Positioned(
                      left: node.position.dx - nodeDrawingTool.calculateNodeRadius(node.title) * 1.3, // render position (x-coordinate)
                      top: node.position.dy - nodeDrawingTool.calculateNodeRadius(node.title) * 1.2, // render position (y-coordinate)
                      child: DeferPointer(
                        child: nodeDrawingTool.renderNode(
                          node, // node to render
                          widget.isEditing, // edit mode status
                          isLinkingMode,
                        ),
                      ),
                    ),
                  // Edit-mode overlays
                  if (widget.isEditing)
                    ...[
                      if (DeleteNodeEdgeHandler.selectedEdgeForDelete != null)
                        Positioned(
                          left: (DeleteNodeEdgeHandler.selectedEdgeForDelete!.from.position.dx +
                                      DeleteNodeEdgeHandler.selectedEdgeForDelete!.to.position.dx) /
                                  2 + 40,
                          top: (DeleteNodeEdgeHandler.selectedEdgeForDelete!.from.position.dy +
                                      DeleteNodeEdgeHandler.selectedEdgeForDelete!.to.position.dy) /
                                  2 - 20,
                          child: DeferPointer(child: _buildDeleteButtonForEdge()),
                        ),
                      if (_addButtonPosition != null && !isLinkingMode) 
                        Positioned(
                          left: _addButtonPosition!.dx - 40, // button position (with adjustment)
                          top: _addButtonPosition!.dy - 40, // button position (with adjustment)
                          child: DeferPointer(child: _buildAddButton()), // construct the "+"" button
                        )
                    ],
                ],
              ),
            ),
          ),
      );
  }
}
