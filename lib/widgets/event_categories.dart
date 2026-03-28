import 'package:flutter/material.dart';

class EventCategory {
  final String name;
  final IconData icon;
  final Color color;

  const EventCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class EventCategories {
  static const List<EventCategory> categories = [
    EventCategory(
      name: 'Work',
      icon: Icons.work_outline,
      color: Color(0xFF1A73E8),
    ),
    EventCategory(
      name: 'Personal',
      icon: Icons.person_outline,
      color: Color(0xFF34A853),
    ),
    EventCategory(
      name: 'Health',
      icon: Icons.favorite_outline,
      color: Color(0xFFEA4335),
    ),
    EventCategory(
      name: 'Social',
      icon: Icons.people_outline,
      color: Color(0xFF9334E6),
    ),
    EventCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFFBBC04),
    ),
    EventCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF5F6368),
    ),
  ];

  static Color getColorForCategory(String category) {
    return categories
        .firstWhere(
          (c) => c.name.toLowerCase() == category.toLowerCase(),
          orElse: () => categories.last,
        )
        .color;
  }
}
