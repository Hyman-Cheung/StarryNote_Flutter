import 'package:flutter/material.dart';
import 'package:notes_taking_app/database/data/label_data.dart';
import '../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';
import '../database/manager/label_manager.dart';
import '../function/string_function.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/custom_search_bar.dart';

// A class for displaying the label list:
class LabelList extends StatefulWidget {
  // Field:
  final LabelType labelType;
  final int notebookId;
  final Function(String, String, int, Offset) switchToPage;
  final Function closeDrawerDialog;
  // Constructor (to get the label type):
  LabelList(
      {required this.labelType,
      required this.notebookId,
      required this.switchToPage,
      required this.closeDrawerDialog});
  @override
  LabelListState createState() => LabelListState();
  // A function to show the pop-up window:
  void showPopup(BuildContext context) {
    showDialog(
      barrierDismissible: false, // Prevents dismissal when tapping outside
      context: context,
      builder: (BuildContext context) => LabelList(
        labelType: labelType,
        notebookId: notebookId,
        switchToPage: switchToPage,
        closeDrawerDialog: closeDrawerDialog,
      ),
    );
  }
}

// A class for developing the pop-up window and handling the data:
class LabelListState extends State<LabelList> {
  // Define the object of "Future<List<Map<String, dynamic>>>":
  late Future<List<Map<String, dynamic>>> futureLabelItems;
  // Initialize a list in "Map<String, dynamic>" type:
  late List<Map<String, dynamic>> labelItems = [];
  // Define a TextEditingController for the search bar:
  TextEditingController searchController = TextEditingController();
  // Initialize a list for filtered items:
  late List<Map<String, dynamic>> filteredItems = [];
  // Initialize the notebook name:
  late String notebookName = "";
  // Initialize state and is called when the state object is created:
  @override
  void initState() {
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();
    // Initialize the futureLabeltems, and get the data from the database:
    futureLabelItems = LabelManager.instance.getData();
    // Ensure the Future is completed before executing the function:
    // ** Because the 'futureLabelItems' is  Future (did not complet), so then() method can ensure the Future is completed
    futureLabelItems.then((value) {
      // Update the labelItems list and filteredItems list with the new data:
      setState(() {
        filteredItems = value; // A list for showing and filtering the items
        labelItems =
            value; // A backup list for geting the item agin when deleting the text from the search bar
        // Filter items according to their type:
        labelItems = _filterItemsType(labelItems, widget.labelType);
        filteredItems = _filterItemsType(filteredItems, widget.labelType);
        // Sorts the list according to the priority and datetime:
        filteredItems = _sort(filteredItems);
        labelItems = _sort(labelItems);
      });
    });
    // Get the noteboo by notebook id:
    fetchNotebookById(widget.notebookId).then((value) {
      setState(() {
        notebookName = value.title;
      });
    });
    // Add listener to search controller to update filtered items:
    searchController.addListener(_filterItems);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        // The background color of the window:
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        // Set the padding of the window:
        child: Padding(
          padding: EdgeInsets.all(23),
          child: ConstrainedBox(
            // Set the fixed size of the pop-up window:
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: 650,
            ),
            child: Column(
              children: [
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
                  // The main content of the window:
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Space:
                      SizedBox(
                        width: 30,
                      ),
                      // The title of the pop-up window:
                      Text(
                        '${StringFunction().capitalizeFirstLetter(widget.labelType.name)} List ($notebookName)',
                        style: TextStyle(
                          height: 3,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Close button(X):
                      IconButton(
                          onPressed: () async {
                            // Close the dialog:
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close))
                    ],
                  ),
                ),
                // Add a search bar below the title :
                CustomSearchBar(
                    controller: searchController,
                    labelText: 'Search by ${widget.labelType.name} name'),
                // The content below the title (show the label list items):
                // ***"Expanded" can expand a child of a Row, Column, or Flex so that the child fills the available space:
                Expanded(
                    // *** ClipRect can prevent the items from overflowing:
                    child: ClipRect(
                  // Show the items list which enables users to dismiss it by swiping:
                  child: ListView.builder(
                    itemCount: filteredItems.length, // The number of items
                    itemBuilder: (BuildContext context, int index) {
                      // An action after swiping the item:
                      return Dismissible(
                        background: Container(
                            alignment: Alignment
                                .centerRight, // Only show the delete icon to the right of the item:
                            // Show the delete icon when swiping the item:
                            child: Icon(
                              Icons.delete,
                              color: Colors.black,
                            )),

                        key: UniqueKey(),
                        // Show the dialog to confirm the deletion after swiping the item:
                        confirmDismiss: (DismissDirection direction) async {
                          bool? confirmed = await ConfirmationDialog.show(
                              context,
                              'Are you sure you want to delete this item?',
                              'Cancel',
                              'Delete',
                              true);
                          // If true delete the data, else keep the data
                          return confirmed ?? false;
                        },
                        // What to do when the user delete the item:
                        onDismissed: (DismissDirection direction) {
                          setState(() {
                            // Store the item to be deleted:
                            Map<String, dynamic> itemToDelete =
                                filteredItems[index];
                            // Remove the item from the window:
                            labelItems.remove(
                                itemToDelete); // Remove the item from the backup list
                            filteredItems.removeAt(index);
                            // Delete the data from the database:
                            LabelManager.instance.delete(itemToDelete);
                          });
                        },
                        direction: DismissDirection
                            .endToStart, // Only allow swiping to the left:
                        // Display the items' content:
                        child: ListTile(
                          title: Text(
                            '${filteredItems[index]['name']}', // Get and show the name of the label item:
                            style: TextStyle(
                                // Get the color according to item's priority:
                                color: _analysisColor(filteredItems[index])),
                            overflow: TextOverflow
                                .ellipsis, // Add this line to handle overflow
                            maxLines: 1, // Limit the text to a single line
                          ),
                          onTap: () {
                            // Close the dialog:
                            Navigator.of(context).pop();
                            Offset labelPosition = Offset(
                                filteredItems[index]['position_x'],
                                filteredItems[index][
                                    'position_y']); // get label's coordinate in its page
                            // switch to selected label's page and move view position to label's position
                            widget.switchToPage(
                                filteredItems[index]['pageId'],
                                filteredItems[index]['sectionId'],
                                filteredItems[index]['notebookId'],
                                labelPosition);
                            widget.closeDrawerDialog();
                          },
                        ),
                      );
                    },
                  ),
                )),
              ],
            ),
          ),
        ));
  }

  // Sorts the list according to the priority and datetime:
  List<Map<String, dynamic>> _sort(List<Map<String, dynamic>> originalList) {
    // Create a new modifiable list from the original list:
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.from(originalList);

    list.sort((a, b) {
      int priorityA = int.parse(a['priority']);
      int priorityB = int.parse(b['priority']);

      // Compare priorities first, ascending order:
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // If priorities are the same, compare the dates:
      DateTime dateTimeA = DateTime.parse(a['createAt']);
      DateTime dateTimeB = DateTime.parse(b['createAt']);
      return dateTimeA.compareTo(dateTimeB); // Ascending order by date:
    });

    return list;
  }

  // Return the color according to item's priority:
  Color _analysisColor(Map<String, dynamic> item) {
    int itemPriority = int.parse(item['priority']);
    if (itemPriority == 0) {
      return Colors.red;
    } else if (itemPriority == 1) {
      return Colors.orange;
    }
    return Colors.black;
  }

  // Function to Filter items according to their type and their notebookId:
  List<Map<String, dynamic>> _filterItemsType(
      List<Map<String, dynamic>> items, LabelType lType) {
    List<Map<String, dynamic>> newItems = [];
    LabelType itemLabelType;
    int itemNotebookId;

    for (var i = 0; i < items.length; i++) {
      // Turn the item's label type to LabelType:
      itemLabelType =
          LabelType.values.firstWhere((e) => e.name == items[i]['labelType']);
      itemNotebookId = items[i]['notebookId'];
      // Check whether the lable type and notebookId is match :
      print(
          'itemNotebookId: $itemNotebookId     -    notebookId: ${widget.notebookId}');
      if (itemLabelType == lType && itemNotebookId == widget.notebookId) {
        // If true, add the item into new items list：
        newItems.add(items[i]);
      }
    }
    return newItems;
  }

  // Function to filter items based on search input:
  void _filterItems() {
    setState(() {
      filteredItems = labelItems
          .where((item) => item['name'] // Get the name feild of the item
              .toString() // Convert the item name to string
              .toLowerCase() // Convert all the name to lower case
              .contains(searchController.text
                  .toLowerCase())) // Checks if the string contains the search text
          .toList(); // Finally, canvert all the names to a list
    });
  }

  @override
  void dispose() {
    // Dispose the search controller:
    searchController.dispose();
    super.dispose();
  }
}
