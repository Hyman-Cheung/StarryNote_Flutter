import 'package:flutter/material.dart';

Future<void> showPdfPageContextMenu(
    BuildContext context,
    int pageIndex,
    List<int> pdfPageList,
    Function deletePdf,
    Function saveData,
    Function refreshUI,
    Offset position) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  // Adjusting for the exact position of the long press
  final localPosition = position;
  final RelativeRect positionRelativeRect = RelativeRect.fromRect(
    Rect.fromPoints(localPosition,
        localPosition.translate(1, 1)), // Position it at the top-left corner
    Offset.zero & overlay.size,
  );

  debugPrint("$pageIndex");

  final String? result = await showMenu<String>(
    context: context,
    position: positionRelativeRect,
    color: const Color.fromARGB(255, 255, 255, 255),
    items: [
      PopupMenuItem<String>(
        value: 'delete_pdf',
        child: const Text('Delete PDF'),
      ),
      PopupMenuItem<String>(
        value: 'delete_page',
        child: const Text('Delete Page'),
      ),
    ],
  );

  if (result == 'delete_pdf') {
    deletePdf();
  } else if (result == 'delete_page') {
    _deletePage(pageIndex, pdfPageList, deletePdf, saveData, refreshUI);
  }
}

void _deletePage(int pageIndex, List<int> pdfPageList, Function deletePdf,
    Function saveData, Function refreshUI) {
  debugPrint("before: $pdfPageList");
  if (pdfPageList.isNotEmpty && pageIndex < pdfPageList.length) {
    pdfPageList.removeAt(pageIndex); // Remove the specific page
    if (pdfPageList.isEmpty) {
      deletePdf();
    }
  }
  saveData();
  refreshUI();
  debugPrint("after: $pdfPageList");
}
