import 'package:flutter/material.dart';
import '../database/data/label_data.dart';
import '../database/manager/label_manager.dart';
import '../function/string_function.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/custom_dropdown_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/items_list.dart';
import '../widgets/prompt.dart';
import '../Note_Hierarchy_Structure/Data_Operation/db_ops.dart';

// A class for showing the information about the label:
class ShowLabel extends StatefulWidget {
  final Map<String, dynamic>? labelItem;
  ShowLabel({required this.labelItem});
  @override
  ShowLabelState createState() => ShowLabelState();
  // A function to show the pop-up window :
  void showPopup(BuildContext context) {
    showDialog(
        barrierDismissible: false, // Prevents dismissal when tapping outside
        context: context,
        builder: (BuildContext costext) => ShowLabel(
              labelItem: labelItem,
            ));
  }
}

// A class for showing and editing the specified label item:
class ShowLabelState extends State<ShowLabel> {
  // A variable for changing the reonly mode to editing mode:
  bool readOnly = true;
  // Some variables for holding the data from the pop-up window:
  int selectedPriority = 0;
  final TextEditingController lName = TextEditingController();
  final TextEditingController lDescription = TextEditingController();
  LabelType labelType = LabelType.question;
  int lid = 0;
  // Some variables for detecting whether the label data are edited:
  String initialLabelName = '';
  String initialLabelDescription = '';
  int initialLabelPriority = 0;
  // Initialize state and is called when the state object is created:
  @override
  void initState() {
    // Ensure that all necessary initialization steps from the superclass are executed before any custom initialization:
    super.initState();

    // Update the state of the variables and assign the data to them:

    setState(() {
      final Map<String, dynamic>? updatedLabel = widget.labelItem;
      // Avoid the ritem is empty:
      if (updatedLabel!.isNotEmpty) {
        // Get and update the label data from the database:
        lName.text = updatedLabel['name'];
        lDescription.text = updatedLabel['description'];
        selectedPriority = int.parse(updatedLabel['priority']);
        lid = updatedLabel['id'];
        labelType = LabelType.values.firstWhere((e) =>
            e.name ==
            updatedLabel[
                'labelType']); // Convert Map from database to Label object
        // ********** Get the backup label data for detecting whether the label data are edited ********** //
        initialLabelName = lName.text;
        initialLabelDescription = lDescription.text;
        initialLabelPriority = selectedPriority;
      }
    });
  }

