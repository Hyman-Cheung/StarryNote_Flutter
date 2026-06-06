//======================================================================================================
// drawer_framework.dart
//======================================================================================================

/*
  Create a custom drawer that implements the hamburger button.
  List out all the notebooks, sections and pages.
  Provide buttons to add, rename and delete items.
  Also provide buttons to access the relation list, question list, etc.
*/

import 'package:flutter/material.dart';
import '../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';
import '../Note_Hierarchy_Structure/Data_Operation/item_renamer.dart';

import './drawer_component/topbar_builder.dart'; // Import the top bar builder

import 'Button_functions_implementation/add_button.dart';
import 'Button_functions_implementation/add_relation_button/add_relation_button.dart';
import 'Button_functions_implementation/delete_button.dart';

import '../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';

/*** Drawer Menu structure ***/
// This class represents a customizable drawer menu for notebooks and sections.
class CustomDrawer extends StatefulWidget {
  final Function(String, String, int, [Offset])
      onPageSelected; // Callback to switch pages
  final Function(String, String) onCreatePage; // Callback to create a new page

  const CustomDrawer({
    required this.onPageSelected,
    required this.onCreatePage,
    super.key,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool isEditMode = false; // Indicates whether the drawer is in edit mode
  bool isRenaming = false; // Track if we're renaming an item
  dynamic
      itemBeingRenamed; // Track the actual item (Notebook, Section, or Page) being renamed

  Notebook? selectedNotebook;
  Section? selectedSection;
  NotePage? selectedPage;

  // A list of user data
  List<Notebook> notebooks = [];
  List<Section> sections = [];
  List<NotePage> pages = [];

  // Sets to keep track of selected items in edit mode
  List<dynamic> editItems = [];

  TextEditingController _editController =
      TextEditingController(); // Controller for the text field

  void initState() {
    super.initState();
    _loadNotebookList();
  }

  // Function to refresh the UI after deletion
  void _refreshUIAfterDel() {
    setState(() {
      _loadNotebookList();
      if (selectedNotebook != null && selectedSection != null) {
        _loadSectionList(selectedNotebook!.notebook_id);
        _loadPageList(selectedSection!.sectionId);
      } else if (selectedNotebook != null) {
        _loadSectionList(selectedNotebook!.notebook_id);
      } else {
        sections.clear();
        pages.clear();
      }
    });
  }

  // Fetch notebook list
  void _loadNotebookList() async {
    notebooks = await fetchNotebooks();
    setState(() {});
  }

  // Fetch sections for the selected notebook
  void _loadSectionList(int id) async {
    sections = await fetchSectionsByNotebookId(id);
    setState(() {});
  }

  // Fetch pages for the selected section
  void _loadPageList(String id) async {
    pages = await fetchPagesBySectionId(id);
    setState(() {});
  }

  // Toggles the edit mode and clears selections when exiting edit mode
  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
      if (!isEditMode) {
        editItems.clear();
      }
    });
  }

  // main function that builds the user interface of the drawer
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background colour
      ),
      child: Column(
        children: [
          buildTopBar(
              context,
              isEditMode,
              selectedNotebook?.notebook_id ?? 0,
              toggleEditMode,
              () => Navigator.pop(context),
              widget.onPageSelected), // Builds the top bar (contains buttons)
          Expanded(
            child: Row(
              children: [
                _buildNotebookColumn(), // Builds the notebook column
                // If a notebook is selected, show sections
                if (selectedNotebook != null) _buildSectionColumn(),
                // If a section is selected, show pages
                if (selectedSection != null) _buildPageColumn(),
              ],
            ),
          ),
          if (isEditMode)
            _buildEditButtons(), // Shows edit buttons only in edit mode
        ],
      ),
    );
  }

  // Builds the notebook column with its own header
  Widget _buildNotebookColumn() {
    return _buildColumn(
      title: "Notebooks", // Header title for the notebook column
      items: notebooks,
      selectedItems: editItems,
      onSelect: (index) {
        setState(() {
          selectedNotebook = notebooks[index];
          selectedSection = null;
          selectedPage = null;
          _loadSectionList(selectedNotebook!.notebook_id);
        });
      },
      onEditSelect: (index) {
        setState(() {
          if (editItems.contains(notebooks[index])) {
            editItems.remove(notebooks[index]);
          } else {
            editItems.add(notebooks[index]);
          }
        });
      },
      addButton: _buildNotebookAddButton(),
      isFirstColumn: true, // First column
      isLastColumn: selectedNotebook == null, // Last column condition
    );
  }

  // Builds the section column with its own header
  Widget _buildSectionColumn() {
    return _buildColumn(
      title: selectedNotebook != null
          ? "Sections in ${selectedNotebook!.title}"
          : "Sections", // Header title for the section column
      items: sections,
      selectedItems: editItems,
      onSelect: (index) {
        setState(() {
          selectedSection = sections[index];
          selectedPage = null;
          _loadPageList(selectedSection!.sectionId);
        });
      },
      onEditSelect: (index) {
        setState(() {
          if (editItems.contains(sections[index])) {
            editItems.remove(sections[index]);
          } else {
            editItems.add(sections[index]);
          }
        });
      },
      addButton: _buildSectionAddButton(),
      isFirstColumn: false, // Not the first column
      isLastColumn: selectedSection == null, // Last column condition
    );
  }

  // Builds the page column with its own header
  Widget _buildPageColumn() {
    return _buildColumn(
      title: selectedSection != null
          ? "Pages in ${selectedSection!.title}"
          : "Pages", // Header title for the page column
      items: pages,
      selectedItems: editItems,
      onSelect: (index) {
        setState(() {
          selectedPage = pages[index];
          if (!isEditMode) {
            widget.onPageSelected(
                selectedPage!.pageId,
                selectedSection!.sectionId,
                selectedNotebook!
                    .notebook_id); // Call the callback to switch pages
            Navigator.pop(context); // Close the drawer
          }
        });
      },
      onEditSelect: (index) {
        setState(() {
          if (editItems.contains(pages[index])) {
            editItems.remove(pages[index]);
          } else {
            editItems.add(pages[index]);
          }
        });
      },
      addButton: _buildPageAddButton(),
      isFirstColumn: false, // Not the first column
      isLastColumn: true, // Last column (no column after this)
    );
  }

  // Generic function to build a column for notebooks, sections, or pages
  Widget _buildColumn({
    required String title, // Header title for the column
    required List<dynamic> items,
    required List<dynamic> selectedItems,
    required Function(int) onSelect,
    required Function(int) onEditSelect,
    required Widget addButton,
    required bool isFirstColumn, // To track if it's the first column
    required bool isLastColumn, // To track if it's the last column
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: isLastColumn
                ? BorderSide.none
                : const BorderSide(
                    color: Colors.black,
                    width: 1), // Right border only between columns
          ), // Adds border
        ),
        child: Column(
          children: [
            // Header for the column
            Container(
              width: double.infinity, // Ensure full width of parent container
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Light grey background
                border: const Border(
                  top: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                ),
              ), // Bottom border
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            // Scrollable list of items
            Expanded(
              child: ListView(
                children: List.generate(items.length, (index) {
                  final isSelected = isEditMode
                      ? selectedItems.contains(items[index])
                      : (selectedNotebook == items[index] ||
                          selectedSection == items[index] ||
                          selectedPage == items[index]);

                  return ListTile(
                    leading: isEditMode
                        ? GestureDetector(
                            onTap: () => onEditSelect(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.indigo, width: 3),
                                color: Colors.transparent,
                              ),
                              child: selectedItems.contains(items[index])
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          )
                        : null,
                    title: isRenaming && itemBeingRenamed == items[index]
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                  // Inactive state
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  // Active state (when selected)
                                  borderSide: BorderSide(
                                      color: Colors.indigo, width: 2),
                                ),
                              ),
                              controller: _editController,
                              autofocus: true,
                              onSubmitted: (_) => _saveRename(),
                            ),
                          )
                        : Text(
                            items[index].toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.indigo : Colors.black,
                            ),
                          ),
                    onTap: () {
                      if (!isEditMode) {
                        onSelect(index);
                      }
                    },
                    selected: isSelected,
                  );
                }),
              ),
            ),
            if (!isEditMode) addButton, // Shows add button if not in edit mode
          ],
        ),
      ),
    );
  }

  // Generic function to create an add button
  Widget _buildAddButton(VoidCallback onPressed) {
    // Return a Container widget that provides styling and layout constraints
    return Container(
      // Add vertical margins to create space above and below the button
      margin: const EdgeInsets.symmetric(vertical: 10),
      // Decoration property for visual styling of the container
      decoration: BoxDecoration(
        shape: BoxShape
            .circle, // Make the container circular (will constrain its children)
        border: Border.all(
            color: Colors.black), // Add a border around the container
      ),
      child: IconButton(
        // The icon to display inside the button
        icon: const Icon(Icons.add),
        onPressed: onPressed, // Press handler
      ),
    );
  }

  Widget _buildNotebookAddButton() {
    return _buildAddButton(() async {
      await addNotebook(context); // Add new notebook
      _loadNotebookList(); // Refresh notebook list

      // Add a short delay to ensure the item is added to the list before renaming
      Future.delayed(const Duration(milliseconds: 100), () {
        // Ensure the last notebook is the newly added one and start renaming
        if (notebooks.isNotEmpty) {
          setState(() {
            isRenaming = true; // Set renaming mode to true
            itemBeingRenamed =
                notebooks.last; // Start renaming the newly added notebook
            _editController.text =
                itemBeingRenamed!.title; // Set default text for renaming
          });
        }
      });
    });
  }

  Widget _buildSectionAddButton() {
    return _buildAddButton(() async {
      if (selectedNotebook != null) {
        await addSection(
            context, selectedNotebook!.notebook_id); // Add new section
        _loadSectionList(selectedNotebook!.notebook_id); // Refresh section list
      }

      // Add a short delay to ensure the item is added to the list before renaming
      Future.delayed(const Duration(milliseconds: 100), () {
        // Ensure the last section is the newly added one and start renaming
        if (sections.isNotEmpty) {
          setState(() {
            isRenaming = true; // Set renaming mode to true
            itemBeingRenamed =
                sections.last; // Start renaming the newly added section
            _editController.text =
                itemBeingRenamed!.title; // Set default text for renaming
          });
        }
      });
    });
  }

  Widget _buildPageAddButton() {
    return _buildAddButton(() async {
      if (selectedSection != null) {
        await widget.onCreatePage(
            selectedSection!.sectionId, 'New Page'); // Use the callback
        _loadPageList(selectedSection!.sectionId); // Refresh page list
      }

      // Add a short delay to ensure the item is added to the list before renaming
      Future.delayed(Duration(milliseconds: 100), () {
        // Ensure the last page is the newly added one and start renaming
        if (pages.isNotEmpty) {
          setState(() {
            isRenaming = true; // Set renaming mode to true
            itemBeingRenamed =
                pages.last; // Start renaming the newly added page
            _editController.text =
                itemBeingRenamed!.title; // Set default text for renaming
          });
        }
      });
    });
  }

  // Builds the edit buttons (delete, edit, add relation)
  Widget _buildEditButtons() {
    // Check if any items are selected across notebooks/sections/pages
    bool hasSelection = editItems.isNotEmpty;

    if (!hasSelection)
      return const SizedBox.shrink(); // Hide buttons when nothing is selected

    return Row(
      // Display action buttons in centered row
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Delete button - removes selected items and refreshes UI (pending implementation)
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Delete selected items and refresh UI
            DeleteButton.showConfirmationDialog(
              context,
              editItems,
              _refreshUIAfterDel,
            );
          },
        ),

        // Rename button - Always visible but only enabled when one item is selected
        IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Ensure something is selected and start renaming
              print(editItems.toString());
              if (editItems.isNotEmpty) {
                if (editItems.first is Notebook) {
                  _startRenaming(editItems
                      .first); // Only rename the first notebook selected
                } else if (editItems.first is Section) {
                  _startRenaming(editItems
                      .first); // Only rename the first section selected
                } else if (editItems.first is NotePage) {
                  _startRenaming(
                      editItems.first); // Only rename the first page selected
                }
              }
            }),

        IconButton(
          icon: Icon(Icons.shape_line_outlined),
          onPressed: () {
            // Invoke the function to show the add relation prompt
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AddRelationDialog(
                    notebooks: notebooks, selectedIteminMenu: editItems.first);
              },
            ); // This triggers the prompt to select which item to relate with
          },
        ),
      ],
    );
  }

  // Start renaming an item (Notebook, Section, Page)
  void _startRenaming(dynamic item) {
    setState(() {
      isRenaming = true;
      itemBeingRenamed = item; // Track the item being renamed
      _editController.text =
          item.title; // Set the initial value to the current title
    });
  }

  // Save the new name and update the corresponding list or database
  void _saveRename() async {
    setState(() {
      itemBeingRenamed!.title =
          _editController.text; // Update renaming item title
      if (itemBeingRenamed is Notebook) {
        // Call rename function to update the notebook in the database
        renameNotebook(itemBeingRenamed!.notebook_id, _editController.text);
      } else if (itemBeingRenamed is Section) {
        // Call rename function to update the section in the database
        renameSection(itemBeingRenamed!.sectionId, _editController.text);
      } else if (itemBeingRenamed is NotePage) {
        // Call rename function to update the page in the database
        renamePage(itemBeingRenamed!.pageId, _editController.text);
      }
      isRenaming = false; // Exit rename mode
      itemBeingRenamed = null; // Clear the tracked item
    });
  }
}
/*** End of Drawer Menu structure ***/
