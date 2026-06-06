//This file is to handle file-based storage for each page
//This service saves and loads page data to/from JSON files named by pageId (e.g., page_N1S1P1.json)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PageStorageService {
  Future<String> _getPageFilePath(String pageId) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/page_$pageId.json';
  }

  Future<void> savePageData(String pageId, Map<String, dynamic> data) async {
    final filePath = await _getPageFilePath(pageId);
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>> loadPageData(String pageId) async {
    final filePath = await _getPageFilePath(pageId);
    final file = File(filePath);
    if (await file.exists()) {
      final dataString = await file.readAsString();
      return jsonDecode(dataString);
    }
    return {
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
    };
  }

  Future<void> deletePageData(String pageId) async {
    final filePath = await _getPageFilePath(pageId);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearNoteData(String pageId) async {
    final filePath = await _getPageFilePath(pageId);
    final file = File(filePath);
    if (await file.exists()) {
      // Overwrite the file with default empty data
      await file.writeAsString(jsonEncode({
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
      }));
    }
  }
}
