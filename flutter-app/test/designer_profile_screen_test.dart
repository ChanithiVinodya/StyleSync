import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/designers/models/designer_profile.dart';
import 'package:stylesync/modules/designers/models/designer_summary.dart';
import 'package:stylesync/modules/designers/models/portfolio_item.dart';
import 'package:stylesync/modules/designers/screens/designer_profile_screen.dart';

void main() {
  group('DesignerProfileScreen Tests', () {
    testWidgets('Renders full profile details, rating, and portfolio gallery grid',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DesignerProfileScreen(designerId: 1),
        ),
      );

      // Settle data load
      await tester.pumpAndSettle();

      // Header info
      expect(find.text('Jayawardena Architecture & Interiors'), findsOneWidget);
      expect(find.text('4.85'), findsOneWidget);
      expect(find.text('Tropical Modernism'), findsWidgets);
      expect(find.textContaining('Accepting Projects'), findsOneWidget);

      // Pricing info
      expect(find.text('TYPICAL PROJECT BUDGET'), findsOneWidget);
      expect(find.textContaining('LKR 150k'), findsOneWidget);

      // Portfolio Gallery Grid
      expect(find.text('Portfolio Showcase'), findsOneWidget);
      expect(find.text('Bawa-Inspired Courtyard Residence'), findsOneWidget);
      expect(find.text('Client: K.M.'), findsOneWidget);
      expect(find.text('LKR 450k-550k'), findsOneWidget);
      expect(find.text('Published Project'), findsWidgets);

      // Confirm Read-only (no edit or delete actions)
      expect(find.text('Edit Profile'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('Displays "No ratings yet" when averageRating is null without faking aggregates',
        (tester) async {
      // In seed data or simulated null rating: Designer 7 has averageRating == null
      await tester.pumpWidget(
        const MaterialApp(
          home: DesignerProfileScreen(designerId: 7),
        ),
      );

      await tester.pumpAndSettle();

      // Profile 7 or fallback with null rating shows "No ratings yet"
      // Let's verify "No ratings yet" is displayed when rating is null
      expect(find.text('No ratings yet'), findsWidgets);
    });

    testWidgets('Tapping portfolio card opens project detail modal',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DesignerProfileScreen(designerId: 1),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure item is scrolled into view in SingleChildScrollView
      final itemFinder = find.text('Bawa-Inspired Courtyard Residence');
      await tester.ensureVisible(itemFinder);
      await tester.pumpAndSettle();

      // Tap portfolio project card
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Modal open
      expect(find.text('Close'), findsOneWidget);
      expect(find.textContaining('A 3,200 sq.ft villa in Pelawatte'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
    });
  });
}
