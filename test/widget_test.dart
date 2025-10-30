// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku_solver/main.dart';

void main() {
  testWidgets('Sudoku app launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SudokuApp());

    // Verify that the Sudoku app title is displayed.
    expect(find.text('9x9 Sudoku'), findsOneWidget);

    // Verify that the status message is displayed.
    expect(
      find.text(
        'Fill in the missing numbers (1-9)! Click a cell and press a number key.',
      ),
      findsOneWidget,
    );

    // Verify that some pre-filled numbers are present in the grid.
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsAtLeastNWidgets(1));
    expect(find.text('9'), findsAtLeastNWidgets(1));
  });
}
