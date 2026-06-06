//======================================================================================================
// add_relation_button.dart
//======================================================================================================

/*
  To provide implementation for the add_relation button.
  add_relation button is used to add relationship between notebook/section/page.
*/

import 'package:flutter/material.dart';
import 'package:notes_taking_app/database/manager/label_manager.dart';
import '../../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart'; // Import db_ops
import '../../../RelationList/Data_Operation/db_ops.dart';
import 'column_divider_builder.dart';

import '../../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';
import '../../../database/data/label_data.dart';
import '../../../RelationList/Data_Model/node_and_edge.dart';

class AddRelationDialog extends StatefulWidget {
  final List<Notebook> notebooks;
  final dynamic selectedIteminMenu;

  AddRelationDialog({
    required this.notebooks,
    required this.selectedIteminMenu,
  });

  @override
  _AddRelationDialogState createState() => _AddRelationDialogState();
}

class _AddRelationDialogState extends State<AddRelationDialog> {
  Notebook? selectedNotebook;
  Section? selectedSection;
  NotePage? selectedPage;
  LabelData? selectedLabel;
  List<Section> sectionsForSelectedNotebook = [];
  List<NotePage> pagesForSelectedSection = [];
  List<LabelData> labelsForSelectedPage = [];
  TextEditingController _relationNameController =
      TextEditingController(text: "New Relation");

  // Fetch sections for selected notebook
  Future<void> loadSectionsForNotebook(Notebook notebook) async {
    setState(() {
      selectedNotebook = notebook;
      selectedSection = null; // Reset section when notebook is selected
      selectedPage = null;
    });

    // Fetch sections for the selected notebook
    sectionsForSelectedNotebook =
        await fetchSectionsByNotebookId(notebook.notebook_id);
    pagesForSelectedSection = [];
    labelsForSelectedPage = [];
    setState(() {}); // Update UI to display sections
  }

  // Fetch pages for selected section
  Future<void> loadPagesForSection(Section section) async {
    setState(() {
      selectedSection = section;
    });

    // Fetch pages for the selected section
    pagesForSelectedSection = await fetchPagesBySectionId(section.sectionId);
    labelsForSelectedPage = [];
    setState(() {}); // Update UI to display pages
  }

  // Fetch pages for selected section
  Future<void> loadLabelsForPage(NotePage page) async {
    setState(() {
      selectedPage = page;
    });

    // Fetch all labels for the selected page
    List<LabelData> temp =
        await LabelManager.instance.getLabelDataByPageId(page.pageId);

    // select only concept label
    for (LabelData label in temp) {
      if (label.labelType == LabelType.concept) {
        labelsForSelectedPage.add(label);
      }
    }

    setState(() {}); // Update UI to display pages
  }

  Future<void> labelSelection(LabelData label) async {
    setState(() {
      selectedLabel = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // Background color of the dialog
      title: Center(
        // Ensure title is centered
        child: Text(
          "Add Relation",
          style: TextStyle(
            color: Colors.black, // Title text color
            fontSize: 18, // Title font size
            fontWeight: FontWeight.bold, // Title font weight
          ),
        ),
      ),
      content: Padding(
        padding: EdgeInsets.all(13),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 800, maxHeight: 600, minWidth: 800, minHeight: 600),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 3),
                bottom: BorderSide(color: Colors.black, width: 3))),
            child: SingleChildScrollView(
              // Make the content scrollable if it overflows
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildVerticalColumn(context, widget.notebooks, "Notebooks",
                      loadSectionsForNotebook, selectedNotebook),
                  buildVerticalDivider(context),
                  buildVerticalColumn(context, sectionsForSelectedNotebook,
                      "Sections", loadPagesForSection, selectedSection),
                  buildVerticalDivider(context),
                  buildVerticalColumn(context, pagesForSelectedSection, "Pages",
                      loadLabelsForPage, selectedPage),
                  buildVerticalDivider(context),
                  buildVerticalColumn(
                      context,
                      labelsForSelectedPage,
                      "Labels",
                      labelSelection,
                      selectedLabel), // Labels don't have a selection
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Add Cancel and Add Relation buttons at the bottom-right
        Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Align buttons to the right
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Close the dialog when Cancel is pressed
              },
              child: Text("Cancel",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                dynamic itemToPass;
                if (selectedLabel != null) {
                  itemToPass = selectedLabel;
                } else if (selectedPage != null) {
                  itemToPass = selectedPage;
                } else if (selectedSection != null) {
                  itemToPass = selectedSection;
                } else if (selectedNotebook != null) {
                  itemToPass = selectedNotebook;
                }
                Navigator.pop(context);
                await promptForRelationName([
                  itemToPass,
                  widget.selectedIteminMenu
                ]); // Show prompt for user to enter relation name
              },
              child: Text("Add Relation",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to prompt user for relation name
  Future<void> promptForRelationName(List<dynamic> itemsSelected) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text('Enter Relation Name'),
          content: TextField(
            controller: _relationNameController,
            decoration:
                InputDecoration(hintText: "Enter a name for the relation"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without saving
              },
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                relationBuilder(
                    itemsSelected,
                    _relationNameController
                        .text); // Proceed with the selected name
              },
              child: Text("OK", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }

  // Function to create relationship
  void relationBuilder(List<dynamic> itemsSelected, String relationName) async {
    int relationID = await createRelation(
      title: relationName,
      createAt: DateTime.now(),
      lastEditTime: DateTime.now(),
    );

    List<MindMapNode> newNodes = [
      MindMapNode(
          id: 1,
          relationID: relationID,
          title: itemsSelected[0].toString(),
          description: '',
          position: Offset(200, 200)),
      MindMapNode(
          id: 2,
          relationID: relationID,
          title: itemsSelected[1].toString(),
          description: '',
          position: Offset(400, 400)),
    ];

    for (int itemNo = 0; itemNo < itemsSelected.length; itemNo++) {
      if (itemsSelected[itemNo] is Notebook) {
        newNodes[itemNo].notebookId = itemsSelected[itemNo].notebook_id;
      } else if (itemsSelected[itemNo] is Section) {
        newNodes[itemNo].sectionId = itemsSelected[itemNo].sectionId;
      } else if (itemsSelected[itemNo] is NotePage) {
        newNodes[itemNo].pageId = itemsSelected[itemNo].pageId;
      } else if (itemsSelected[itemNo] is LabelData) {
        newNodes[itemNo].labelId = itemsSelected[itemNo].id;
      }
    }

    int fromId = await createMindMapNode(newNodes[0]);
    int toId = await createMindMapNode(newNodes[1]);

    MindMapEdge writeEdge = MindMapEdge(
      id: 0,
      relationID: relationID,
      from: await readMindMapNodeById(fromId) ??
          MindMapNode(
              id: 0,
              relationID: -1,
              title: 'Unknown',
              description: '',
              position: Offset(0, 0)),
      to: await readMindMapNodeById(toId) ??
          MindMapNode(
              id: 0,
              relationID: -1,
              title: 'Unknown',
              description: '',
              position: Offset(0, 0)),
    );
    await createMindMapEdge(writeEdge);
  }
}
