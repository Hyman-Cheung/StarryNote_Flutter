import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:notes_taking_app/Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import 'package:notes_taking_app/label/show_label.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'HamburgerButton/Button_functions_implementation/add_relation_button/add_relation_button.dart';
import 'HamburgerButton/drawer_framework.dart';
import 'database/data/label_data.dart';
import 'database/manager/label_manager.dart';
import 'label/label.dart';
import 'models/models.dart';
//import 'services/local_storage_service.dart';
import 'tasks/notification/notification_service.dart';
import 'services/page_storage_service.dart';
import 'tasks/tasks_calendar.dart';
import 'tasks/tasks_provider.dart';
import 'widgets/handwritten_painter.dart';
import 'widgets/tool_item.dart';
import 'widgets/color_picker_widget.dart';
import 'utils/helpers.dart';
import 'setting_page/setting_page.dart';
import 'package:file_picker/file_picker.dart'; // For file picker
import 'package:path_provider/path_provider.dart'; // For file path handling
import 'dart:io'; // For file I/O
import 'package:defer_pointer/defer_pointer.dart';
import 'widgets/pdf_handler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'Note_Hierarchy_Structure/Data_Operation/db_ops.dart'; // For database operations
import 'package:timezone/data/latest.dart' as tz;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Creat Task Provider:
      create: (_) => TaskProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: NoteTakingApp(),
      ),
    );
  }
}

class NoteTakingApp extends StatefulWidget {
  const NoteTakingApp({super.key});

  @override
  _NoteTakingAppState createState() => _NoteTakingAppState();
}