  // Develop the body of the pop-up window:
  @override
  Widget build(BuildContext context) {
    return Dialog(
      // The backgrould color of the window
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      // Set the padding of the window:
      child: Padding(
        padding: EdgeInsets.all(23),
        child: ConstrainedBox(
          // Set the fixed size of the pop-pu window:
          constraints: BoxConstraints(maxWidth: 600, maxHeight: 650),
          // The content of the pop-up window:
          child: Column(
            children: [
              Container(
                //The border below title:
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Done button(confirming the data and update it) and Edit button(changing the mode and allow to edit the item):
                    TextButton(
                      style: TextButton.styleFrom(
                          overlayColor: readOnly ? Colors.black : Colors.amber),
                      // An action after clicking the done button:
                      onPressed: () => {
                        setState(() {
                          // If readOnly is true, user can click the 'Edit' button to turn readOnly to false (Allow user to edit):
                          if (readOnly) {
                            readOnly = false;
                          }
                          // When readOnly is false, user can click the 'Done' button to update the data:
                          else {
                            // To check whether the label name is empty:
                            if (lName.text.trim().isEmpty) {
                              // Show the prompt:
                              Prompt.show(context,
                                  'Please enter the ${labelType.name} name!');
                            } else {
                              // update the data from the database file:
                              _updateLabel(
                                lid,
                                labelType,
                                lName.text,
                                lDescription.text,
                                selectedPriority,
                              );
                              // Update the state of all Inital data:
                              _updateInitalData();
                            }
                          }
                        })
                      },
                      child: Text(
                        // If readOnly is true, the text button will change to "Edit", otherwise it will change to "Done":
                        readOnly ? 'Edit' : 'Done',
                        style: TextStyle(
                          // If readOnly is true, the text button will change to black color, otherwise it will change to amber color:
                          color: readOnly ? Colors.black : Colors.amber,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // The title of the pop-up window:
                    Text(
                      '${StringFunction().capitalizeFirstLetter(labelType.name)} label',
                      style: TextStyle(
                        height: 3,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Width space (to make the title to center):
                        SizedBox(
                          width: readOnly ? 16 : 26,
                        ), // Close button(X):
                        IconButton(
                            onPressed: () async {
                              _comfirmationAndSave(context);
                            },
                            icon: Icon(Icons.close))
                      ],
                    )
                  ],
                ),
              ),
              // The content below the title:
              // ***"Expanded" can expand a child of a Row, Column, or Flex so that the child fills the available space
              Expanded(
                  child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A text bar for entering the name of the item:
                      CustomTextField(
                          controller: lName,
                          labelText:
                              "${StringFunction().capitalizeFirstLetter(labelType.name)} Label Name",
                          maxLines: 1,
                          //If readOnly is true, users cannot edit the TextField, otherwise they can edit:
                          readOnly: readOnly,
                          icon: Icon(null),
                          onTap: () {}),
                      // Space:
                      SizedBox(height: 30),
                      // A test bar for entering the decoration of the item:
                      CustomTextField(
                          controller: lDescription,
                          labelText: "Decoration",
                          maxLines: 10,
                          //If readOnly is true, users cannot edit the TextField, otherwise they can edit:
                          readOnly: readOnly,
                          icon: Icon(null),
                          onTap: () {}),
                      // Space:
                      SizedBox(height: 30),
                      //  Dropdown menu for selecting the priority:
                      //Check whether the lable type is concept (If lable type is not concept, return Dropdown menu widget):
                      _getPriorityWidget(),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // Update the data from the pop-up window:
  void _updateLabel(
    int lid,
    LabelType labelType,
    String lName,
    String lDescription,
    int lPriority,
  ) async {
    // Insert the data from the pop-up window:
    LabelManager.instance
        .update(lid, labelType, lName, lDescription, lPriority);
    await dbHelper.renameLabelNode(lid, lName);
  }

  // Check whether the lable type is concept:
  Widget _getPriorityWidget() {
    // If lable type is not concept, return Dropdown menu widget:
    if (labelType != LabelType.concept) {
      //  Dropdown menu for selecting the priority:
      return CustomDropdownButton(
          title: 'Priority',
          value: selectedPriority,
          items: ItemsList().priorityItems,
          // If readOnly is true, users cannot edit the DropdownButton, otherwise they cannot edit
          readOnly: readOnly,
          onChanged: (newValue) {
            setState(() {
              selectedPriority = newValue!;
            });
          });
    } else {
      // If label type is concept, return SizedBox():
      return SizedBox();
    }
  }

  // A function for closing the dailog and showing the comfirmation message:
  void _comfirmationAndSave(BuildContext context) async {
    // Check whether the data are edited:
    if (initialLabelName != lName.text ||
        initialLabelDescription != lDescription.text ||
        initialLabelPriority != selectedPriority) {
      // If the label data are edited, ask whether the user want to save it:
      bool? confirmed = await ConfirmationDialog.show(context,
          'Do you want to save your content?', 'Don\'t save', 'Save', false);
      // When user click save:
      if (confirmed ?? false) {
        // If user want to save the data, check whether the name is empty:
        if (lName.text.isNotEmpty) {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // update the data from the database file:
          _updateLabel(
            lid,
            labelType,
            lName.text,
            lDescription.text,
            selectedPriority,
          );
        } else {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // If the label name is empty, show the prompt:
          Prompt.show(context, 'Please enter the ${labelType.name} name!');
        }
      }
      // When user click Close button(X):
      else if (confirmed ?? true) {
        // Do nothing...
      }
      // When user click don't save:
      else {
        // Check if the widget is still mounted before using the context:
        if (!context.mounted) {
          return;
        }
        // Close the dialog when user click don't save:
        Navigator.of(context).pop();
      }
    } else {
      // If no label data is edited, Close the dialog:
      Navigator.of(context).pop();
    }
  }

  // Update the state of all Inital data:
  void _updateInitalData() {
    setState(() {
      readOnly = !readOnly;
      initialLabelName = lName.text;
      initialLabelDescription = lDescription.text;
      initialLabelPriority = selectedPriority;
    });
  }
}
