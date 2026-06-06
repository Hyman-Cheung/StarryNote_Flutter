//======================================================================================================
// node_rendering_utility.dart
//======================================================================================================

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../database/manager/label_manager.dart';
import 'delete_node_edge_handler.dart';
import 'node_detail_handler.dart';
import '../Data_Model/node_and_edge.dart';

class NodeRenderingUtility {
  BuildContext context;
  List<MindMapNode> nodes; 
  List<MindMapEdge> edges; 
  int relationID;
  TransformationController transformationController;
  Function() reflectChanges;
  Function updateUI;
  Function(List<MindMapNode>, List<MindMapEdge>) passItemsToDelete;
  Function(MindMapNode) onbuildLinkButtonClicked;
  Function(MindMapNode) onNodeClickedForLinking;
  Function closeMindMapDisplayDialog;
  Function closeRelationListDialog;
  Function closeDrawerDialog;
  Function switchToPage;
  GlobalKey<State<StatefulWidget>> globalKey;

  NodeRenderingUtility(
    this.context,
    this.nodes,
    this.edges,
    this.relationID,
    this.transformationController,
    this.reflectChanges,
    this.updateUI,
    this.passItemsToDelete,
    this.onbuildLinkButtonClicked,
    this.onNodeClickedForLinking,
    this.closeMindMapDisplayDialog,
    this.closeRelationListDialog,
    this.closeDrawerDialog,
    this.switchToPage,
    this.globalKey,
  );

  Widget determineChildBaseOnNodeType(MindMapNode node) {
    double radius = calculateNodeRadius(node.title) * 2;
    if (node.notebookId != null) {
      return Container(
        width: radius,
        height: radius,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.indigo,
        shape: BoxShape.circle, 
        ),
        child: Text(
          node.title, 
          overflow: TextOverflow.ellipsis, 
          style: TextStyle(fontSize: 12, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    } else if (node.sectionId != null) {
      return ClipOval(
        child: Container(
          width: radius * 1.6,
          height: radius,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 80, 42, 185),
          ),
          child: Text(
            node.title, 
            overflow: TextOverflow.ellipsis, 
            style: TextStyle(fontSize: 12, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (node.pageId != null) {
      return Center(
        child: Container(
          width: radius * 1.5,
          height: radius,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 60, 130, 196),
            shape: BoxShape.rectangle, 
          ),
          child: Text(
            node.title, 
            overflow: TextOverflow.ellipsis, 
            style: TextStyle(fontSize: 12, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (node.labelId != null) {
      return Transform.rotate(
        angle: 3.14159 / 4, // Rotates by 45 degrees (π/4 radians)
        child: Container(
          width: radius * 1.2,
          height: radius * 1.2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 83, 83, 83),
            shape: BoxShape.rectangle, 
          ),
          child: Transform.rotate(
            angle: -3.14159 / 4, // Counteracts the container's rotation, leaving the text unrotated
            child: Text(
              node.title, 
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    throw Exception("Node type cannot be distinguished");
  }

  Widget renderNode(MindMapNode node, bool isEditing, bool isLinking) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isEditing) {
          if (!isLinking) {
            _showTextContextMenu(node);
          } else {
            onNodeClickedForLinking(node);
          }
        } else {
          _showNodeDetails(node);
        }
      },
      onPanUpdate: (details) {
        // Update the node's position while dragging
        if (isEditing) {
          final currentScenePosition = _transformGlobalToScene(details.globalPosition);
          final delta = currentScenePosition - node.position;

          // Update the node's position by adding the transformed delta
          node.position = Offset(
            node.position.dx + delta.dx,
            node.position.dy + delta.dy
          );
          debugPrint("Dragging nodes, $node");
          reflectChanges(); // Notify parent about changes made
        }
      },
      child: determineChildBaseOnNodeType(node),
    );
  }

  // Method to calculate the node radius based on title length
  double calculateNodeRadius(String title) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: title, style: TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: double.infinity); // Layout text for full width
    double width = textPainter.width;
    double height = textPainter.height;

    // Ensure the radius is large enough to fit the title
    double maxDimension = width > height ? width : height;
    double radius = maxDimension / 2 + 10; // Add padding around the text
    return radius;
  }

   // Method to show the dialog when a node is clicked
  void _showNodeDetails(MindMapNode node) async {
    String location = await NodeDetailHandler.getLocation(node);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.all(16),
            content: Padding(
              padding: EdgeInsets.all(23),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 350,
                    maxHeight: 400,
                    minWidth: 350,
                    minHeight: 400
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Button to close the dialog
                      Container(
                        // The border below the title:
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                        ),
                        alignment: Alignment.topLeft,
                        child: TextButton(
                          child: Text("Edit",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          onPressed: () {
                            Navigator.pop(
                                context); // Close the current node detail dialog
                            // Show the options for editing title or description
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  contentPadding: EdgeInsets.all(16),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Option to edit title
                                      TextButton(
                                        child: Text("Edit Title",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo)),
                                        onPressed: () async {
                                          // Invoke edit title function
                                          Navigator.pop(
                                              context); // Close the current dialog
                                          await NodeDetailHandler
                                              .editNodeDetail(context, node,
                                                  true, updateUI);
                                        },
                                      ),
                                      // Option to edit description
                                      TextButton(
                                        child: Text("Edit Description",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo)),
                                        onPressed: () async {
                                          // Invoke edit description function
                                          Navigator.pop(
                                              context); // Close the current dialog
                                          await NodeDetailHandler
                                              .editNodeDetail(context, node,
                                                  false, updateUI);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30),
                            // Node title
                            Text(
                              'Node Name: ',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              node.title,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 60),
                            // Location
                            Text(
                              'Location: ',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              location,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 60),
                            // Description
                            Text(
                              'Description: ',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              node.description,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ))
                    ],
                  )),
            ));
      },
    );
  }

