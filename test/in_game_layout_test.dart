import 'package:caroxo/models/move_model.dart';
import 'package:caroxo/screens/caro_screen.dart';
import 'package:caroxo/widgets/cell_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('in-game screen uses a tall mobile game layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CaroScreen(
          userEmail: 'hoang@example.com',
          initialMode: GameMode.twoPlayers,
          initialDifficulty: Difficulty.easy,
          initialBoardSize: 20,
          timeLimitSeconds: 35,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('game_header_bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('game_board_viewport')), findsOneWidget);
    expect(find.byKey(const ValueKey('game_bottom_bar')), findsOneWidget);
    expect(find.text('Hoang'), findsWidgets);
    expect(find.text('Your Turn'), findsOneWidget);
    expect(find.text('00:35'), findsOneWidget);

    final viewportSize = tester.getSize(
      find.byKey(const ValueKey('game_board_viewport')),
    );
    expect(viewportSize.height, greaterThan(viewportSize.width));
  });

  testWidgets('desktop web centers the board inside the play area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CaroScreen(
          userEmail: 'hoang@example.com',
          initialMode: GameMode.twoPlayers,
          initialDifficulty: Difficulty.easy,
          initialBoardSize: 20,
          timeLimitSeconds: 35,
        ),
      ),
    );

    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('game_board_viewport')),
    );
    final boardRect = tester.getRect(
      find.byKey(const ValueKey('game_board_surface')),
    );

    expect(boardRect.width, lessThan(viewportRect.width));
    expect(
      boardRect.center.dx,
      moreOrLessEquals(viewportRect.center.dx, epsilon: 1),
    );
    expect(
      boardRect.center.dy,
      moreOrLessEquals(viewportRect.center.dy, epsilon: 1),
    );
  });

  testWidgets('turn status and timer are shown on the active player bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CaroScreen(
          userEmail: 'toilathanh@example.com',
          initialMode: GameMode.twoPlayers,
          initialDifficulty: Difficulty.easy,
          initialBoardSize: 20,
          timeLimitSeconds: 35,
        ),
      ),
    );

    final localBar = find.byKey(const ValueKey('local_player_bar'));
    final opponentBar = find.byKey(const ValueKey('opponent_player_bar'));

    expect(
      find.descendant(of: localBar, matching: find.text('Toilathanh')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: localBar, matching: find.text('Your Turn')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: localBar, matching: find.text('00:35')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: opponentBar, matching: find.text('Your Turn')),
      findsNothing,
    );
    expect(
      find.descendant(of: opponentBar, matching: find.text('00:35')),
      findsNothing,
    );

    await tester.tap(find.byType(CellWidget).first);
    await tester.pump();

    expect(
      find.descendant(of: opponentBar, matching: find.text('Opponent Turn')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: opponentBar, matching: find.text('00:35')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: localBar, matching: find.text('Your Turn')),
      findsNothing,
    );
    expect(
      find.descendant(of: localBar, matching: find.text('00:35')),
      findsNothing,
    );
  });
}
