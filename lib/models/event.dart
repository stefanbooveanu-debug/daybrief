enum RecurrenceType { none, daily, weekly, monthly, yearly }

enum CalendarType { work, personal, family }

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final String? category;
  final String? location;
  final bool reminderEnabled;
  final bool isCompleted;
  final String userId;
  final RecurrenceType recurrenceType;
  final int? recurrenceEndAfter;
  final CalendarType calendarType;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    this.category,
    this.location,
    this.reminderEnabled = true,
    this.isCompleted = false,
    required this.userId,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceEndAfter,
    this.calendarType = CalendarType.personal,
  });

  DateTime? get reminderTime => reminderEnabled ? dateTime.subtract(const Duration(hours: 1)) : null;

  List<DateTime> getOccurrences({int maxCount = 30}) {
    if (recurrenceType == RecurrenceType.none) return [dateTime];
    
    final occurrences = <DateTime>[dateTime];
    var current = dateTime;
    
    for (int i = 1; i < (recurrenceEndAfter ?? maxCount); i++) {
      switch (recurrenceType) {
        case RecurrenceType.daily:
          current = current.add(const Duration(days: 1));
          break;
        case RecurrenceType.weekly:
          current = current.add(const Duration(days: 7));
          break;
        case RecurrenceType.monthly:
          current = DateTime(current.year, current.month + 1, current.day, current.hour, current.minute);
          break;
        case RecurrenceType.yearly:
          current = DateTime(current.year + 1, current.month, current.day, current.hour, current.minute);
          break;
        case RecurrenceType.none:
          break;
      }
      occurrences.add(current);
    }
    return occurrences;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
      'category': category,
      'location': location,
      'reminderEnabled': reminderEnabled,
      'isCompleted': isCompleted,
      'userId': userId,
      'recurrenceType': recurrenceType.index,
      'recurrenceEndAfter': recurrenceEndAfter,
      'calendarType': calendarType.name,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      description: map['description'],
      category: map['category'],
      location: map['location'],
      reminderEnabled: map['reminderEnabled'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      recurrenceType: RecurrenceType.values[map['recurrenceType'] ?? 0],
      recurrenceEndAfter: map['recurrenceEndAfter'],
      calendarType: CalendarType.values.firstWhere(
        (e) => e.name == map['calendarType'],
        orElse: () => CalendarType.personal,
      ),
    );
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? description,
    String? category,
    String? location,
    bool? reminderEnabled,
    bool? isCompleted,
    String? userId,
    RecurrenceType? recurrenceType,
    int? recurrenceEndAfter,
    CalendarType? calendarType,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndAfter: recurrenceEndAfter ?? this.recurrenceEndAfter,
      calendarType: calendarType ?? this.calendarType,
    );
  }
}
