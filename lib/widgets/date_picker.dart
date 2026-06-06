import 'package:flutter/material.dart';

class DatePicker {
  Future<DateTime?> selectDate(BuildContext context, bool readOnly) async {
    // Get the seleted date and call the Date Picker:
    return readOnly
        ? null
        : await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            // Range of calendar days：
            firstDate: DateTime.now().subtract(
              Duration(days: 365 * 30),
            ), // 30 years before today
            lastDate: DateTime.now().add(
              Duration(days: 365 * 30),
            ), // 30 years after today
            builder: (BuildContext context, Widget? child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    // Header background color:
                    primary: const Color.fromARGB(255, 91, 90, 90),
                    // Header text color
                    onPrimary: Colors.white,
                    // Background color
                    surface: Colors.white,
                    // text color:
                    onSurface: Colors.black,
                  ),
                  // button text color:
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      textStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
  }
}