  void _showTextContextMenu( 
    MindMapNode node,
    ) {
    // Get the scale factor and offset from the transformationController
    // ignore: unused_local_variable
    final double scale = transformationController.value.getMaxScaleOnAxis();
    final Matrix4 matrix = transformationController.value;

    // Get the node position in scene coordinates
    final Offset scenePosition = node.position;

    // Convert the scene position to screen coordinates using the transformation matrix
    final transformedPosition = matrix.transform3(Vector3(scenePosition.dx, scenePosition.dy, 0));

    // The transformedPosition now gives us the node's position adjusted for any transformations
    final adjustedOffset = Offset(transformedPosition.x, transformedPosition.y);

    // Create a RelativeRect for the position of the context menu relative to the screen
    final relativeRect = RelativeRect.fromLTRB(
      adjustedOffset.dx, // The X position of the menu (node's position, adjusted for zoom and panning)
      adjustedOffset.dy, // The Y position of the menu (node's position, adjusted for zoom and panning)
      adjustedOffset.dx + 100, // Right offset, modify this value to control the width of the menu
      adjustedOffset.dy + 50, // Bottom offset, modify this value to control the height of the menu
    );
    showMenu(
      context: context,
      position: relativeRect,
      color: Colors.grey,
      items: [
        PopupMenuItem(
          onTap: () => DeleteNodeEdgeHandler.showDeleteConfirmationDialog(
            context,
            nodes,
            edges,
            node,
            relationID,
            () => updateUI,
            () => reflectChanges(),
            (nodesToDelete, edgesToDelete) =>
                passItemsToDelete(nodesToDelete, edgesToDelete),
          ),
          child: const Text('Delete Node'),
        ),
        PopupMenuItem(
          onTap: () {
            onbuildLinkButtonClicked(node);
            Fluttertoast.showToast(
              msg: "Please select the node you wish to link.",
              toastLength: Toast.LENGTH_LONG,
              timeInSecForIosWeb: 3,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }, 
          child: const Text('Link To'),
        ),
        if (node.labelId != null) 
          PopupMenuItem(
            onTap: () async { // switch to the page where the label belongs to
            // close all dialog
              Navigator.of(context).pop();
              closeRelationListDialog();
              closeDrawerDialog();

              // get label data for switching
              final labelData = await LabelManager.instance.getDataById(node.labelId!);
              final position = Offset(labelData!['position_x'], labelData['position_y']);
              switchToPage(labelData['pageId'], labelData['sectionId'], labelData['notebookId'], position);
            }, 
            child: const Text('Move to Label'),
          ),
      ],
    );
  }

  Offset _transformGlobalToScene(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Matrix4 transform = transformationController.value;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    final double translateX = transform.getTranslation().x;
    final double translateY = transform.getTranslation().y;
    final double scale = transform.getMaxScaleOnAxis();
    return Offset(
      (localPosition.dx - translateX) / scale,
      (localPosition.dy - translateY) / scale,
    );
  }
}


