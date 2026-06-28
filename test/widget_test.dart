import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:caroxo/main.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'SUPABASE_URL=\nSUPABASE_ANON_KEY=\n');
  });

  testWidgets('Login page renders when Supabase is not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CaroApp());

    expect(find.text('Caro XO'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
