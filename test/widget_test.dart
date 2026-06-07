import 'package:flutter_test/flutter_test.dart';

import 'package:caroxo/main.dart';

void main() {
  testWidgets('Login page renders when Supabase is not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CaroApp());

    expect(find.text('Caro XO'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Dang nhap'), findsOneWidget);
  });
}
