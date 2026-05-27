import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:day_brief/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('defaultCategoryColors has the 6 canonical categories', () {
      expect(AppColors.defaultCategoryColors.keys.toSet(), {
        'Work',
        'Personal',
        'Health',
        'Social',
        'Shopping',
        'Other',
      });
    });

    test('getCategoryColor returns the matching color', () {
      expect(AppColors.getCategoryColor('Work'),
          AppColors.defaultCategoryColors['Work']);
      expect(AppColors.getCategoryColor('Health'),
          AppColors.defaultCategoryColors['Health']);
    });

    test('getCategoryColor falls back to "Other" for unknown categories', () {
      expect(AppColors.getCategoryColor('SomethingWeird'),
          AppColors.defaultCategoryColors['Other']);
    });

    group('getCategoryIcon', () {
      test('returns the right icon per category', () {
        expect(AppColors.getCategoryIcon('Work'), Icons.work_outline);
        expect(AppColors.getCategoryIcon('Personal'), Icons.person_outline);
        expect(AppColors.getCategoryIcon('Health'), Icons.favorite_outline);
        expect(AppColors.getCategoryIcon('Social'), Icons.people_outline);
        expect(AppColors.getCategoryIcon('Shopping'),
            Icons.shopping_cart_outlined);
      });

      test('falls back to Icons.event for unknown', () {
        expect(AppColors.getCategoryIcon('Asdf'), Icons.event);
        expect(AppColors.getCategoryIcon(''), Icons.event);
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

    test('both themes register CategoryColors with all default categories',
        () {
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
    final ext = CategoryColors(AppColors.defaultCategoryColors);

    test('colorFor returns the named color', () {
      expect(ext.colorFor('Work'),
          AppColors.defaultCategoryColors['Work']);
    });

    test('colorFor falls back to "Other" when name is null or unknown', () {
      expect(ext.colorFor(null),
          AppColors.defaultCategoryColors['Other']);
      expect(ext.colorFor('Mystery'),
          AppColors.defaultCategoryColors['Other']);
    });

    test('colorFor on user-customized values returns the override', () {
      const customWork = Color(0xFF000001);
      final custom = CategoryColors({
        ...AppColors.defaultCategoryColors,
        'Work': customWork,
      });
      expect(custom.colorFor('Work'), customWork);
      expect(custom.colorFor('Health'),
          AppColors.defaultCategoryColors['Health']);
    });

    test('copyWith without args returns equivalent values', () {
      final clone = ext.copyWith();
      expect(clone.values, ext.values);
    });

    test('copyWith with new map replaces values', () {
      const customWork = Color(0xFF111111);
      final clone = ext.copyWith(values: {'Work': customWork});
      expect(clone.values, {'Work': customWork});
    });

    test('lerp(t=0) preserves left side, lerp(t=1) takes right side', () {
      final a = CategoryColors({'Work': const Color(0xFF000000)});
      final b = CategoryColors({'Work': const Color(0xFFFFFFFF)});

      final lerped0 = a.lerp(b, 0.0);
      final lerped1 = a.lerp(b, 1.0);
      expect(lerped0.values['Work'], const Color(0xFF000000));
      expect(lerped1.values['Work'], const Color(0xFFFFFFFF));
    });

    test('lerp with a non-CategoryColors other returns `this`', () {
      final same = ext.lerp(null, 0.5);
      expect(same.values, ext.values);
    });
  });
}
