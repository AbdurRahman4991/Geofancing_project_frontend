// class DateHelper {
//   static String formatDate(String? dateTime) {
//     if (dateTime == null || dateTime.isEmpty) return '-';
//     try {
//       final dt = DateTime.parse(dateTime);
//       final day = dt.day.toString().padLeft(2, '0');
//       final month = dt.month.toString().padLeft(2, '0');
//       final year = dt.year.toString();
//       final hour = dt.hour.toString().padLeft(2, '0');
//       final minute = dt.minute.toString().padLeft(2, '0');
//       final second = dt.second.toString().padLeft(2, '0');

//       return "$day/$month/$year Time $hour:$minute:$second";
//     } catch (e) {
//       return '-';
//     }
//   }
// }
import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      // Parse incoming UTC datetime
      DateTime utcDate = DateTime.parse(dateTime);

      // ✅ Convert to device local time (Bangladesh automatically if device timezone is set)
      DateTime localDate = utcDate.toLocal();

      // ✅ Format to dd/MM/yyyy hh:mm:ss a (12-hour + AM/PM)
      final formattedDate = DateFormat('dd/MM/yyyy hh:mm:ss a').format(localDate);

      return formattedDate;
    } catch (e) {
      return '-';
    }
  }
}

