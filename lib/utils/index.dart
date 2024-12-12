import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_app/classed/task.dart';
import 'package:todolist_app/utils/enum/enum.dart';

String iconToString(IconData icon) => icon.codePoint.toString();
IconData stringToIcon(String iconString) =>
    IconData(int.parse(iconString), fontFamily: 'MaterialIcons');
String colorToString(Color color) => color.value.toString();
Color stringToColor(String colorString) => Color(int.parse(colorString));

ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1024) return ScreenType.desktop;
  if (width >= 600) return ScreenType.tablet;
  return ScreenType.mobile;
}

Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('locale', locale.languageCode);
}

Future<Locale> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('locale') ?? 'en';
  return Locale(languageCode);
}

TimeOfDay parseTimeOfDay(String timeString) {
  final RegExp timeFormat = RegExp(r'(\d+):(\d+)([APMapm]{2})');
  final match = timeFormat.firstMatch(timeString);

  if (match != null) {
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();

    int adjustedHour = hour;
    if (period == 'PM' && hour != 12) {
      adjustedHour += 12;
    } else if (period == 'AM' && hour == 12) {
      adjustedHour = 0;
    }

    return TimeOfDay(hour: adjustedHour, minute: minute);
  }

  return TimeOfDay.now();
}

void sortTasksByStatus(List<Task> tasks) {
  tasks.sort((a, b) => a.status.index.compareTo(b.status.index));
}

void sortTasksByUpdateTime(List<Task> tasks) {
  tasks.sort((a, b) {
    final aUpdatedAt = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bUpdatedAt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bUpdatedAt.compareTo(aUpdatedAt);
  });
}

int getGridColumnCount(BuildContext context) {
  final screenType = getScreenType(context);

  switch (screenType) {
    case ScreenType.desktop:
      return 12;
    case ScreenType.tablet:
      return 8;
    case ScreenType.mobile:
      return 4;
    default:
      return 4;
  }
}
