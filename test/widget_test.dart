import 'package:flutter_test/flutter_test.dart';

import 'package:omdb/main.dart';

void main() {
  testWidgets('mostra a identidade e a busca inicial do OpenMovie', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenMovieApp());

    expect(find.text('OpenMovie'), findsOneWidget);
    expect(find.text('Encontre seu\npróximo filme'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
  });
}
