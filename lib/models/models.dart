import 'package:flutter/material.dart';

enum ActionType {
  addLabel,
  addText,
  editText,
  addStroke,
  eraseStroke,
  deleteText,
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;
  bool isSelected;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isHighlighter,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': color.value,
        'strokeWidth': strokeWidth,
        'isHighlighter': isHighlighter,
        'isSelected': isSelected,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        points: (json['points'] as List)
            .map((p) => Offset(p['dx'], p['dy']))
            .toList(),
        color: Color(json['color']),
        strokeWidth: json['strokeWidth'],
        isHighlighter: json['isHighlighter'],
        isSelected: json['isSelected'] ?? false,
      );
}

class TextData {
  final String text;
  final Offset position;
  final Color textColor;
  final double fontSize;

  TextData({
    required this.text,
    required this.position,
    required this.textColor,
    required this.fontSize,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'position': {'dx': position.dx, 'dy': position.dy},
        'textColor': textColor.value,
        'fontSize': fontSize,
      };

  factory TextData.fromJson(Map<String, dynamic> json) => TextData(
        text: json['text'],
        position: Offset(json['position']['dx'], json['position']['dy']),
        textColor: Color(json['textColor']),
        fontSize: json['fontSize'],
      );

  TextData copyWith({
    String? text,
    Offset? position,
    Color? textColor,
    double? fontSize,
  }) {
    return TextData(
      text: text ?? this.text,
      position: position ?? this.position,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class WritingTool {
  final String id;
  final Color color;
  final double thickness;
  final bool isHighlighter;
  final bool isDefault;

  WritingTool({
    required this.id,
    required this.color,
    this.thickness = 4.0,
    this.isHighlighter = false,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.value,
        'thickness': thickness,
        'isHighlighter': isHighlighter,
        'isDefault': isDefault,
      };

  factory WritingTool.fromJson(Map<String, dynamic> json) => WritingTool(
        id: json['id'],
        color: Color(json['color']),
        thickness: json['thickness'],
        isHighlighter: json['isHighlighter'],
        isDefault: json['isDefault'] ?? false,
      );
}

class AppAction {
  final ActionType type;
  final dynamic data;
  final dynamic previousData;
  final dynamic additionalData;

  AppAction({
    required this.type,
    required this.data,
    this.previousData,
    this.additionalData,
  });
}

class PdfData {
  final String pdfPath;
  int totalPages = 0;
  List<int> pdfPageList; // pdf page list
  bool isPdfRendered = false;

  PdfData({
    required this.pdfPath,
    required this.totalPages,
    required this.pdfPageList,
    required this.isPdfRendered,
  });

  Map<String, dynamic> toJson() => {
        'pdfPath': pdfPath,
        'totalPages': totalPages,
        'pdfPageList': pdfPageList, // Store as a list of integers
        'isPdfRendered': isPdfRendered,
      };

  factory PdfData.fromJson(Map<String, dynamic> json) => PdfData(
        pdfPath: json["pdfPath"],
        totalPages: json["totalPages"],
        pdfPageList: List<int>.from(json["pdfPageList"].map((x) => x)),
        isPdfRendered: json["isPdfRendered"],
      );
}
