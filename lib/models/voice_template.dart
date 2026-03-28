class VoiceTemplate {
  final String id;
  final String name;
  final String phrase;
  final String? category;
  final String? defaultTime;
  final bool isCustom;

  VoiceTemplate({
    required this.id,
    required this.name,
    required this.phrase,
    this.category,
    this.defaultTime,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phrase': phrase,
      'category': category,
      'defaultTime': defaultTime,
      'isCustom': isCustom,
    };
  }

  factory VoiceTemplate.fromMap(Map<String, dynamic> map) {
    return VoiceTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phrase: map['phrase'] ?? '',
      category: map['category'],
      defaultTime: map['defaultTime'],
      isCustom: map['isCustom'] ?? false,
    );
  }

  VoiceTemplate copyWith({
    String? id,
    String? name,
    String? phrase,
    String? category,
    String? defaultTime,
    bool? isCustom,
  }) {
    return VoiceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      phrase: phrase ?? this.phrase,
      category: category ?? this.category,
      defaultTime: defaultTime ?? this.defaultTime,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  static List<VoiceTemplate> get defaultTemplates => [
    VoiceTemplate(
      id: '1',
      name: 'Quick Meeting',
      phrase: 'schedule meeting',
      category: 'Work',
      defaultTime: '10:00',
    ),
    VoiceTemplate(
      id: '2',
      name: 'Gym Time',
      phrase: 'workout',
      category: 'Health',
      defaultTime: '18:00',
    ),
    VoiceTemplate(
      id: '3',
      name: 'Lunch Break',
      phrase: 'lunch',
      category: 'Personal',
      defaultTime: '12:00',
    ),
    VoiceTemplate(
      id: '4',
      name: 'Doctor Visit',
      phrase: 'doctor',
      category: 'Health',
      defaultTime: '09:00',
    ),
    VoiceTemplate(
      id: '5',
      name: 'Team Standup',
      phrase: 'standup',
      category: 'Work',
      defaultTime: '09:00',
    ),
    VoiceTemplate(
      id: '6',
      name: 'Coffee Break',
      phrase: 'coffee',
      category: 'Personal',
      defaultTime: '14:30',
    ),
    VoiceTemplate(
      id: '7',
      name: 'Grocery Shopping',
      phrase: 'shopping',
      category: 'Shopping',
      defaultTime: '17:00',
    ),
    VoiceTemplate(
      id: '8',
      name: 'Birthday',
      phrase: 'birthday',
      category: 'Social',
      defaultTime: '12:00',
    ),
  ];
}
