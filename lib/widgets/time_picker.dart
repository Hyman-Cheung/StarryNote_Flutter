import 'package:flutter/material.dart';

class TimePicker {
  Future<TimeOfDay?> selectTime(BuildContext context, bool readOnly) async {
    // Get the seleted time and call the Time Picker:
    return readOnly
        ? null
        : await showTimePicker(
            context: context,
            // Set the initial time on the Time Picker
            initialTime: TimeOfDay.now(),
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
                  timePickerTheme: TimePickerThemeData(
                    // dial hand color:
                    dialHandColor: Colors.black12,
                    // dial background color：
                    dialBackgroundColor: Colors.white,
                    // dial text color：
                    dialTextColor: Colors.black,

                    // color for AM/PM buttons:
                    dayPeriodColor: WidgetStateColor.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.indigo;
                      } else if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return Colors.indigoAccent; // Custom color when focused
                      } else {
                        return Colors.white;
                      }
                    }),
                    // Text color for AM/PM buttons:
                    dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      } else if (states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)) {
                        return Colors.white; // Custom color when focused
                      } else {
                        return Colors.black;
                      }
                    }),
                    // Border of AM/PM buttons:
                    dayPeriodShape: RoundedRectangleBorder(
                      //Border radius of AM/PM buttons
                      borderRadius: BorderRadius.circular(8.0),
                      //Border color of AM/PM buttons
                      side: BorderSide(color: Colors.black),
                    ),
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
