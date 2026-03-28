enum CalendarType { work, personal, family }

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final String userId;
  final CalendarType calendarType;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    required this.userId,
    this.calendarType = CalendarType.personal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
      'userId': userId,
      'calendarType': calendarType.name,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      description: map['description'],
      userId: map['userId'] ?? '',
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
    String? userId,
    CalendarType? calendarType,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      calendarType: calendarType ?? this.calendarType,
    );
  }
}
