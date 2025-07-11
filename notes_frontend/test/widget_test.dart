import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('NotesApp main launches NotesListPage', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    // Should find the notes title
    expect(find.text('Notes'), findsOneWidget);
    // Should find the floating action button
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('NotesApp shows search bar', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
