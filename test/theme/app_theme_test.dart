import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/models/event.dart';
import 'package:day_brief/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('defaultCategoryColors has the 6 canonical categories', () {
      expect(AppColors.defaultCategoryColors.keys.toSet(), {
        EventCategory.work,
        EventCategory.personal,
        EventCategory.health,
        EventCategory.social,
        EventCategory.shopping,
        EventCategory.other,
      });
    });

    test('getCategoryColor returns the matching color', () {
      expect(
        AppColors.getCategoryColor(EventCategory.work),
        AppColors.defaultCategoryColors[EventCategory.work],
      );
      expect(
        AppColors.getCategoryColor(EventCategory.health),
        AppColors.defaultCategoryColors[EventCategory.health],
      );
    });

    test('getCategoryColor falls back to other for unknown via enum', () {
      expect(
        AppColors.colorForCategory(null),
        AppColors.defaultCategoryColors[EventCategory.other],
      );
    });

    group('getCategoryIcon', () {
      test('returns the right icon per category', () {
        expect(
            AppColors.getCategoryIcon(EventCategory.work), Icons.work_outline);
        expect(AppColors.getCategoryIcon(EventCategory.personal),
            Icons.person_outline);
        expect(AppColors.getCategoryIcon(EventCategory.health),
            Icons.favorite_outline);
        expect(AppColors.getCategoryIcon(EventCategory.social),
            Icons.people_outline);
        expect(AppColors.getCategoryIcon(EventCategory.shopping),
            Icons.shopping_cart_outlined);
        expect(AppColors.getCategoryIcon(EventCategory.other), Icons.event);
      });
    });
  });

  group('AppTheme', () {
    test('lightTheme is Material3 with brightness=light', () {
      final t = AppTheme.lightTheme;
      expect(t.useMaterial3, isTrue);
      expect(t.brightness, Brightness.light);
    });

    test('darkTheme is Material3 with brightness=dark', () {
      final t = AppTheme.darkTheme;
      expect(t.useMaterial3, isTrue);
      expect(t.brightness, Brightness.dark);
    });

    test('both themes register CategoryColors with all default categories', () {
      for (final t in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final ext = t.extension<CategoryColors>();
        expect(ext, isNotNull,
            reason: '${t.brightness} theme is missing CategoryColors');
        expect(ext!.values.keys.toSet(),
            AppColors.defaultCategoryColors.keys.toSet());
      }
    });
  });

  group('CategoryColors theme extension', () {
    const ext = CategoryColors(AppColors.defaultCategoryColors);

    test('colorForCategory returns the named color', () {
      expect(
        ext.colorForCategory(EventCategory.work),
        AppColors.defaultCategoryColors[EventCategory.work],
      );
    });

    test('colorForCategory falls back to other when null', () {
      expect(
        ext.colorForCategory(null),
        AppColors.defaultCategoryColors[EventCategory.other],
      );
    });

    test('colorForCategory on user-customized values returns the override', () {
      const customWork = Color(0xFF000001);
      // ignore: prefer_const_constructors, prefer_const_literals_to_create_immutables — spread map cannot be const
      final custom = CategoryColors(<EventCategory, Color>{
        ...AppColors.defaultCategoryColors,
        EventCategory.work: customWork,
      });
      expect(custom.colorForCategory(EventCategory.work), customWork);
      expect(
        custom.colorForCategory(EventCategory.health),
        AppColors.defaultCategoryColors[EventCategory.health],
      );
    });

    test('copyWith without args returns equivalent values', () {
      final clone = ext.copyWith();
      expect(clone.values, ext.values);
    });

    test('copyWith with new map replaces values', () {
      const customWork = Color(0xFF111111);
      final clone = ext.copyWith(
        values: {EventCategory.work: customWork},
      );
      expect(clone.values, {EventCategory.work: customWork});
    });

    test('lerp(t=0) preserves left side, lerp(t=1) takes right side', () {
      const a = CategoryColors(<EventCategory, Color>{
        EventCategory.work: Color(0xFF000000),
      });
      const b = CategoryColors(<EventCategory, Color>{
        EventCategory.work: Color(0xFFFFFFFF),
      });

      final lerped0 = a.lerp(b, 0.0);
      final lerped1 = a.lerp(b, 1.0);
      expect(lerped0.values[EventCategory.work], const Color(0xFF000000));
      expect(lerped1.values[EventCategory.work], const Color(0xFFFFFFFF));
    });

    test('lerp with a non-CategoryColors other returns `this`', () {
      final same = ext.lerp(null, 0.5);
      expect(same.values, ext.values);
    });
  });
}
