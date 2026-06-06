//======================================================================================================
// node_detail_handler.dart
//======================================================================================================

/*

*/

import 'package:notes_taking_app/widgets/custom_text_field.dart';

import '../Data_Model/node_and_edge.dart';
import '../../database/data/label_data.dart';
import '../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';

import '../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';
import '../../Note_Hierarchy_Structure/Data_Operation/item_renamer.dart';
import '../Data_Operation/db_ops.dart';
import 'package:flutter/material.dart';
import '../../database/manager/label_manager.dart';

class NodeDetailHandler {
  static Future<String> getLocation(MindMapNode node) async {
    if (node.notebookId != null) {
      Notebook notebookItem = await fetchNotebookById(node.notebookId ?? 0);
      return notebookItem.returnPosition();
    } else if (node.sectionId != null) {
      Section sectionItem = await fetchSectionById(node.sectionId ?? '');
      return await sectionItem.returnPosition();
    } else if (node.pageId != null) {
      NotePage pageItem = await fetchPageById(node.pageId ?? '');
      return await pageItem.returnPosition();
    } else if (node.labelId != null) {
      final map = await LabelManager.instance.getDataById(node.labelId!);
      LabelData labelItem = LabelData(
          id: map!['id'],
          labelType:
              LabelType.values.firstWhere((e) => e.name == map['labelType']),
          name: map['name'],
          description: map['description'],
          priority: int.parse(map['priority'].toString()),
          position: Offset(map['position_x'], map['position_y']),
          createAt: map['createAt'],
          lastEditTime: map['lastEditTime'],
          pageId: map['pageId'],
          sectionId: map['sectionId'],
          notebookId: map['notebookId']);
      return await labelItem.returnPosition();
    } else {
      throw Exception('Unable to get location');
    }
  }

  static Future<void> editNodeDetail(BuildContext context, MindMapNode node,
      bool isTitle, Function updateUI) async {
    TextEditingController controller = TextEditingController();

    // Set the controller text based on whether we're editing the title or description
    if (isTitle) {
      controller.text = node.title;
    } else {
      controller.text = node.description;
    }

    // Show the dialog for editing
    await showDialog(
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
                    maxHeight: isTitle ? 180 : 400,
                    minWidth: 350,
                    minHeight: isTitle ? 180 : 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          isTitle ? 'Edit Title' : 'Edit Description',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Divider(
                          // ← Full-width line
                          color: Colors.black,
                          thickness: 3,
                          height: 12, // Space below the text
                        ),
                      ],
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                            child: ClipRRect(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          CustomTextField(
                              controller: controller,
                              labelText: isTitle ? 'Title' : 'Description',
                              maxLines: isTitle ? 1 : 10,
                              readOnly: false,
                              icon: Icon(null),
                              onTap: () {}),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () async {
                              // Update the node title or description depending on the field being edited
                              if (isTitle) {
                                node.title = controller.text;
                                if (node.notebookId != null) {
                                  await renameNotebook(
                                      node.notebookId!, node.title);
                                } else if (node.sectionId != null) {
                                  await renameSection(
                                      node.sectionId!, node.title);
                                } else if (node.pageId != null) {
                                  await renamePage(node.pageId!, node.title);
                                } else if (node.labelId != null) {
                                  await renameLabel(node.labelId!, node.title);
                                }
                                updateUI();
                              } else {
                                node.description = controller.text;
                                await updateMindMapNode(
                                    node); // Update in the database
                              }

                              // Close the current edit dialog
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Save',
                              style: TextStyle(color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    )))
                  ],
                ),
              ),
            ));
      },
    );
  }
}
