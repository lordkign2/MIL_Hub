import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mil_hub/common/utils/responsive_utils.dart';

void main() {
  group('ResponsiveUtils', () {
    test('should correctly identify mobile screen size', () {
      // Create a test widget with a mobile-sized screen
      final mobileMediaQuery = MediaQueryData(size: const Size(500, 800));

      expect(
        ResponsiveUtils.isMobile(MockBuildContext(mobileMediaQuery)),
        true,
      );
      expect(
        ResponsiveUtils.isTablet(MockBuildContext(mobileMediaQuery)),
        false,
      );
      expect(
        ResponsiveUtils.isDesktop(MockBuildContext(mobileMediaQuery)),
        false,
      );
    });

    test('should correctly identify tablet screen size', () {
      // Create a test widget with a tablet-sized screen
      final tabletMediaQuery = MediaQueryData(size: const Size(800, 1000));

      expect(
        ResponsiveUtils.isMobile(MockBuildContext(tabletMediaQuery)),
        false,
      );
      expect(
        ResponsiveUtils.isTablet(MockBuildContext(tabletMediaQuery)),
        true,
      );
      expect(
        ResponsiveUtils.isDesktop(MockBuildContext(tabletMediaQuery)),
        false,
      );
    });

    test('should correctly identify desktop screen size', () {
      // Create a test widget with a desktop-sized screen
      final desktopMediaQuery = MediaQueryData(size: const Size(1200, 800));

      expect(
        ResponsiveUtils.isMobile(MockBuildContext(desktopMediaQuery)),
        false,
      );
      expect(
        ResponsiveUtils.isTablet(MockBuildContext(desktopMediaQuery)),
        false,
      );
      expect(
        ResponsiveUtils.isDesktop(MockBuildContext(desktopMediaQuery)),
        true,
      );
    });

    test('should return correct padding for different screen sizes', () {
      final mobileMediaQuery = MediaQueryData(size: const Size(500, 800));
      final tabletMediaQuery = MediaQueryData(size: const Size(800, 1000));
      final desktopMediaQuery = MediaQueryData(size: const Size(1200, 800));

      final mobilePadding = ResponsiveUtils.getPadding(
        MockBuildContext(mobileMediaQuery),
      );
      final tabletPadding = ResponsiveUtils.getPadding(
        MockBuildContext(tabletMediaQuery),
      );
      final desktopPadding = ResponsiveUtils.getPadding(
        MockBuildContext(desktopMediaQuery),
      );

      expect(
        mobilePadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(
        tabletPadding,
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
      expect(
        desktopPadding,
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      );
    });

    test('should return correct grid count for different screen sizes', () {
      final mobileMediaQuery = MediaQueryData(size: const Size(500, 800));
      final tabletMediaQuery = MediaQueryData(size: const Size(800, 1000));
      final desktopMediaQuery = MediaQueryData(size: const Size(1200, 800));

      final mobileCount = ResponsiveUtils.getGridCount(
        MockBuildContext(mobileMediaQuery),
      );
      final tabletCount = ResponsiveUtils.getGridCount(
        MockBuildContext(tabletMediaQuery),
      );
      final desktopCount = ResponsiveUtils.getGridCount(
        MockBuildContext(desktopMediaQuery),
      );

      expect(mobileCount, 1);
      expect(tabletCount, 2);
      expect(desktopCount, 3);
    });

    test(
      'should return correct cross axis count for different screen sizes',
      () {
        final smallMediaQuery = MediaQueryData(size: const Size(300, 600));
        final mediumMediaQuery = MediaQueryData(size: const Size(600, 800));
        final largeMediaQuery = MediaQueryData(size: const Size(1200, 800));

        final smallCount = ResponsiveUtils.getCrossAxisCount(
          MockBuildContext(smallMediaQuery),
          maxItemWidth: 150,
        );
        final mediumCount = ResponsiveUtils.getCrossAxisCount(
          MockBuildContext(mediumMediaQuery),
          maxItemWidth: 150,
        );
        final largeCount = ResponsiveUtils.getCrossAxisCount(
          MockBuildContext(largeMediaQuery),
          maxItemWidth: 150,
        );

        expect(smallCount, 2); // 300 / 150 = 2
        expect(mediumCount, 4); // 600 / 150 = 4
        expect(largeCount, 8); // 1200 / 150 = 8
      },
    );

    test('should return correct spacing for different screen sizes', () {
      final mobileMediaQuery = MediaQueryData(size: const Size(500, 800));
      final tabletMediaQuery = MediaQueryData(size: const Size(800, 1000));
      final desktopMediaQuery = MediaQueryData(size: const Size(1200, 800));

      final mobileSpacing = ResponsiveUtils.getSpacing(
        MockBuildContext(mobileMediaQuery),
      );
      final tabletSpacing = ResponsiveUtils.getSpacing(
        MockBuildContext(tabletMediaQuery),
      );
      final desktopSpacing = ResponsiveUtils.getSpacing(
        MockBuildContext(desktopMediaQuery),
      );

      expect(mobileSpacing, 8.0);
      expect(tabletSpacing, 12.0);
      expect(desktopSpacing, 16.0);
    });
  });
}

// Mock BuildContext for testing
class MockBuildContext extends BuildContext {
  final MediaQueryData mediaQueryData;

  MockBuildContext(this.mediaQueryData);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
