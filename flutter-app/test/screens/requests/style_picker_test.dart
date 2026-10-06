import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/screens/requests/widgets/style_picker.dart';
import 'package:stylesync/config/style_constants.dart';

void main() {
  testWidgets('StylePicker renders 6 style cards with titles and descriptions', (tester) async {
    List<String> selectedStyles = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: StylePicker(
                  selectedStyles: selectedStyles,
                  onChanged: (updated) {
                    setState(() {
                      selectedStyles = updated;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    // Verify section header and description
    expect(find.text('Preferred Design Styles'), findsOneWidget);
    expect(find.text('Select one or more styles that match your vision'), findsOneWidget);

    // Verify all 6 style titles are present
    for (final style in AppStyleConstants.homeStyles) {
      expect(find.text(style.title), findsOneWidget);
      expect(find.text(style.description!), findsOneWidget);
    }

    // Tapping Modern Minimalist card selects it
    await tester.tap(find.text('Modern Minimalist'));
    await tester.pumpAndSettle();

    expect(selectedStyles, contains('Modern Minimalist'));
    expect(find.text('1 selected'), findsOneWidget);

    // Tapping Scandinavian card adds it (multi-select)
    await tester.tap(find.text('Scandinavian'));
    await tester.pumpAndSettle();

    expect(selectedStyles, contains('Modern Minimalist'));
    expect(selectedStyles, contains('Scandinavian'));
    expect(find.text('2 selected'), findsOneWidget);

    // Tapping Modern Minimalist again deselects it
    await tester.tap(find.text('Modern Minimalist'));
    await tester.pumpAndSettle();

    expect(selectedStyles, isNot(contains('Modern Minimalist')));
    expect(selectedStyles, contains('Scandinavian'));
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('StylePicker displays error message when errorText is provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StylePicker(
              selectedStyles: [],
              errorText: 'Pick at least one style you like',
              onChanged: _dummyOnChanged,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pick at least one style you like'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}

void _dummyOnChanged(List<String> styles) {}
