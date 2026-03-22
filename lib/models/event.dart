class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final String? category;
  final bool reminderEnabled;
  final String userId;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    this.category,
    this.reminderEnabled = true,
    required this.userId,
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
      'userId': userId,
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
      userId: map['userId'] ?? '',
    );
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? description,
    String? category,
    bool? reminderEnabled,
    String? userId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      userId: userId ?? this.userId,
    );
  }
}
