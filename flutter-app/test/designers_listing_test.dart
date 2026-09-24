import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/designers/models/designer_summary.dart';
import 'package:stylesync/modules/designers/models/paged_result.dart';
import 'package:stylesync/modules/designers/widgets/designer_card.dart';
import 'package:stylesync/modules/designers/screens/designer_listing_screen.dart';

void main() {
  group('Designer Models & DTO Deserialization', () {
    test('DesignerSummary deserializes backend JSON response correctly', () {
      final json = {
        'id': 1,
        'displayName': 'Jayawardena Architecture & Interiors',
        'bio': 'Award-winning interior studio specializing in tropical modernism.',
        'styleTags': ['Tropical Modernism', 'Minimalist'],
        'serviceCategories': ['Full Home Interior'],
        'priceRangeMin': 150000.0,
        'priceRangeMax': 600000.0,
        'ratePerSqFt': 450.0,
        'isAvailable': true,
        'maxConcurrentProjects': 3,
        'activeProjectCount': 1,
        'remainingCapacity': 2,
        'isUnderCapacity': true,
        'isAtCapacity': false,
        'averageRating': 4.85,
        'listingStatus': 1,
        'publishedPortfolioCount': 2,
        'featuredImageUrl': 'https://example.com/image.jpg',
        'createdAtUtc': '2026-08-15T10:00:00Z',
      };

      final designer = DesignerSummary.fromJson(json);

      expect(designer.id, 1);
      expect(designer.displayName, 'Jayawardena Architecture & Interiors');
      expect(designer.styleTags.length, 2);
      expect(designer.priceRangeMin, 150000.0);
      expect(designer.priceRangeMax, 600000.0);
      expect(designer.ratePerSqFt, 450.0);
      expect(designer.isUnderCapacity, true);
      expect(designer.isAtCapacity, false);
      expect(designer.averageRating, 4.85);
      expect(designer.listingStatus, ListingStatus.published);
    });

    test('PagedResult deserializes paginated JSON envelope correctly', () {
      final json = {
        'items': [
          {
            'id': 1,
            'displayName': 'Studio Amara',
            'bio': 'Bio',
            'styleTags': ['Boho Chic'],
            'serviceCategories': [],
            'priceRangeMin': 100000,
            'priceRangeMax': 300000,
            'ratePerSqFt': 320,
            'isAvailable': true,
            'maxConcurrentProjects': 2,
            'activeProjectCount': 2,
            'remainingCapacity': 0,
            'isUnderCapacity': false,
            'isAtCapacity': true,
            'averageRating': 4.9,
            'listingStatus': 1,
            'publishedPortfolioCount': 1,
            'createdAtUtc': '2026-08-18T09:00:00Z',
          }
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
      };

      final paged = PagedResult<DesignerSummary>.fromJson(
        json,
        (itemJson) => DesignerSummary.fromJson(itemJson),
      );

      expect(paged.page, 1);
      expect(paged.totalCount, 1);
      expect(paged.items.length, 1);
      expect(paged.items.first.isAtCapacity, true);
    });
  });

  group('DesignerCard Widget Tests', () {
    testWidgets('Renders designer details, rating, and accepting projects badge',
        (tester) async {
      final designer = DesignerSummary(
        id: 1,
        displayName: 'Jayawardena Architecture',
        bio: 'Bespoke interior design studio.',
        styleTags: const ['Tropical Modernism', 'Minimalist'],
        serviceCategories: const ['Full Home'],
        priceRangeMin: 150000,
        priceRangeMax: 600000,
        ratePerSqFt: 450,
        isAvailable: true,
        maxConcurrentProjects: 3,
        activeProjectCount: 1,
        remainingCapacity: 2,
        isUnderCapacity: true,
        isAtCapacity: false,
        averageRating: 4.85,
        listingStatus: ListingStatus.published,
        publishedPortfolioCount: 2,
        createdAtUtc: DateTime.now(),
      );

      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignerCard(
              designer: designer,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Jayawardena Architecture'), findsOneWidget);
      expect(find.text('4.85'), findsOneWidget);
      expect(find.text('Accepting Projects'), findsOneWidget);
      expect(find.text('Tropical Modernism'), findsOneWidget);
      expect(find.text('LKR 450'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('Renders At Capacity badge when isAtCapacity is true',
        (tester) async {
      final designer = DesignerSummary(
        id: 2,
        displayName: 'Studio Amara Design',
        bio: 'Warm bohemian spaces.',
        styleTags: const ['Boho Chic'],
        serviceCategories: const [],
        priceRangeMin: 100000,
        priceRangeMax: 350000,
        ratePerSqFt: 320,
        isAvailable: true,
        maxConcurrentProjects: 2,
        activeProjectCount: 2,
        remainingCapacity: 0,
        isUnderCapacity: false,
        isAtCapacity: true,
        averageRating: 4.90,
        listingStatus: ListingStatus.published,
        publishedPortfolioCount: 1,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignerCard(
              designer: designer,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Studio Amara Design'), findsOneWidget);
      expect(find.text('At Capacity'), findsOneWidget);
    });
  });

  group('DesignerListingScreen Widget Tests', () {
    testWidgets('Renders screen header, style chips, and listings',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DesignerListingScreen(),
        ),
      );

      // Initial loading
      expect(find.text('Interior Designers'), findsOneWidget);

      // Pump to settle async load
      await tester.pumpAndSettle();

      expect(find.text('Tropical Modernism'), findsWidgets);
      expect(find.text('Luxe Heritage Interiors'), findsOneWidget);
    });
  });
}
