enum RecurrenceType { none, daily, weekly, monthly, yearly }

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final String? category;
  final bool reminderEnabled;
  final bool isCompleted;
  final String userId;
  final String? location;
  final RecurrenceType recurrenceType;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    this.category,
    this.reminderEnabled = true,
    this.isCompleted = false,
    required this.userId,
    this.location,
    this.recurrenceType = RecurrenceType.none,
  });

  DateTime? get reminderTime => reminderEnabled ? dateTime.subtract(const Duration(hours: 1)) : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
      'category': category,
      'reminderEnabled': reminderEnabled,
      'isCompleted': isCompleted,
      'userId': userId,
      'location': location,
      'recurrenceType': recurrenceType.index,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      description: map['description'],
      category: map['category'],
      reminderEnabled: map['reminderEnabled'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      location: map['location'],
      recurrenceType: RecurrenceType.values[map['recurrenceType'] ?? 0],
    );
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? description,
    String? category,
    bool? reminderEnabled,
    bool? isCompleted,
    String? userId,
    String? location,
    RecurrenceType? recurrenceType,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      recurrenceType: recurrenceType ?? this.recurrenceType,
    );
  }
}
