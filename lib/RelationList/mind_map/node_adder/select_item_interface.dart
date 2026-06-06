//======================================================================================================
// select_item_interface.dart
//======================================================================================================

/*
  To provide implementation for the add_relation button.
  add_relation button is used to add relationship between notebook/section/page.
*/

import 'package:flutter/material.dart';
import '../../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart'; // Import db_ops
import 'add_node_handler.dart';
import '../../../database/manager/label_manager.dart';
import '../../../HamburgerButton/Button_functions_implementation/add_relation_button/column_divider_builder.dart';

import '../../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';
import '../../../database/data/label_data.dart';
import '../../Data_Model/node_and_edge.dart';

class AddNodeDialog extends StatefulWidget {
  final int relationID;
  final Offset position;
  final List<MindMapNode> currentNodeList;
  final Function onNodeAdded; // Add the callback as a parameter
  final Function() onChangesMade;

  AddNodeDialog({required this.relationID, required this.position, required this.currentNodeList, required this.onNodeAdded, required this.onChangesMade});
  @override
  _AddNodeDialogState createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends State<AddNodeDialog> {
  Notebook? selectedNotebook;
  Section? selectedSection;
  NotePage? selectedPage;
  LabelData? selectedLabel;
  List<Notebook> notebooks = [];
  List<Section> sectionsForSelectedNotebook = [];
  List<NotePage> pagesForSelectedSection = [];
  List<LabelData> labelsForSelectedPage = [];

  @override
  void initState() {
    super.initState();
    _fetchAllNotebooks();
  }

  // Fetch notebook list
  void _fetchAllNotebooks() async {
    notebooks = await fetchNotebooks();
    setState(() {});
  }

  // Fetch sections for selected notebook
  Future<void> loadSectionsForNotebook(Notebook notebook) async {
    setState(() {
      selectedNotebook = notebook;
      selectedSection = null; // Reset section when notebook is selected
      selectedPage = null;
    });

    // Fetch sections for the selected notebook
    sectionsForSelectedNotebook = await fetchSectionsByNotebookId(notebook.notebook_id);
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
    print(page.title);
    // Fetch all labels for the selected page
    List<LabelData> temp = await LabelManager.instance.getLabelDataByPageId(page.pageId);
    
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
      backgroundColor: Colors.blueGrey[50], // Background color of the dialog
      title: Center(  // Ensure title is centered
        child: Text(
          "Select which item to refer to as",
          style: TextStyle(
            color: Colors.black, // Title text color
            fontSize: 18, // Title font size
            fontWeight: FontWeight.bold, // Title font weight
          ),
        ),
      ),
      content: SingleChildScrollView( // Make the content scrollable if it overflows
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align the columns from left
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildVerticalColumn(context, notebooks, "Notebooks", loadSectionsForNotebook, selectedNotebook),
            buildVerticalDivider(context),
            buildVerticalColumn(context, sectionsForSelectedNotebook, "Sections", loadPagesForSection, selectedSection),
            buildVerticalDivider(context),
            buildVerticalColumn(context, pagesForSelectedSection, "Pages", loadLabelsForPage, selectedPage),
            buildVerticalDivider(context),
            buildVerticalColumn(context, labelsForSelectedPage, "Labels", labelSelection, selectedLabel), // Labels don't have a selection
          ],
        ),
      ),
      actions: [
        // Add Cancel and Add Relation buttons at the bottom-right
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog when Cancel is pressed
              },
              child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                dynamic itemToPass;
                if (selectedLabel != null) {
                  itemToPass = selectedLabel;
                } 
                else if (selectedPage != null) {
                  itemToPass = selectedPage;
                } 
                else if (selectedSection != null) {
                  itemToPass = selectedSection;
                } 
                else if (selectedNotebook != null) {
                  itemToPass = selectedNotebook;
                }
                AddNodeHandler.addNode(itemToPass, widget.position, widget.relationID, widget.currentNodeList, widget.onNodeAdded, widget.onChangesMade);
                Navigator.pop(context); // Close the dialog after adding relation
              },
              child: Text("Add Node", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}