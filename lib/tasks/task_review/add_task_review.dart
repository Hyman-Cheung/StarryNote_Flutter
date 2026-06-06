import 'package:flutter/material.dart';
import 'package:notes_taking_app/database/manager/label_manager.dart';
import 'package:notes_taking_app/database/manager/task_review_manager.dart';
import '../../../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../../../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';
import '../../../database/data/label_data.dart';
import '../../HamburgerButton/Button_functions_implementation/add_relation_button/column_divider_builder.dart';

class AddTaskReview extends StatefulWidget {
  final List<Notebook> notebooks;
  final int taskId; // Changed from selectedIteminMenu to taskId

  AddTaskReview({
    required this.notebooks,
    required this.taskId, // Now accepts taskId directly
  });

  @override
  AddTaskReviewState createState() => AddTaskReviewState();
}

class AddTaskReviewState extends State<AddTaskReview> {
  Notebook? selectedNotebook;
  Section? selectedSection;
  NotePage? selectedPage;
  List<LabelData> selectedLabels = []; // Changed to support multiple selections
  List<Section> sectionsForSelectedNotebook = [];
  List<NotePage> pagesForSelectedSection = [];
  List<LabelData> labelsForSelectedPage = [];

  // Fetch sections for selected notebook
  Future<void> loadSectionsForNotebook(Notebook notebook) async {
    setState(() {
      selectedNotebook = notebook;
      selectedSection = null;
      selectedPage = null;
      selectedLabels.clear();
    });

    sectionsForSelectedNotebook =
        await fetchSectionsByNotebookId(notebook.notebook_id);
    pagesForSelectedSection = [];
    labelsForSelectedPage = [];
    setState(() {});
  }

  // Fetch pages for selected section
  Future<void> loadPagesForSection(Section section) async {
    setState(() {
      selectedSection = section;
      selectedPage = null;
      selectedLabels.clear();
    });

    pagesForSelectedSection = await fetchPagesBySectionId(section.sectionId);
    labelsForSelectedPage = [];
    setState(() {});
  }

  // Fetch labels for selected page
  Future<void> loadLabelsForPage(NotePage page) async {
    print('Loading labels for page: ${page.pageId}');

    setState(() {
      selectedPage = page;
      selectedLabels.clear();
      labelsForSelectedPage = [];
    });

    try {
      List<LabelData> temp =
          await LabelManager.instance.getLabelDataByPageId(page.pageId);
      print('Fetched ${temp.length} labels for page ${page.pageId}');

      // For debugging, show all labels regardless of type
      List<LabelData> filtered = temp;

      // Once working, you can re-enable the filter:
      // List<LabelData> filtered = temp.where((label) => label.labelType == LabelType.review).toList();

      setState(() {
        // Get only review labels:
        labelsForSelectedPage = getReviewLabels(filtered);
        ;
      });

      if (filtered.isEmpty) {
        print('No labels found for this page');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No labels found for this page'),
          ),
        );
      }
    } catch (e) {
      print('Error loading labels: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading labels: $e')),
      );
    }
  }

  // Toggle label selection
  void toggleLabelSelection(LabelData label) {
    setState(() {
      if (selectedLabels.contains(label)) {
        selectedLabels.remove(label);
      } else {
        selectedLabels.add(label);
      }
    });
  }

  // Add selected labels as task reviews
  Future<void> addTaskReviews() async {
    if (selectedLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one review label')),
      );
      return;
    }

    try {
      for (var label in selectedLabels) {
        // Check whether the label exiting in task review list:
        if (!await TaskReviewManager.instance.labelExist(label.id)) {
          await TaskReviewManager.instance.insert(widget.taskId, label.id);
        }
      }

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task reviews: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          "Add Task Review Item",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Padding(
        padding: EdgeInsets.all(13),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 1000, maxHeight: 600, minWidth: 1000, minHeight: 600),
            child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.black, width: 3),
                      bottom: BorderSide(color: Colors.black, width: 3))),
              child: SingleChildScrollView(
                  child: ClipRRect(
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
                    buildVerticalColumn(context, pagesForSelectedSection,
                        "Pages", loadLabelsForPage, selectedPage),
                    buildVerticalDivider(context),
                    // Modified label column to support multiple selections
                    Container(
                      width: 320,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              "Labels",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: labelsForSelectedPage.length,
                              itemBuilder: (context, index) {
                                final label = labelsForSelectedPage[index];
                                final isSelected =
                                    selectedLabels.contains(label);
                                return CheckboxListTile(
                                  title: Text(label.name),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    toggleLabelSelection(label);
                                  },
                                  activeColor: Colors.indigo,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )),
            )),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            TextButton(
              onPressed: addTaskReviews,
              child: Text("Add",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
          ],
        ),
      ],
    );
  }

  // Get review Labels:
  List<LabelData> getReviewLabels(List<LabelData> labels) {
    List<LabelData> newLabels = [];
    for (var label in labels) {
      if (label.labelType == LabelType.review) {
        newLabels.add(label);
      }
    }
    return newLabels;
  }
}
