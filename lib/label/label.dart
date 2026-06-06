import 'package:flutter/material.dart';
import '../database/data/label_data.dart';
import '../database/manager/label_manager.dart';
import '../function/string_function.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/items_list.dart';
import '../widgets/prompt.dart';
import '../widgets/custom_dropdown_button.dart';

// A class for user to creat the label:
class Label extends StatefulWidget {
  // Feild:
  final LabelType labelType;
  final Offset position;
  final String pageId;
  final String sectionId;
  final int notebookId;
  // Constructor (to get the label type):
  Label(
      {required this.labelType,
      required this.position,
      required this.pageId,
      required this.sectionId,
      required this.notebookId,
      super.key});
  @override
  LabelState createState() => LabelState();

  // A function to show the pop-up window :
  Future<LabelData?> showPopup(BuildContext context) async {
    return await showDialog<LabelData>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => this,
    );
  }
}

// A class for developing the pop-up window and handling the data:
class LabelState extends State<Label> {
  // Some variables for storing the data from the pop-up window:
  int selectedPriority = 0;
  final TextEditingController lName = TextEditingController();
  final TextEditingController lDescription = TextEditingController();
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
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: 650,
            ),

            // The content of the pop-up window:
            child: Column(
              children: [
                Container(
                  //The border below title:
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                    color: Colors.black,
                    width: 3,
                  ))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Done button for confirming the data from the window:
                      TextButton(
                        style: TextButton.styleFrom(overlayColor: Colors.amber),
                        // An action after clicking the done button:
                        onPressed: () => {
                          // To check whether the label name is empty:
                          if (lName.text.trim().isEmpty)
                            {
                              // Show the prompt:
                              Prompt.show(context,
                                  'Please enter the ${widget.labelType.name} name!')
                            }
                          else
                            {
                              // Store the data into database file:
                              _storeLabel(
                                  context,
                                  widget.labelType,
                                  lName.text,
                                  lDescription.text,
                                  widget.position,
                                  selectedPriority,
                                  widget.pageId,
                                  widget.sectionId,
                                  widget.notebookId)
                            }
                        },
                        child: Text('Done',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 18)),
                      ),
                      // The title of the pop-up window:
                      Text(
                        'Create ${widget.labelType.name} label',
                        style: TextStyle(
                          height: 3,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Close button(X):
                      IconButton(
                          onPressed: () async {
                            _comfirmationAndSave(context);
                          },
                          icon: Icon(Icons.close))
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
                        // A text bar for entering the name of the label :
                        CustomTextField(
                            controller: lName,
                            labelText:
                                "${StringFunction().capitalizeFirstLetter(widget.labelType.name)} Label Name",
                            maxLines: 1,
                            readOnly: false,
                            icon: Icon(null),
                            onTap: () {}),
                        // Space:
                        SizedBox(height: 30),
                        // A test bar for entering the decoration of the label:
                        CustomTextField(
                            controller: lDescription,
                            labelText: "Description",
                            maxLines: 13,
                            readOnly: false,
                            icon: Icon(null),
                            onTap: () {}),
                        // Space:
                        SizedBox(height: 30),
                        //  Dropdown menu for selecting the priority:
                        //Check whether the lable type is concept (If lable type is not concept, return Dropdown menu widget):
                        _getPriorityWidget(widget.labelType),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ));
  }

  // Store the data from the pop-up window:
  Future<void> _storeLabel(
      BuildContext context,
      LabelType labelType,
      String lName,
      String lDescription,
      Offset lPosition,
      int lPriority,
      String pageId,
      String sectionId,
      int notebookId) async {
    print('************* Store Label *************');
    try {
      final label = await LabelManager.instance.insert(lName, labelType,
          lDescription, lPosition, lPriority, pageId, sectionId, notebookId);
      if (!context.mounted) return;
      Navigator.of(context).pop(label); // Return the inserted LabelData
      print('The Label is stored!');
    } catch (e) {
      print('Error storing label: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      Navigator.of(context).pop(null); // Return null on error
    }
  }

  // Check whether the lable type is concept:
  Widget _getPriorityWidget(LabelType lType) {
    // If lable type is not concept, return Dropdown menu widget:
    if (lType != LabelType.concept) {
      //  Dropdown menu for selecting the priority:
      return CustomDropdownButton(
          title: 'Priority',
          value: selectedPriority,
          items: ItemsList().priorityItems,
          // If readOnly is true, users cannot edit the DropdownButton, otherwise they cannot edit
          readOnly: false,
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
    // Check whether the user has entered any task information:
    if (lName.text.isNotEmpty ||
        lDescription.text.isNotEmpty ||
        selectedPriority != 0) {
      // If user has not entered any task information, ask whether the user want to save it:
      bool? confirmed = await ConfirmationDialog.show(
          context,
          'Do you want to save the content about your task?',
          'Don\'t save',
          'Save',
          false);
      // When user click save:
      if (confirmed ?? false) {
        // If user want to save the data, check whether the name is empty:
        if (lName.text.isNotEmpty) {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // Store the data into database file:
          _storeLabel(
              context,
              widget.labelType,
              lName.text,
              lDescription.text,
              widget.position,
              selectedPriority,
              widget.pageId,
              widget.sectionId,
              widget.notebookId);
        } else {
          // Check if the widget is still mounted before using the context:
          if (!context.mounted) {
            return;
          }
          // If label name is empty, show the prompt:
          Prompt.show(context, 'Please enter the task name!');
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
      // If user did not enter any data, Close the dialog:
      Navigator.of(context).pop();
    }
  }
}
