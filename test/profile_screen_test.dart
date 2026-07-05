import 'package:caroxo/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Profile screen shows avatar fallback initial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(userEmail: 'avatar@example.com', onSignOut: () {}),
      ),
    );

    expect(find.byKey(const ValueKey('profile_avatar_button')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Đổi ảnh đại diện'), findsOneWidget);
  });
}
