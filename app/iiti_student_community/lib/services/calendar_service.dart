import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:iiti_student_community/models/event.dart' as EventInternal;

class CalendarService {
  static Future<void> addEventToCalendar(EventInternal.Event event) async {
    try {
      final calendarEvent = Event(
        title: event.name,
        description:
            event.description ?? 'Event organized by ${event.organizerName}',
        location: event.location,
        startDate: event.dateTime,
        endDate: event.dateTime.add(const Duration(hours: 2)),
        iosParams: const IOSParams(reminder: Duration(hours: 1)),
        androidParams: const AndroidParams(emailInvites: []),
      );

      await Add2Calendar.addEvent2Cal(calendarEvent);
    } catch (e) {
      print('Error adding to calendar: $e');
      rethrow;
    }
  }
}
