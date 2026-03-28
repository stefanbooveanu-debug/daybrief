import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/models/event.dart';
import 'package:day_brief/providers/auth_provider.dart';
import 'package:day_brief/theme/app_theme.dart';

void main() {
  group('AuthProvider Tests', () {
    test('initial state is not authenticated', () {
      final provider = AuthProvider();
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.error, null);
    });

    test('signIn with valid credentials succeeds', () async {
      final provider = AuthProvider();
      final result = await provider.signIn('test@example.com', 'password123');
      
      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(provider.isLoading, false);
    });

    test('signIn with empty fields fails', () async {
      final provider = AuthProvider();
      final result = await provider.signIn('', '');
      
      expect(result, false);
      expect(provider.error, 'Please enter email and password');
      expect(provider.isAuthenticated, false);
    });

    test('signUp with invalid email fails', () async {
      final provider = AuthProvider();
      final result = await provider.signUp('invalid', 'password123', 'John', 'Doe');
      
      expect(result, false);
      expect(provider.error, 'Please enter a valid email');
    });

    test('signUp with short password fails', () async {
      final provider = AuthProvider();
      final result = await provider.signUp('test@example.com', '123', 'John', 'Doe');
      
      expect(result, false);
      expect(provider.error, 'Password must be at least 6 characters');
    });

    test('clearError clears error state', () async {
      final provider = AuthProvider();
      await provider.signIn('', '');
      expect(provider.error, isNotNull);
      
      provider.clearError();
      expect(provider.error, null);
    });
  });

  group('Event Model Tests', () {
    test('Event can be created with required fields', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        dateTime: DateTime(2024, 1, 15, 10, 30),
        category: 'Work',
        userId: 'user1',
      );
      
      expect(event.title, 'Test Event');
      expect(event.category, 'Work');
      expect(event.id, '1');
    });

    test('Event copyWith creates modified copy', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        dateTime: DateTime(2024, 1, 15, 10, 30),
        category: 'Work',
        userId: 'user1',
      );
      
      final modified = event.copyWith(isCompleted: true);
      
      expect(modified.title, 'Test Event');
      expect(modified.isCompleted, true);
      expect(event.isCompleted, false);
    });
  });

  group('AppTheme Tests', () {
    test('light theme has correct primary color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('dark theme has dark brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('AppColors Tests', () {
    test('getCategoryColor returns correct color', () {
      expect(AppColors.getCategoryColor('Work'), const Color(0xFF1A73E8));
      expect(AppColors.getCategoryColor('Personal'), const Color(0xFF34A853));
      expect(AppColors.getCategoryColor('Health'), const Color(0xFFEA4335));
      expect(AppColors.getCategoryColor('NonExistent'), AppColors.defaultCategoryColors['Other']);
    });

    test('getCategoryIcon returns correct icon', () {
      expect(AppColors.getCategoryIcon('Work'), Icons.work_outline);
      expect(AppColors.getCategoryIcon('Personal'), Icons.person_outline);
      expect(AppColors.getCategoryIcon('Health'), Icons.favorite_outline);
    });
  });
}
