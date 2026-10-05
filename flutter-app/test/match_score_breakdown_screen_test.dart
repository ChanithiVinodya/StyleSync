import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/designers/models/match_score_breakdown.dart';
import 'package:stylesync/modules/designers/screens/match_score_breakdown_screen.dart';
import 'package:stylesync/modules/designers/services/designers_api_service.dart';

class MockDesignersApiService extends DesignersApiService {
  final MatchScoreBreakdownResponse Function() onGetBreakdown;

  MockDesignersApiService({required this.onGetBreakdown});

  @override
  Future<MatchScoreBreakdownResponse> getMatchScoreBreakdown({
    required int designerId,
    required List<String> styleTags,
    required double budgetMin,
    required double budgetMax,
  }) async {
    return onGetBreakdown();
  }
}

void main() {
  group('MatchScoreBreakdownScreen Tests', () {
    testWidgets(
        'Renders all four breakdown components in plain language alongside overall match score',
        (tester) async {
      final mockService = MockDesignersApiService(
        onGetBreakdown: () => const MatchScoreBreakdownResponse(
          designerId: 1,
          styleTagOverlapPct: 0.80,
          budgetRangeOverlapPct: 0.65,
          pastRatingNormalized: 0.84,
          availabilityBonus: 1.0,
          matchScore: 0.88,
          averageRating: 4.2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MatchScoreBreakdownScreen(
            designerId: 1,
            styleTags: const ['Tropical Modernism', 'Minimalist'],
            budgetMin: 200000,
            budgetMax: 500000,
            designerDisplayName: 'Jayawardena Architecture',
            apiService: mockService,
          ),
        ),
      );

      // Loading state check
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Header & Overall Match Score
      expect(find.text('Jayawardena Architecture - Match Breakdown'),
          findsOneWidget);
      expect(find.text('88% Match'), findsOneWidget);
      expect(find.text('Exceptional Match'), findsOneWidget);

      // Component 1: Style Match plain language
      expect(
        find.text(
            "Style match: 80% of your requested style overlaps with this designer's work"),
        findsOneWidget,
      );
      expect(find.text('# Tropical Modernism'), findsOneWidget);
      expect(find.text('# Minimalist'), findsOneWidget);

      // Component 2: Budget Fit plain language
      expect(
        find.text(
            "Budget fit: your budget range overlaps 65% with their pricing"),
        findsOneWidget,
      );

      // Component 3: Rating plain language
      expect(
        find.text("Rating: 4.2 / 5 from past clients"),
        findsOneWidget,
      );

      // Component 4: Availability plain language
      expect(
        find.text("Availability: currently accepting new projects"),
        findsOneWidget,
      );

      // Read-only indicator
      expect(find.text('Read-Only Explanation'), findsOneWidget);
      // Ensure no buttons or edit controls to adjust score/weights exist
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Adjust Weights'), findsNothing);
      expect(find.text('Re-run Matching'), findsNothing);
    });

    testWidgets('Renders "No ratings yet" when designer has no rating history',
        (tester) async {
      final mockService = MockDesignersApiService(
        onGetBreakdown: () => const MatchScoreBreakdownResponse(
          designerId: 7,
          styleTagOverlapPct: 0.50,
          budgetRangeOverlapPct: 0.70,
          pastRatingNormalized: 0.50,
          availabilityBonus: 1.0,
          matchScore: 0.65,
          averageRating: null, // Nullable rating
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MatchScoreBreakdownScreen(
            designerId: 7,
            styleTags: const ['Biophilic'],
            budgetMin: 100000,
            budgetMax: 300000,
            apiService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rating plain language with null history
      expect(find.text('Rating: No ratings yet'), findsOneWidget);
      expect(
          find.text('New designer on platform; standard 50% baseline applied.'),
          findsOneWidget);
    });

    testWidgets('Renders "Availability: At capacity" when designer is at capacity',
        (tester) async {
      final mockService = MockDesignersApiService(
        onGetBreakdown: () => const MatchScoreBreakdownResponse(
          designerId: 2,
          styleTagOverlapPct: 1.0,
          budgetRangeOverlapPct: 1.0,
          pastRatingNormalized: 0.98,
          availabilityBonus: 0.0, // At capacity
          matchScore: 0.90,
          averageRating: 4.9,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MatchScoreBreakdownScreen(
            designerId: 2,
            styleTags: const ['Boho Chic'],
            budgetMin: 150000,
            budgetMax: 300000,
            apiService: mockService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Availability plain language when at capacity
      expect(find.text('Availability: At capacity'), findsOneWidget);
      expect(
        find.text(
            'Designer is currently occupied with active client commitments.'),
        findsOneWidget,
      );
    });
  });
}
