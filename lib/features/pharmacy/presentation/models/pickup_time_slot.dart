/// Model for pickup time slots
class PickupTimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? expressLane;

  PickupTimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.expressLane,
  });

  String get displayTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String get displayRange {
    final startHour = startTime.hour;
    final startMinute = startTime.minute;
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final startDisplayHour = startHour > 12
        ? startHour - 12
        : (startHour == 0 ? 12 : startHour);

    final endHour = endTime.hour;
    final endMinute = endTime.minute;
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final endDisplayHour = endHour > 12
        ? endHour - 12
        : (endHour == 0 ? 12 : endHour);

    return '${startDisplayHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} $startPeriod - ${endDisplayHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';
  }

  bool isInSlot(DateTime time) {
    return time.isAfter(startTime) && time.isBefore(endTime);
  }
}