class _NoteTakingAppState extends State<NoteTakingApp> {
  // Initialize the NotificationService：
  NotificationService notificationService = NotificationService();
  late PageStorageService _storageService;
  String? currentPageId; // Track the current page
  String? currentSectionId;
  int? currentNotebookId;
  bool isTypingMode = false;
  bool isCursorMode = false;
  Color textColor = Colors.black;
  double textFontSize = 18.0;
  bool isHandwrittenMode = false;
  bool isEraserMode = false;
  double eraserThickness = 10.0;
  bool isStrokeEraser = true;
  List<TextData> textDataList = [];
  List<Stroke> strokes = [];
  List<Stroke> _pointEraserRemovedStrokes = [];
  Offset? _textBoxPosition;
  final TextEditingController _textController = TextEditingController();
  int? _editingTextIndex;
  final FocusNode _textFocusNode = FocusNode();
  bool _textFieldActive = false;
  final List<Color> presetColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.black,
    Colors.grey,
    Colors.white,
  ];
  final TransformationController _transformationController =
      TransformationController();
  LabelType? selectedLabelType;
  List<LabelData> labels = [];

  List<WritingTool> writingTools = [
    WritingTool(
      id: 'default_pen',
      color: Colors.black,
      thickness: 4.0,
      isDefault: true,
    ),
  ];
  WritingTool? selectedTool;

  int? _selectedLabelIndex;
  final Map<LabelType, List<String>> _labelOptions = {
    LabelType.concept: ['Show More', 'Create Relation', 'Delete'],
    LabelType.question: ['Show More', 'Delete'],
    LabelType.review: ['Show More', 'Delete'],
  };

  int? _selectedTextIndex;
  bool _isDraggingText = false;
  Offset? _dragStartScenePosition;
  bool _isNewStroke = true;

  final _interactiveViewerKey = GlobalKey();
  int? draggedIndex;

  // Action history for undo functionality
  List<AppAction> actionHistory = [];

  TextData? _originalTextData;

  bool isLassoMode = false;
  Path? lassoPath;
  List<Offset>? lassoPoints;
  bool isDraggingStrokes = false;
  Offset? lastDragPosition;

  PdfData? savedPdf;
  bool isPdfLoaded = false;
  String pdfKey = UniqueKey().toString();

  List<bool> isSelected_hBar = [true, false, false]; // For horizontal bar

  // A function for nitializing notification service:
  Future<void> _initializeNotificationService() async {
    await notificationService.init();
    tz.initializeTimeZones();
  }

  @override
  void initState() {
    super.initState();
    //_storageService = LocalStorageService();
    _storageService = PageStorageService();
    _loadInitialPage();
    // Nitializing notification service
    _initializeNotificationService();
    selectedTool = writingTools.isNotEmpty ? writingTools.first : null;
  }

  Future<void> _loadInitialPage() async {
    final notebooks = await fetchNotebooks();
    print('Fetched notebooks: ${notebooks.length}');
    if (notebooks.isNotEmpty) {
      final notebookId = notebooks.first.notebook_id;
      final sections = await fetchSectionsByNotebookId(notebookId);

      print('Fetched sections: ${sections.length}');
      if (sections.isNotEmpty) {
        final sectionId = sections.first.sectionId;
        final pages = await fetchPagesBySectionId(sectionId);
        print('Fetched pages: ${pages.length}');
        if (pages.isNotEmpty) {
          final initialPageId = pages.first.pageId;
          print('Loading initial page: $initialPageId');
          await switchToPage(initialPageId, sectionId, notebookId);
          print('Initial page loaded with ${labels.length} labels');
        }
      }
    } else {
      print('No notebooks found, creating default page');
      // Optionally create a default page here if needed
    }
  }

  Future<void> switchToPage(
      String newPageId, String newSectionId, int newNotebookId,
      [Offset? positionToFocus] // optional parameter for label's position
      ) async {
    if (currentPageId != null && currentPageId != newPageId) {
      await _saveData();
    }
    final data = await _storageService.loadPageData(newPageId);

    print('Switching to page: $newPageId');

    setState(() {
      // Update the current IDs:
      currentPageId = newPageId;
      currentSectionId = newSectionId;
      currentNotebookId = newNotebookId;
      strokes =
          (data['strokes'] as List?)?.map((s) => Stroke.fromJson(s)).toList() ??
              [];
      textDataList = (data['textDataList'] as List?)
              ?.map((t) => TextData.fromJson(t))
              .toList() ??
          [];
      writingTools = (data['writingTools'] as List?)
              ?.map((w) => WritingTool.fromJson(w))
              .toList() ??
          [
            WritingTool(
                id: 'default_pen',
                color: Colors.black,
                thickness: 4.0,
                isDefault: true),
          ];
      selectedTool = writingTools.isNotEmpty ? writingTools.first : null;
      savedPdf =
          data['pdfData'] != null ? PdfData.fromJson(data['pdfData']) : null;
      isPdfLoaded = savedPdf != null;
      actionHistory.clear();

      // Get the all the labels of the relevant page ID from the SQL database:
      updateLabel(newPageId);
    });

    if (positionToFocus != null) {
      // label position is passed (label clicked on label list)
      _centerOnPosition(
          positionToFocus); // auto. move the viewing position to label's position in target page
    }
  }

  // Get the all the labels of the relevant page ID from the SQL database:
  void updateLabel(newPageId) async {
    final labelsDb = await LabelManager.instance.getData();
    print('Raw labels from DB: $labelsDb');
    setState(() {
      labels.clear();
      if (labelsDb.isNotEmpty) {
        for (var labelDb in labelsDb) {
          if (labelDb['pageId'] == newPageId) {
            try {
              final label = LabelData(
                  id: labelDb['id'],
                  labelType: LabelType.values
                      .firstWhere((e) => e.name == labelDb['labelType']),
                  name: labelDb['name'],
                  description: labelDb['description'],
                  priority: int.parse(labelDb['priority'].toString()),
                  position: Offset(
                    (labelDb['position_x'] as num).toDouble(),
                    (labelDb['position_y'] as num).toDouble(),
                  ),
                  createAt: labelDb['createAt'],
                  lastEditTime: labelDb['lastEditTime'],
                  pageId: labelDb['pageId'],
                  sectionId: labelDb['sectionId'],
                  notebookId: labelDb['notebookId']);
              labels.add(label);
              print('Loaded label: ${label.id} - ${label.name}');
            } catch (e) {
              print('Error parsing label: $labelDb, error: $e');
            }
          }
        }
      }
    });
    print('Loaded ${labels.length} labels for page: $newPageId');
  }

  Future<void> createNewPage(String sectionId, String pageTitle) async {
    await addPageToDB(pageTitle, sectionId);
    final pages = await fetchPagesBySectionId(sectionId);
    final newPage = pages.last; // Assumes the newest page is last
    final pageId = newPage.pageId;
    final notebookId = await fetchNotebooks();
    await _storageService.savePageData(pageId, {
      'strokes': [],
      'textDataList': [],
      'writingTools': [
        {
          'id': 'default_pen',
          'color': Colors.black.value,
          'thickness': 4.0,
          'isHighlighter': false,
          'isDefault': true,
        }
      ],
      'pdfData': null,
    });
    await switchToPage(pageId, newPage.sectionId, newPage.notebookId);
  }

  Future<void> _listFilesInDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files = dir.listSync(); // List all files in the directory

    // Filter for JSON files starting with "page_"
    final jsonFiles = files
        .where((file) =>
            file.path.endsWith('.json') && file.path.contains('page_'))
        .map((file) => file.path.split('/').last) // Get just the file name
        .toList();

    // Print to console for debugging
    print('JSON Files in Documents Directory: $jsonFiles');

    // Optionally, show a dialog with the file list
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('JSON Files in Documents Directory'),
        content: SingleChildScrollView(
          child: Column(
            children: jsonFiles
                .map((fileName) => ListTile(
                      title: Text(fileName),
                      onTap: () async {
                        // Optionally, read and display the file contents
                        final file = File('${directory.path}/$fileName');
                        final contents = await file.readAsString();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Contents of $fileName'),
                            content: SingleChildScrollView(
                              child: Text(contents),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Colors.indigo),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndLoadPdf() async {
    // Pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      // Save the picked PDF file to a local directory
      final file = File(result.files.single.path!);
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = '${directory.path}/page_${currentPageId}_pdf.pdf';
      await file.copy(savedPath);

      setState(() {
        savedPdf = PdfData(
          pdfPath: savedPath,
          totalPages: 0, // temp
          pdfPageList: [0],
          isPdfRendered: false,
        );
        isPdfLoaded = true;
      });
      await _saveData();
    }
  }

  // Track totalPages when the PDF is loaded
  void _onPageChanged(int? current, int? total) {
    setState(() {
      if (total != null &&
          total != savedPdf!.pdfPageList.last &&
          !savedPdf!.isPdfRendered) {
        savedPdf!.pdfPageList = List<int>.generate(total, (i) => i++);
        if (savedPdf!.pdfPageList.length == total) {
          savedPdf!.isPdfRendered = true;
          _saveData();
        }
      }
    });
  }

  void _deletePdf() async {
    if (savedPdf != null) {
      final file = File(savedPdf!.pdfPath);
      if (await file.exists()) {
        await file.delete();

        setState(() {
          savedPdf = null;
          isPdfLoaded = false;
        });
        await _saveData();
      }
    }
  }

  Future<void> _saveData() async {
    if (currentPageId == null) return;
    final data = {
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'textDataList': textDataList.map((t) => t.toJson()).toList(),
      'writingTools': writingTools.map((w) => w.toJson()).toList(),
      'pdfData': savedPdf?.toJson(),
    };
    await _storageService.savePageData(currentPageId!, data);
  }

  void _toggleModes(bool typing) {
    setState(() {
      selectedLabelType = null;
      _selectedTextIndex = null;
      isCursorMode = false;

      if ((isTypingMode && _textController.text.isNotEmpty) ||
          (isHandwrittenMode && _textFieldActive)) {
        _saveText();
      }
      isTypingMode = typing;
      isHandwrittenMode = !typing;
      isEraserMode = false;
      _isNewStroke = true;
      _textBoxPosition = null;
      _editingTextIndex = null;
      _textController.clear();
      _textFieldActive = false;
      if (isTypingMode) {
        selectedTool = null; // Deselect the current tool in typing mode
      }
      if (isLassoMode) {
        isLassoMode = false;
        _clearStrokeSelection(); // Clear selection when exiting lasso mode
      }
    });
  }

  void _toggleCursorMode() {
    setState(() {
      isCursorMode = !isCursorMode;
      if (isCursorMode) {
        isTypingMode = false;
        isHandwrittenMode = false;
        isEraserMode = false;
        selectedLabelType = null;
        _textFieldActive = false;
        if (isLassoMode) {
          isLassoMode = false;
          _clearStrokeSelection(); // Clear selection when exiting lasso mode
        }
      }
    });
  }

  void _showEraserSettingsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Eraser Settings'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Thickness: ${eraserThickness.round()}px'),
                    Slider(
                      inactiveColor: const Color.fromARGB(100, 59, 76, 171),
                      activeColor: Colors.indigo,
                      value: eraserThickness,
                      min: 5.0,
                      max: 50.0,
                      divisions: 9,
                      label: eraserThickness.round().toString(),
                      onChanged: (value) {
                        setState(() => eraserThickness = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Eraser Type:'),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      fillColor: Colors.indigo,
                      isSelected: [isStrokeEraser, !isStrokeEraser],
                      onPressed: (index) {
                        setState(() => isStrokeEraser = index == 0);
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Stroke Eraser',
                              style: TextStyle(
                                  color: isStrokeEraser
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Point Eraser',
                              style: TextStyle(
                                  color: isStrokeEraser
                                      ? Colors.black
                                      : Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Colors.indigo)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDrawer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height,
            child: CustomDrawer(
              onPageSelected: switchToPage,
              onCreatePage: createNewPage, // Pass the create function
            ), // from UIFramework.dart
          ),
        );
      },
    );
  }

  void _showTextSettingsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // The backgrould color of the window
              backgroundColor: Colors.white,
              title: const Text('Text Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Font Size: ${textFontSize.round()}'),
                  Slider(
                    thumbColor: Colors.indigo,
                    value: textFontSize,
                    min: 1.0,
                    max: 75.0,
                    divisions: 75,
                    label: textFontSize.round().toString(),
                    onChanged: (value) {
                      setDialogState(() => textFontSize = value);
                      if (_selectedTextIndex != null) {
                        setState(() {
                          TextData previousText =
                              textDataList[_selectedTextIndex!];
                          textDataList[_selectedTextIndex!] =
                              textDataList[_selectedTextIndex!].copyWith(
                            fontSize: value,
                          );
                          actionHistory.add(AppAction(
                            type: ActionType.editText,
                            data: textDataList[_selectedTextIndex!],
                            previousData: previousText,
                          ));
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: textFontSize.round(),
                    dropdownColor: Colors.white,
                    items: List.generate(75, (index) => index + 1)
                        .map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setDialogState(() {
                        textFontSize = newValue!.toDouble();
                      });
                      if (_selectedTextIndex != null && newValue != null) {
                        setState(() {
                          TextData previousText =
                              textDataList[_selectedTextIndex!];
                          textDataList[_selectedTextIndex!] =
                              textDataList[_selectedTextIndex!].copyWith(
                            fontSize: newValue.toDouble(),
                          );
                          actionHistory.add(AppAction(
                            type: ActionType.editText,
                            data: textDataList[_selectedTextIndex!],
                            previousData: previousText,
                          ));
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: Icon(Icons.format_color_text, color: textColor),
                    onPressed: () async {
                      Color? newColor =
                          await _showAdvancedColorPicker(textColor);
                      if (newColor != null) {
                        setDialogState(() => textColor = newColor);
                        if (_selectedTextIndex != null) {
                          setState(() {
                            TextData previousText =
                                textDataList[_selectedTextIndex!];
                            textDataList[_selectedTextIndex!] =
                                textDataList[_selectedTextIndex!].copyWith(
                              textColor: newColor,
                            );
                            actionHistory.add(AppAction(
                              type: ActionType.editText,
                              data: textDataList[_selectedTextIndex!],
                              previousData: previousText,
                            ));
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => textColor = color);
                          if (_selectedTextIndex != null) {
                            setState(() {
                              TextData previousText =
                                  textDataList[_selectedTextIndex!];
                              textDataList[_selectedTextIndex!] =
                                  textDataList[_selectedTextIndex!].copyWith(
                                textColor: color,
                              );
                              actionHistory.add(AppAction(
                                type: ActionType.editText,
                                data: textDataList[_selectedTextIndex!],
                                previousData: previousText,
                              ));
                            });
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: textColor == color
                                  ? Colors.indigo
                                  : Colors.grey,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: () async {
                      Color? newColor =
                          await _showAdvancedColorPicker(textColor);
                      if (newColor != null) {
                        setDialogState(() => textColor = newColor);
                        if (_selectedTextIndex != null) {
                          setState(() {
                            TextData previousText =
                                textDataList[_selectedTextIndex!];
                            textDataList[_selectedTextIndex!] =
                                textDataList[_selectedTextIndex!].copyWith(
                              textColor: newColor,
                            );
                            actionHistory.add(AppAction(
                              type: ActionType.editText,
                              data: textDataList[_selectedTextIndex!],
                              previousData: previousText,
                            ));
                          });
                        }
                      }
                    },
                    child: const Text(
                      'More Text Colour',
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Colors.indigo)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleTapDown(Offset scenePosition) {
    if (!isTypingMode || _isDraggingText) return;

    if (_textFieldActive && _textController.text.isNotEmpty) {
      _saveText();
    }

    bool tappedExistingText = false;

    for (int i = 0; i < textDataList.length; i++) {
      final textData = textDataList[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: textData.text,
          style: TextStyle(
            fontSize: textData.fontSize,
            color: textData.textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textRect = Rect.fromPoints(
        textData.position,
        textData.position.translate(textPainter.width, textPainter.height),
      );

      final expandedRect = textRect.inflate(10.0);
      if (expandedRect.contains(scenePosition)) {
        tappedExistingText = true;
        setState(() {
          _selectedTextIndex = i;
          _textFieldActive = false;
        });
        break;
      }
    }

    if (!tappedExistingText) {
      setState(() {
        _selectedTextIndex = null;
      });
      _showTextInput(scenePosition);
    }
  }

  void _showTextInput(Offset scenePosition) {
    setState(() {
      _textBoxPosition = scenePosition;
      _textFieldActive = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
    });
  }

  void _saveText() {
    setState(() {
      if (_editingTextIndex != null) {
        if (_textController.text.isEmpty) {
          // Remove the text entry if it’s fully deleted
          TextData removedText = textDataList[_editingTextIndex!];
          textDataList.removeAt(_editingTextIndex!);
          actionHistory.add(AppAction(
            type:
                ActionType.deleteText, // Use addText to allow undo to re-add it
            data: removedText,
          ));
        } else {
          // Update the existing text if it’s not empty
          TextData previousText = textDataList[_editingTextIndex!];
          textDataList[_editingTextIndex!] = TextData(
            text: _textController.text,
            position: _textBoxPosition!,
            textColor: textColor,
            fontSize: textFontSize,
          );
          actionHistory.add(AppAction(
            type: ActionType.editText,
            data: textDataList[_editingTextIndex!],
            previousData: previousText,
          ));
        }
      } else {
        // Add new text if it’s not empty and not editing an existing entry
        TextData newText = TextData(
          text: _textController.text,
          position: _textBoxPosition!,
          textColor: textColor,
          fontSize: textFontSize,
        );
        textDataList.add(newText);
        actionHistory.add(AppAction(
          type: ActionType.addText,
          data: newText,
        ));
      }
      // Always reset the text box state, whether text is empty or not
      _textBoxPosition = null;
      _editingTextIndex = null;
      _textController.clear();
      _textFieldActive = false;
    });
    _saveData();
  }

  void _editText(int index) {
    if (_textFieldActive &&
        _editingTextIndex != null &&
        _textController.text.isNotEmpty) {
      _saveText();
    }

    setState(() {
      _editingTextIndex = index;
      _selectedTextIndex = null;
      _textController.text = textDataList[index].text;
      _textBoxPosition = textDataList[index].position;
      _textFieldActive = true;
      textColor = textDataList[index].textColor;
      textFontSize = textDataList[index].fontSize;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  void _handleDrawing(Offset scenePosition) {
    if (!isHandwrittenMode) return; // Only proceed if in handwritten mode

    if (isEraserMode) {
      _eraseStrokes(scenePosition);
    } else if (selectedTool != null) {
      bool alreadyDrawn = false;
      final currentColor = selectedTool!.color.withAlpha(255);
      final currentRadius = selectedTool!.thickness / 2;

      for (final stroke in strokes) {
        final strokeColor = stroke.color.withAlpha(255);
        if (strokeColor != currentColor) continue;

        final existingRadius = stroke.strokeWidth / 2;
        final combinedThreshold = existingRadius + currentRadius;

        for (final point in stroke.points) {
          if ((point - scenePosition).distance < combinedThreshold) {
            alreadyDrawn = true;
            break;
          }
        }
        if (alreadyDrawn) break;
      }

      if (!alreadyDrawn) {
        setState(() {
          if (_isNewStroke || strokes.isEmpty) {
            Stroke newStroke = Stroke(
              points: [scenePosition],
              color: selectedTool!.color,
              strokeWidth: selectedTool!.thickness,
              isHighlighter: selectedTool!.isHighlighter,
            );
            strokes.add(newStroke);
            actionHistory.add(AppAction(
              type: ActionType.addStroke,
              data: newStroke,
            ));
          } else {
            strokes.last.points.add(scenePosition);
          }
        });
        _saveData();
      }
    }
  }

  void _eraseStrokes(Offset position) {
    setState(() {
      if (isStrokeEraser) {
        List<Stroke> removedStrokes = strokes.where((stroke) {
          return stroke.points
              .any((point) => (point - position).distance <= eraserThickness);
        }).toList();
        strokes.removeWhere((stroke) {
          return stroke.points
              .any((point) => (point - position).distance <= eraserThickness);
        });
        if (removedStrokes.isNotEmpty) {
          actionHistory.add(AppAction(
            type: ActionType.eraseStroke,
            data: removedStrokes,
            previousData: List<Stroke>.from(strokes)
              ..addAll(removedStrokes), // Full state before erase
          ));
        }
      } else {
        final List<Stroke> newStrokes = [];

        for (final stroke in strokes) {
          final indexedPoints = stroke.points.asMap().entries.toList();
          final remainingEntries = indexedPoints
              .where((entry) =>
                  (entry.value - position).distance > eraserThickness)
              .toList();

          if (remainingEntries.length == stroke.points.length) {
            newStrokes.add(stroke);
          } else {
            _pointEraserRemovedStrokes.add(stroke);

            List<List<Offset>> segments = [];
            List<Offset> currentSegment = [];
            int? prevIndex;

            for (final entry in remainingEntries) {
              if (prevIndex == null || entry.key == prevIndex + 1) {
                currentSegment.add(entry.value);
              } else {
                if (currentSegment.length >= 2) {
                  segments.add(List.from(currentSegment));
                }
                currentSegment = [entry.value];
              }
              prevIndex = entry.key;
            }
            if (currentSegment.length >= 2) {
              segments.add(List.from(currentSegment));
            }

            for (final segment in segments) {
              newStrokes.add(Stroke(
                points: segment,
                color: stroke.color,
                strokeWidth: stroke.strokeWidth,
                isHighlighter: stroke.isHighlighter,
              ));
            }
          }
        }

        strokes
          ..clear()
          ..addAll(newStrokes);
      }
      _isNewStroke = true;
    });
    _saveData();
  }

  void _handleDrawingEnd(DragEndDetails details) {
    if (!isHandwrittenMode || isEraserMode) return;
  }

  void _handleTextDrag(int index, DragUpdateDetails details) {
    setState(() {
      // Store the original TextData before moving
      final originalText = textDataList[index];
      // Update position
      textDataList[index] = textDataList[index].copyWith(
        position: textDataList[index].position + details.delta,
      );
      // Add to action history
      actionHistory.add(AppAction(
        type: ActionType.editText,
        data: textDataList[index], // New position
        previousData: originalText, // Original position
      ));
      _saveData();
    });
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  void _showToolConfigDialog({
    WritingTool? existingTool,
    bool initialIsHighlighter = false,
    Color? initialColor,
  }) {
    final isEditing = existingTool != null;
    final initialTool = existingTool ??
        WritingTool(
          id: const Uuid().v4(),
          color: initialColor ?? Colors.black,
          thickness: 4.0,
          isHighlighter: initialIsHighlighter,
        );

    Color selectedColor = initialTool.color;
    double thickness = initialTool.thickness;
    bool isHighlighter = initialTool.isHighlighter;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
              '${isEditing ? 'Edit' : 'New'} ${isHighlighter ? 'Highlighter' : 'Pen'}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ColorPickerWidget(
                  selectedColor: selectedColor,
                  onColorChanged: (c) =>
                      setDialogState(() => selectedColor = c),
                  presetColors: presetColors,
                  onAdvancedColorPicker: _showAdvancedColorPicker,
                ),
                const SizedBox(height: 20),
                Text('Thickness: ${thickness.round()}px'),
                Slider(
                  inactiveColor: const Color.fromARGB(100, 59, 76, 171),
                  activeColor: Colors.indigo,
                  value: thickness,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setDialogState(() => thickness = v),
                ),
                SwitchListTile(
                  inactiveTrackColor: Colors.white,
                  activeColor: Colors.indigo,
                  title: const Text('Highlighter'),
                  value: isHighlighter,
                  onChanged: (v) => setDialogState(() => isHighlighter = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.indigo)),
            ),
            TextButton(
              onPressed: () {
                final newTool = WritingTool(
                  id: initialTool.id,
                  color: selectedColor,
                  thickness: thickness,
                  isHighlighter: isHighlighter,
                );

                setState(() {
                  if (isEditing) {
                    final index =
                        writingTools.indexWhere((t) => t.id == initialTool.id);
                    if (index != -1) {
                      writingTools[index] = newTool;
                    } else {
                      writingTools.add(newTool);
                    }
                  } else {
                    writingTools.add(newTool);
                  }
                  selectedTool = newTool;
                });

                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.indigo)),
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _showAdvancedColorPicker(Color initialColor) async {
    Color selectedColor = initialColor;
    return await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) => selectedColor = color,
            displayThumbColor: true,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.7,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.indigo),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selectedColor),
            child: const Text('OK', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  void _undoLastAction() {
    if (actionHistory.isEmpty) return;

    setState(() {
      final lastAction = actionHistory.removeLast();

      switch (lastAction.type) {
        case ActionType.addLabel:
          final LabelData label = lastAction.data;
          final index =
              labels.indexWhere((l) => l.id == label.id); // Match by id
          setState(() {
            if (index != -1) {
              // Undo an add: Remove the label
              labels.removeAt(index);
              LabelManager.instance.delete(label.toMap());
              print('Undo addLabel: Removed label ${label.id} - ${label.name}');
            } else {
              // Undo a delete: Restore the label
              labels.add(label);
              LabelManager.instance.insert(
                  label.name,
                  label.labelType,
                  label.description,
                  label.position,
                  label.priority,
                  label.pageId,
                  label.sectionId,
                  label.notebookId);
              print(
                  'Undo deleteLabel: Restored label ${label.id} - ${label.name}');
            }
          });
          break;

        case ActionType.addText:
          final text = lastAction.data as TextData;
          textDataList.remove(text);
          break;

        case ActionType.editText:
          if (lastAction.data is TextData) {
            final editedText = lastAction.data as TextData;
            final previousText = lastAction.previousData as TextData;
            final index = textDataList.indexWhere((t) =>
                t.position == editedText.position && t.text == editedText.text);
            if (index != -1) {
              textDataList[index] = previousText;
            } else {
              print('Warning: Could not find edited text in list to undo');
            }
          } else if (lastAction.data is List<Stroke>) {
            final movedStrokes = lastAction.data as List<Stroke>;
            final previousStrokes = lastAction.previousData as List<Stroke>;
            setState(() {
              for (var i = 0; i < strokes.length; i++) {
                final stroke = strokes[i];
                final previousStroke = previousStrokes.firstWhere(
                  (ps) =>
                      ps.points.length == stroke.points.length &&
                      ps.color == stroke.color &&
                      ps.strokeWidth == stroke.strokeWidth &&
                      ps.isHighlighter == stroke.isHighlighter,
                  orElse: () => stroke,
                );
                if (movedStrokes.any((ms) =>
                    ms.points.length == stroke.points.length &&
                    ms.color == stroke.color)) {
                  strokes[i] = Stroke(
                    points: List.from(previousStroke.points),
                    color: stroke.color,
                    strokeWidth: stroke.strokeWidth,
                    isHighlighter: stroke.isHighlighter,
                    isSelected: stroke.isSelected,
                  );
                }
              }
            });
          }
          break;

        case ActionType.addStroke:
          if (lastAction.data is Stroke) {
            final stroke = lastAction.data as Stroke;
            strokes.remove(stroke);
          } else if (lastAction.data is List<Stroke>) {
            // Handle lasso selection undo
            final selectedStrokes = lastAction.data as List<Stroke>;
            final previousStrokes = lastAction.previousData as List<Stroke>;
            strokes
              ..clear()
              ..addAll(previousStrokes); // Restore previous state
          }
          break;

        case ActionType.eraseStroke:
          List<Stroke> removedStrokes;
          if (lastAction.data is List<Stroke>) {
            removedStrokes = lastAction.data as List<Stroke>;
          } else if (lastAction.data is List<dynamic>) {
            removedStrokes = (lastAction.data as List<dynamic>)
                .map((item) => item as Stroke)
                .toList();
          } else {
            print(
                'Error: eraseStroke data is not a List: ${lastAction.data.runtimeType}');
            return;
          }
          if (lastAction.previousData is List<Stroke>) {
            // Restore the full pre-erase state
            strokes
              ..clear()
              ..addAll(lastAction.previousData as List<Stroke>);
          } else if (lastAction.previousData is List<dynamic>) {
            strokes
              ..clear()
              ..addAll((lastAction.previousData as List<dynamic>)
                  .map((item) => item as Stroke)
                  .toList());
          } else {
            print(
                'Error: eraseStroke previousData is not a List: ${lastAction.previousData.runtimeType}');
            return;
          }
          break;

        case ActionType.deleteText:
          final deletedText = lastAction.data as TextData;
          textDataList.add(deletedText); // Re-add the deleted text
          break;
      }

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Stroke> highlighterStrokes =
        strokes.where((s) => s.isHighlighter).toList();
    List<Stroke> penStrokes = strokes.where((s) => !s.isHighlighter).toList();
    final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _openDrawer, // actions when user press it
                ),
                // Logo:
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('assets/logo.png'),
                ),
                const Text(
                  'Starry Note',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 20,
                ), // Space
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: _undoLastAction, // Undo function
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all_sharp),
                  tooltip: 'Clear Page',
                  onPressed: _clearData,
                ),
              ],
            ),
            ToggleButtons(
              color: const Color.fromARGB(255, 93, 91, 91),
              borderRadius: BorderRadius.circular(20),
              isSelected: isSelected_hBar,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < isSelected_hBar.length; i++) {
                    isSelected_hBar[i] = i == index;
                  }
                });
              },
              selectedColor: Colors.white,
              fillColor: const Color.fromARGB(255, 52, 50, 50),
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Insert'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Draw'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Accessibility'),
                ),
              ],
            ),
            Row(
              children: [
                // Show tasks calendar:
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    TasksCalendar(
                      switchToPage: switchToPage,
                    ).showPopup(context);
                  }, // Add calendar functionality
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_sharp,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  }, // Add settings functionality if needed
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            child: _buildToolbar(isSelected_hBar),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(color: Colors.white),
                InteractiveViewer(
                  key: _interactiveViewerKey,
                  transformationController: _transformationController,
                  panEnabled: isCursorMode || !_isDraggingText,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.01,
                  maxScale: 20.0,
                  child: DeferredPointerHandler(
                    child: Stack(
                      children: [
                        Container(
                            width: 10000, height: 10000, color: Colors.white),
                        RepaintBoundary(
                          child: SizedBox(
                            width: 10000,
                            height: 10000,
                            child: CustomPaint(
                              painter: HandwrittenPainter(highlighterStrokes),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10000,
                          height: 10000,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (isPdfLoaded)
                                for (int index = 0;
                                    index < savedPdf!.pdfPageList.length;
                                    index++)
                                  Positioned(
                                    top: 0.0 + 850 * index,
                                    left: 0.0,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height,
                                      child: DeferPointer(
                                          // allow hit test outside parent boundary
                                          child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onLongPressStart: (details) async {
                                          // Capture the position of the long press
                                          final position =
                                              details.globalPosition;
                                          await showPdfPageContextMenu(
                                              context,
                                              index,
                                              savedPdf!.pdfPageList,
                                              _deletePdf,
                                              () => setState(() {}),
                                              _saveData,
                                              position);
                                          pdfKey = UniqueKey().toString();
                                        },
                                        onDoubleTap: () => debugPrint(
                                            "Double Tap blocked on page ${savedPdf!.pdfPageList[index] + 1}"),
                                        child: PDFView(
                                          key: Key(pdfKey),
                                          enableSwipe: false,
                                          pageFling: false,
                                          pageSnap: false,
                                          filePath: savedPdf!.pdfPath,
                                          defaultPage:
                                              savedPdf!.pdfPageList[index],
                                          fitPolicy: FitPolicy.BOTH,
                                          onPageChanged: (current, total) =>
                                              _onPageChanged(current, total),
                                        ),
                                      )),
                                    ),
                                  ),
                              ...labels.asMap().entries.map((entry) {
                                final index = entry.key;
                                final label = entry.value;
                                return Positioned(
                                  left: label.position.dx - 20,
                                  top: label.position.dy - 20,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.transparent,
                                    child: Center(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onLongPressStart: (details) {
                                          setState(() =>
                                              _selectedLabelIndex = index);
                                          showContextMenu(context, index,
                                              details.globalPosition);
                                        },
                                        child: Icon(
                                          getLabelIcon(label.labelType),
                                          color: _getLabelColor(label),
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              for (var index = 0;
                                  index < textDataList.length;
                                  index++)
                                Positioned(
                                  left: textDataList[index].position.dx,
                                  top: textDataList[index].position.dy,
                                  child: MouseRegion(
                                    cursor: isTypingMode
                                        ? SystemMouseCursors.move
                                        : SystemMouseCursors.basic,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          if (!isTypingMode) return;
                                          setState(() {
                                            _selectedTextIndex = index;
                                            _textFieldActive = false;
                                          });
                                        },
                                        onDoubleTap: () {
                                          if (!isTypingMode) return;
                                          _editText(index);
                                        },
                                        onLongPress: () {
                                          if (!isTypingMode) return;
                                          final RenderBox box = context
                                              .findRenderObject() as RenderBox;
                                          final position =
                                              box.localToGlobal(Offset.zero);
                                          _showTextContextMenu(
                                            context,
                                            index,
                                            position: position,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration:
                                              _selectedTextIndex == index
                                                  ? BoxDecoration(
                                                      color: Colors.grey[200],
                                                      border: Border.all(
                                                          color: Colors.grey),
                                                    )
                                                  : null,
                                          child: Text(
                                            textDataList[index].text,
                                            style: TextStyle(
                                              fontSize:
                                                  textDataList[index].fontSize,
                                              color:
                                                  textDataList[index].textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_textFieldActive && _textBoxPosition != null)
                                Positioned(
                                  left: _textBoxPosition!.dx,
                                  top: _textBoxPosition!.dy,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 200,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _textController,
                                        focusNode: _textFocusNode,
                                        decoration:
                                            const InputDecoration.collapsed(
                                          hintText: 'Type here...',
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                        ),
                                        style: TextStyle(
                                            fontSize: textFontSize,
                                            color: textColor),
                                        maxLines: null,
                                        autofocus: true,
                                        onSubmitted: (_) => _saveText(),
                                        onTapOutside: (_) {
                                          _saveText();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IgnorePointer(
                          child: RepaintBoundary(
                            child: SizedBox(
                              width: 10000,
                              height: 10000,
                              child: CustomPaint(
                                painter: HandwrittenPainter(penStrokes),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Keep your existing gesture detectors
                if (isHandwrittenMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) {
                        setState(() => _isNewStroke = true);
                        final sceneOffset =
                            _transformGlobalToScene(details.globalPosition);
                        if (isEraserMode && !isStrokeEraser) {
                          _pointEraserRemovedStrokes.clear();
                        }
                        _handleDrawing(sceneOffset);
                      },
                      onPanUpdate: (details) {
                        setState(() => _isNewStroke = false);
                        final sceneOffset =
                            _transformGlobalToScene(details.globalPosition);
                        _handleDrawing(sceneOffset);
                      },
                      onPanEnd: (details) {
                        if (isEraserMode &&
                            !isStrokeEraser &&
                            _pointEraserRemovedStrokes.isNotEmpty) {
                          setState(() {
                            actionHistory.add(AppAction(
                              type: ActionType.eraseStroke,
                              data: List.from(_pointEraserRemovedStrokes),
                              previousData: List<Stroke>.from(strokes)
                                ..addAll(_pointEraserRemovedStrokes),
                            ));
                            _pointEraserRemovedStrokes = [];
                          });
                          _saveData();
                        }
                        _handleDrawingEnd(details);
                      },
                    ),
                  ),
                if (isTypingMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (details) {
                        final sceneOffset =
                            _transformGlobalToScene(details.globalPosition);
                        _handleTapDown(sceneOffset);
                      },
                      onPanStart: (details) {
                        if (!isTypingMode) return;
                        final scenePosition =
                            _transformGlobalToScene(details.globalPosition);
                        for (int i = 0; i < textDataList.length; i++) {
                          final textData = textDataList[i];
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: textData.text,
                              style: TextStyle(
                                fontSize: textData.fontSize,
                                color: textData.textColor,
                              ),
                            ),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          final textRect = Rect.fromPoints(
                            textData.position,
                            textData.position.translate(
                                textPainter.width, textPainter.height),
                          );

                          if (textRect.contains(scenePosition)) {
                            setState(() {
                              _isDraggingText = true;
                              _selectedTextIndex = i;
                              _dragStartScenePosition = scenePosition;
                              _originalTextData = textDataList[i];
                            });
                            return;
                          }
                        }
                      },
                      onPanUpdate: (details) {
                        if (!_isDraggingText || _selectedTextIndex == null)
                          return;
                        final currentScenePosition =
                            _transformGlobalToScene(details.globalPosition);
                        final delta =
                            currentScenePosition - _dragStartScenePosition!;
                        setState(() {
                          textDataList[_selectedTextIndex!] =
                              textDataList[_selectedTextIndex!].copyWith(
                            position:
                                textDataList[_selectedTextIndex!].position +
                                    delta,
                          );
                          _dragStartScenePosition = currentScenePosition;
                        });
                      },
                      onPanEnd: (_) {
                        if (_selectedTextIndex != null &&
                            _originalTextData != null) {
                          final newTextData = textDataList[_selectedTextIndex!];
                          if (newTextData.position !=
                              _originalTextData!.position) {
                            actionHistory.add(AppAction(
                              type: ActionType.editText,
                              data: newTextData,
                              previousData: _originalTextData,
                            ));
                            _saveData();
                          }
                        }
                        setState(() {
                          _isDraggingText = false;
                          _selectedTextIndex = null;
                          _originalTextData = null;
                        });
                      },
                      onLongPressStart: (details) {
                        final scenePosition =
                            _transformGlobalToScene(details.globalPosition);
                        for (int i = 0; i < textDataList.length; i++) {
                          final textData = textDataList[i];
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: textData.text,
                              style: TextStyle(
                                fontSize: textData.fontSize,
                                color: textData.textColor,
                              ),
                            ),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          final textRect = Rect.fromPoints(
                            textData.position,
                            textData.position.translate(
                                textPainter.width, textPainter.height),
                          );

                          if (textRect.contains(scenePosition)) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final position = box.localToGlobal(Offset.zero);
                            _showTextContextMenu(context, i,
                                position: details.globalPosition);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                if (selectedLabelType != null &&
                    !isHandwrittenMode &&
                    !isTypingMode &&
                    !isEraserMode &&
                    !isCursorMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        final scenePosition =
                            _transformGlobalToScene(details.globalPosition);
                        _placeLabel(scenePosition);
                      },
                    ),
                  ),
                if (isCursorMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPressStart: (details) {
                        final scenePosition =
                            _transformGlobalToScene(details.globalPosition);
                        LabelData label;
                        for (int i = 0; i < labels.length; i++) {
                          if (labels[i].pageId == currentPageId) {
                            label = labels[i];
                            final labelRect = Rect.fromCenter(
                              center: label.position,
                              width: 80,
                              height: 80,
                            );
                            if (labelRect.contains(scenePosition)) {
                              setState(() => _selectedLabelIndex = i);
                              showContextMenu(
                                  context, i, details.globalPosition);
                              break;
                            }
                          }
                        }
                      },
                    ),
                  ),
                if (isLassoMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) {
                        final globalPosition = details.globalPosition;
                        final scenePosition =
                            _transformGlobalToScene(globalPosition);
                        final adjustedPosition = Offset(
                            globalPosition.dx, globalPosition.dy - topOffset);

                        for (var stroke in strokes.where((s) => s.isSelected)) {
                          if (_isPointOnStroke(scenePosition, stroke, 10.0)) {
                            setState(() {
                              isDraggingStrokes = true;
                              lastDragPosition = scenePosition;
                            });
                            return;
                          }
                        }
                        setState(() {
                          lassoPath = Path()
                            ..moveTo(adjustedPosition.dx, adjustedPosition.dy);
                          lassoPoints = [adjustedPosition];
                        });
                      },
                      onPanUpdate: (details) {
                        final globalPosition = details.globalPosition;
                        final scenePosition =
                            _transformGlobalToScene(globalPosition);
                        final adjustedPosition = Offset(
                            globalPosition.dx, globalPosition.dy - topOffset);
                        if (isDraggingStrokes && lastDragPosition != null) {
                          final delta = scenePosition - lastDragPosition!;
                          setState(() {
                            strokes = strokes.map((stroke) {
                              if (stroke.isSelected) {
                                return Stroke(
                                  points: stroke.points
                                      .map((p) => p + delta)
                                      .toList(),
                                  color: stroke.color,
                                  strokeWidth: stroke.strokeWidth,
                                  isHighlighter: stroke.isHighlighter,
                                  isSelected: stroke.isSelected,
                                );
                              }
                              return stroke;
                            }).toList();
                            lastDragPosition = scenePosition;
                          });
                        } else if (lassoPath != null) {
                          setState(() {
                            lassoPoints!.add(adjustedPosition);
                            lassoPath!.lineTo(
                                adjustedPosition.dx, adjustedPosition.dy);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (isDraggingStrokes) {
                          if (lastDragPosition != null) {
                            final affectedStrokes =
                                strokes.where((s) => s.isSelected).toList();
                            final scenePosition =
                                _transformGlobalToScene(details.globalPosition);
                            final previousStrokes = affectedStrokes
                                .map((s) => Stroke(
                                      points: s.points
                                          .map((p) =>
                                              p -
                                              (scenePosition -
                                                  lastDragPosition!))
                                          .toList(),
                                      color: s.color,
                                      strokeWidth: s.strokeWidth,
                                      isHighlighter: s.isHighlighter,
                                      isSelected: s.isSelected,
                                    ))
                                .toList();
                            setState(() {
                              actionHistory.add(AppAction(
                                type: ActionType.editText,
                                data: affectedStrokes,
                                previousData: previousStrokes,
                              ));
                              _saveData();
                            });
                          }
                          setState(() {
                            isDraggingStrokes = false;
                            lastDragPosition = null;
                          });
                        } else if (lassoPath != null) {
                          setState(() {
                            lassoPath!.close();
                            _selectStrokesInsideLasso();
                            lassoPath = null;
                            lassoPoints = null;
                          });
                        }
                      },
                    ),
                  ),
                if (isLassoMode && lassoPath != null)
                  CustomPaint(
                    painter: LassoPainter(lassoPath!),
                    size: MediaQuery.of(context).size, // Full screen size
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method to your class
  Widget _buildToolbar(List<bool> isSelected_hBar) {
    if (isSelected_hBar[0]) {
      return _buildInsertToolbar();
    } else if (isSelected_hBar[1]) {
      return _buildDrawToolbar();
    } else if (isSelected_hBar[2]) {
      return _buildAccessibilityToolbar();
    } else {
      return Container();
    }
  }

  // **** The word bar Hidden:
  Widget _buildWordToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: const Icon(Icons.format_bold), onPressed: () {}),
        IconButton(icon: const Icon(Icons.format_italic), onPressed: () {}),
        IconButton(icon: const Icon(Icons.format_underline), onPressed: () {}),
        IconButton(icon: const Icon(Icons.subscript), onPressed: () {}),
        IconButton(icon: const Icon(Icons.superscript), onPressed: () {}),
        DropdownButton<double>(
          value: textFontSize,
          dropdownColor: Colors.white,
          items: List.generate(75, (index) => (index + 1).toDouble())
              .map((double value) {
            return DropdownMenuItem<double>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (double? newValue) {
            setState(() {
              textFontSize = newValue!;
              if (_selectedTextIndex != null) {
                TextData previousText = textDataList[_selectedTextIndex!];
                textDataList[_selectedTextIndex!] =
                    textDataList[_selectedTextIndex!].copyWith(
                  fontSize: newValue,
                );
                actionHistory.add(AppAction(
                  type: ActionType.editText,
                  data: textDataList[_selectedTextIndex!],
                  previousData: previousText,
                ));
              }
            });
            _saveData();
          },
        ),
        IconButton(
          icon: Icon(Icons.format_color_text, color: textColor),
          onPressed: () => _showTextSettingsPopup(context),
        ),
        IconButton(icon: const Icon(Icons.format_align_left), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_align_center), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_align_right), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_list_bulleted), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_list_numbered), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_indent_decrease), onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.format_indent_increase), onPressed: () {}),
      ],
    );
  }

  Widget _buildInsertToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: () {
            _pickAndLoadPdf();
          },
        ),
        IconButton(
          color: const Color.fromARGB(255, 0, 131, 225),
          icon: const Icon(Icons.polyline_outlined),
          tooltip: 'Concept Label',
          onPressed: () {
            setState(() {
              selectedLabelType = LabelType.concept;
              isTypingMode = false;
              isHandwrittenMode = false;
              isEraserMode = false;
              _textFieldActive = false;
              if (isLassoMode) {
                isLassoMode = false;
                _clearStrokeSelection();
              }
            });
          },
        ),
        IconButton(
          color: const Color.fromARGB(255, 200, 19, 19),
          icon: const Icon(Icons.question_mark),
          tooltip: 'Question Label',
          onPressed: () {
            setState(() {
              selectedLabelType = LabelType.question;
              isTypingMode = false;
              isHandwrittenMode = false;
              isEraserMode = false;
              _textFieldActive = false;
              if (isLassoMode) {
                isLassoMode = false;
                _clearStrokeSelection();
              }
            });
          },
        ),
        IconButton(
          color: const Color.fromARGB(255, 242, 230, 2),
          icon: const Icon(Icons.star_border_purple500_sharp),
          tooltip: 'Review Label',
          onPressed: () {
            setState(() {
              selectedLabelType = LabelType.review;
              isTypingMode = false;
              isHandwrittenMode = false;
              isEraserMode = false;
              _textFieldActive = false;
              if (isLassoMode) {
                isLassoMode = false;
                _clearStrokeSelection();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDrawToolbar() {
    const Color activeColor = Colors.indigo; // Color when mode is active
    const Color inactiveColor = Colors.black; // Color when mode is inactive
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Center the buttons
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.text_fields_outlined),
                      tooltip: 'Typing Mode',
                      color: isTypingMode ? activeColor : inactiveColor,
                      padding: const EdgeInsets.all(4.0), // Reduced padding
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36), // Tighter constraints
                      onPressed: () => _toggleModes(true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 18), // Small triangle
                      tooltip: 'Text Settings',
                      color: inactiveColor,
                      padding: const EdgeInsets.all(4.0), // Reduced padding
                      constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24), // Even tighter for triangle
                      onPressed: () => _showTextSettingsPopup(context),
                    ),
                  ],
                ),
                IconButton(
                  icon: SizedBox(
                    width: 35,
                    height: 35,
                    child: Image.asset('assets/ImgButton/lassoTool.png'),
                  ),
                  tooltip: 'Lasso Tool',
                  color: isLassoMode ? activeColor : inactiveColor,
                  onPressed: _toggleLassoMode,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: SizedBox(
                        width: 35,
                        height: 35,
                        child: Image.asset('assets/ImgButton/eraser.png'),
                      ),
                      tooltip: 'Eraser',
                      color: isEraserMode ? activeColor : inactiveColor,
                      padding: const EdgeInsets.all(4.0), // Reduced padding
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36), // Tighter constraints
                      onPressed: () {
                        setState(() {
                          isEraserMode = !isEraserMode;
                          selectedLabelType = null;
                          if (isEraserMode) {
                            isHandwrittenMode = true;
                            isTypingMode = false;
                            isCursorMode = false;
                            _textFieldActive =
                                false; // Hide text box when switching to eraser
                            selectedTool = null; // Deselect the current tool
                            if (isLassoMode) {
                              isLassoMode = false;
                              _clearStrokeSelection();
                            }
                          } else {
                            // When turning off eraser mode, don’t automatically enable pen mode
                            isHandwrittenMode = false;
                            selectedTool =
                                null; // Deselect when turning off eraser
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 18), // Small triangle
                      tooltip: 'Eraser Settings',
                      color: inactiveColor,
                      padding: const EdgeInsets.all(4.0), // Reduced padding
                      constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24), // Even tighter for triangle
                      onPressed: () => _showEraserSettingsPopup(context),
                    ),
                  ],
                ),

                IconButton(
                  icon: const Icon(Icons.front_hand),
                  tooltip: 'Cursor Mode',
                  color: isCursorMode ? activeColor : inactiveColor,
                  padding: const EdgeInsets.all(4.0),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _toggleCursorMode,
                ),

                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Pen/Highlighter',
                  color: inactiveColor,
                  onPressed: () =>
                      _showToolConfigDialog(initialIsHighlighter: false),
                ),

                // Dynamic Tool Items with Drag-and-Drop
                ...writingTools.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tool = entry.value;
                  return LongPressDraggable(
                    key: ValueKey(tool.id),
                    data: index,
                    feedback: ToolItem(
                      tool: tool,
                      isSelected: false,
                      onSelect: () {},
                      onEdit: () {},
                      onDelete: () {},
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: ToolItem(
                        tool: tool,
                        isSelected: selectedTool?.id == tool.id,
                        onSelect: () {},
                        onEdit: () {},
                        onDelete: () {},
                      ),
                    ),
                    onDragStarted: () => setState(() => draggedIndex = index),
                    onDragEnd: (_) => setState(() => draggedIndex = null),
                    onDragCompleted: () => draggedIndex = null,
                    child: DragTarget<int>(
                      builder: (context, candidateData, rejectedData) {
                        return ToolItem(
                          tool: tool,
                          isSelected: selectedTool?.id == tool.id,
                          onSelect: () {
                            setState(() {
                              selectedTool = tool;
                              isHandwrittenMode = true;
                              isTypingMode = false;
                              isEraserMode = false;
                              isCursorMode = false;
                              _textFieldActive = false;
                              if (isLassoMode) {
                                isLassoMode = false;
                                _clearStrokeSelection();
                              }
                            });
                          },
                          onEdit: () =>
                              _showToolConfigDialog(existingTool: tool),
                          onDelete: () => _showDeleteDialog(tool),
                        );
                      },
                      onAcceptWithDetails: (details) =>
                          _handleToolReorder(details.data, index),
                    ),
                  );
                }).toList(),
              ],
            ),
          ));
    });
  }

  Widget _buildAccessibilityToolbar() {
    bool isDark = false; // For Dark and Light theme switching button
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 50,
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 52, 50, 50),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () {
            _transformationController.value =
                Matrix4.identity(); // Reset zoom/pan
          },
          child: const Row(
            children: [
              Icon(Icons.arrow_upward),
              SizedBox(width: 5),
              Text('BACK TO TOP'),
            ],
          ),
        ),
        SizedBox(
          width: 1,
        ),
      ],
    );
  }

  List<Widget> _buildToolItems() {
    return writingTools.asMap().entries.map((entry) {
      final index = entry.key;
      final tool = entry.value;
      return LongPressDraggable(
        key: ValueKey(tool.id),
        data: index,
        feedback: ToolItem(
          tool: tool,
          isSelected: false,
          onSelect: () {},
          onEdit: () {},
          onDelete: () {},
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: ToolItem(
            tool: tool,
            isSelected: selectedTool?.id == tool.id,
            onSelect: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
        onDragStarted: () => setState(() => draggedIndex = index),
        onDragEnd: (_) => setState(() => draggedIndex = null),
        onDragCompleted: () => draggedIndex = null,
        child: DragTarget<int>(
          builder: (context, candidateData, rejectedData) {
            return ToolItem(
              tool: tool,
              isSelected: selectedTool?.id == tool.id,
              onSelect: () {
                setState(() => selectedTool = tool);
              },
              onEdit: () => _showToolConfigDialog(existingTool: tool),
              onDelete: () => _showDeleteDialog(tool),
            );
          },
          onAcceptWithDetails: (details) =>
              _handleToolReorder(details.data, index),
        ),
      );
    }).toList();
  }

  void _handleToolReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final tool = writingTools.removeAt(oldIndex);
      writingTools.insert(newIndex, tool);
    });
  }

  void _showDeleteDialog(WritingTool tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete ${tool.isHighlighter ? 'Highlighter' : 'Pen'}'),
        content: Text(
            'Are you sure to delete this ${tool.isHighlighter ? 'highlighter' : 'pen'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                writingTools.removeWhere((t) => t.id == tool.id);
                if (selectedTool?.id == tool.id) {
                  selectedTool =
                      writingTools.isNotEmpty ? writingTools.first : null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _placeLabel(Offset scenePosition) async {
    if (selectedLabelType == null ||
        currentPageId == null ||
        currentSectionId == null ||
        currentNotebookId == null ||
        isHandwrittenMode ||
        isTypingMode ||
        isEraserMode) {
      return;
    }
    // Show pop up window to add label information and store data:
    final newLabel = Label(
      labelType: selectedLabelType!,
      position: scenePosition,
      pageId: currentPageId!,
      sectionId: currentSectionId!,
      notebookId: currentNotebookId!,
    );
    final insertedLabel = await newLabel.showPopup(context);
    if (insertedLabel != null) {
      setState(() {
        labels.add(insertedLabel);
        actionHistory.add(AppAction(
          type: ActionType.addLabel,
          data: insertedLabel,
        ));
        print('Undo action length: ${actionHistory.length}');
        print('Added label: $insertedLabel');
      });
    } else {
      print('Label creation canceled or failed');
    }
  }

  void _clearData() async {
    if (currentPageId != null) {
      // Ensure a page is selected
      await _storageService.clearNoteData(currentPageId!); // Pass currentPageId
      setState(() {
        strokes.clear();
        textDataList.clear();
        actionHistory.clear(); // Clear action history on clear data

        writingTools = [
          WritingTool(
            id: 'default_pen',
            color: Colors.black,
            thickness: 4.0,
            isDefault: true,
          ),
        ];
        selectedTool = writingTools.first;
        savedPdf = null; // Clear any PDF data
        isPdfLoaded = false; // Reset PDF loaded state
        // clear all the label data:
        for (var label in labels) {
          LabelManager.instance.delete(label.toMap());
        }
        labels.clear();
      });
    }
  }

  void showContextMenu(BuildContext context, int index, Offset position) async {
    final label = labels[index];
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox viewerBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Matrix4 transform = _transformationController.value;
    final scale = transform.getMaxScaleOnAxis();
    final labelLocal = viewerBox.localToGlobal(Offset(
      label.position.dx * scale + transform.getTranslation().x,
      label.position.dy * scale + transform.getTranslation().y,
    ));

    final RelativeRect positionRelativeRect = RelativeRect.fromRect(
      Rect.fromPoints(position, position.translate(1, 1)),
      Offset.zero & overlay.size,
    );

    final String? result = await showMenu<String>(
      color: const Color.fromARGB(255, 237, 236, 236),
      context: context,
      position: positionRelativeRect,
      items: _labelOptions[label.labelType]!.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
    );

    if (result == 'Delete') {
      _showDeleteLabelDialog(index, label.labelType);
    } else if (result == "Create Relation") {
      List<Notebook> tempNotebookList = await fetchNotebooks();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddRelationDialog(
            notebooks: tempNotebookList,
            selectedIteminMenu: label,
          );
        },
      ); // This triggers the prompt to select which item to relate with
    } else if (result == 'Show More') {
      // Show label information When user click show more:
      // Check if the widget is still mounted before using the context:
      if (!context.mounted) {
        return;
      }
      // Show the dialog to display label information:
      // Get the updated label:
      Map<String, dynamic>? updatedLabel =
          await LabelManager.instance.getDataById(label.id);
      ShowLabel(labelItem: updatedLabel).showPopup(context);
    }
  }

  void _showDeleteLabelDialog(int index, LabelType type) {
    String labelName = '';
    switch (type) {
      case LabelType.concept:
        labelName = 'relation label';
        break;
      case LabelType.question:
        labelName = 'question label';
        break;
      case LabelType.review:
        labelName = 'review label';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete $labelName'),
        content: Text('Are you sure to delete this $labelName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              // Initialize removedLabel before setState
              final LabelData removedLabel = labels[index];
              setState(() {
                labels.removeAt(index);
                actionHistory.add(AppAction(
                  type: ActionType.addLabel, // For undo: re-add the label
                  data: removedLabel,
                ));
              });
              Navigator.pop(context);
              // Delete label from database:
              LabelManager.instance.delete(removedLabel.toMap());
            },
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTextContextMenu(BuildContext context, int index,
      {required Offset position}) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect positionRelativeRect = RelativeRect.fromRect(
      Rect.fromPoints(position, position.translate(1, 1)),
      Offset.zero & overlay.size,
    );

    showMenu(
      color: const Color.fromARGB(255, 237, 236, 236),
      context: context,
      position: positionRelativeRect,
      items: [
        PopupMenuItem(
          child: const Text('Edit Text'),
          onTap: () {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _editText(index);
            });
          },
        ),
        PopupMenuItem(
          child: const Text('Format Text'),
          onTap: () {
            setState(() => _selectedTextIndex = index);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              textColor = textDataList[index].textColor;
              textFontSize = textDataList[index].fontSize;
              _showTextSettingsPopup(context);
            });
          },
        ),
      ],
    );
  }

  Offset _transformGlobalToScene(Offset globalPosition) {
    final RenderBox renderBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Matrix4 transform = _transformationController.value;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    final double translateX = transform.getTranslation().x;
    final double translateY = transform.getTranslation().y;
    final double scale = transform.getMaxScaleOnAxis();
    return Offset(
      (localPosition.dx - translateX) / scale,
      (localPosition.dy - translateY) / scale,
    );
  }

  void _toggleLassoMode() {
    setState(() {
      isLassoMode = !isLassoMode;
      if (isLassoMode) {
        isHandwrittenMode = false;
        isTypingMode = false;
        isEraserMode = false;
        isCursorMode = false;
        selectedLabelType = null;
        _textFieldActive = false;
        selectedTool = null; // Deselect the current tool in lasso mode
        // Clear any active text input
        if (_textController.text.isNotEmpty) {
          _saveText();
        }
      } else {
        _clearStrokeSelection(); // Clear selection when exiting lasso mode
      }
    });
  }

  void _selectStrokesInsideLasso() {
    if (lassoPath == null || lassoPoints == null) return;
    setState(() {
      // Convert lassoPath from screen to scene coordinates

      final Path sceneLassoPath = Path();
      final renderBox =
          _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
      for (var i = 0; i < lassoPoints!.length; i++) {
        final globalPoint = lassoPoints![i];
        // Convert screen to local coordinates relative to InteractiveViewer
        final localPoint = renderBox.globalToLocal(globalPoint);
        // Convert local to scene coordinates
        final scenePoint = _transformationController.toScene(localPoint);
        print("Lasso point $i: Screen $localPoint -> Scene $scenePoint");
        if (i == 0) {
          sceneLassoPath.moveTo(scenePoint.dx, scenePoint.dy);
        } else {
          sceneLassoPath.lineTo(scenePoint.dx, scenePoint.dy);
        }
      }
      sceneLassoPath.close();
      print("Scene lasso bounds: ${sceneLassoPath.getBounds()}");

      // Debug stroke positions
      if (strokes.isNotEmpty) {
        print("First stroke first point: ${strokes.first.points.first}");
      }

      for (var stroke in strokes) {
        stroke.isSelected = _isStrokeInside(stroke, sceneLassoPath);
        print("Selected stroke with points: ${stroke.points.first}");
      }
      // Add to action history for undo support
      List<Stroke> affectedStrokes =
          strokes.where((s) => s.isSelected).toList();
      if (affectedStrokes.isNotEmpty) {
        actionHistory.add(AppAction(
          type: ActionType
              .addStroke, // Using addStroke to represent selection change
          data: affectedStrokes,
          previousData: strokes
              .map((s) => Stroke(
                    points: List.from(s.points),
                    color: s.color,
                    strokeWidth: s.strokeWidth,
                    isHighlighter: s.isHighlighter,
                    isSelected: false, // Previous state before selection
                  ))
              .toList(),
        ));
      } else {
        print("No strokes selected");
      }
    });
    _saveData();
  }

  bool _isStrokeInside(Stroke stroke, Path lasso) {
    // Sample points along the stroke and check if all are inside the lasso
    return stroke.points.every((point) => lasso.contains(point));
  }

  bool _isPointOnStroke(Offset point, Stroke stroke, double threshold) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i];
      final b = stroke.points[i + 1];
      if (_distanceToSegment(point, a, b) < threshold) {
        return true;
      }
    }
    return false;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = Offset(b.dx - a.dx, b.dy - a.dy); // Vector from a to b
    final ap = Offset(p.dx - a.dx, p.dy - a.dy); // Vector from a to p
    final abLengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;

    // Handle case where a and b are the same point
    if (abLengthSquared == 0) return ap.distance;

    // Project ap onto ab, clamp t between 0 and 1
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLengthSquared;
    t = t.clamp(0.0, 1.0);

    // Calculate the closest point on the segment
    final closest = Offset(
      a.dx + t * ab.dx,
      a.dy + t * ab.dy,
    );

    // Return distance from p to closest point
    return (p - closest).distance;
  }

  void _clearStrokeSelection() {
    setState(() {
      for (var stroke in strokes) {
        stroke.isSelected = false;
      }
    });
  }

  void _centerOnPosition(Offset position) {
    _transformationController.value = Matrix4.identity(); // Reset zoom/pan

    final viewerBox =
        _interactiveViewerKey.currentContext!.findRenderObject() as RenderBox;
    final viewerWidth = viewerBox.size.width;
    final viewerHeight = viewerBox.size.height;
    final currentMatrix = _transformationController.value;
    final scale = currentMatrix.getMaxScaleOnAxis(); // Get the current scale
    final translateX = currentMatrix.getTranslation().x;
    final translateY = currentMatrix.getTranslation().y;
    final centerX = viewerWidth / 2;
    final centerY = viewerHeight / 2;
    // Calculate the position in the scene coordinates
    final sceneX = position.dx * scale + translateX;
    final sceneY = position.dy * scale + translateY;

    // Calculate the new translation to center the label
    final newTranslateX = centerX - sceneX;
    final newTranslateY = centerY - sceneY;

    // Apply the new transformation
    _transformationController.value = Matrix4.identity()
      ..translate(newTranslateX, newTranslateY)
      ..scale(scale);
  }
}

Color _getLabelColor(LabelData label) {
  if (label.labelType == LabelType.question) {
    return Colors.red;
  } else if (label.labelType == LabelType.concept) {
    return Colors.blue;
  } else {
    return Colors.yellow;
  }
}

class LassoPainter extends CustomPainter {
  final Path path;

  LassoPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
