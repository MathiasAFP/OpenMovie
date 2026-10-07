import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:omdb/main.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets('mostra a identidade e a busca inicial do OpenMovie', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenMovieApp());

    expect(find.text('OpenMovie'), findsOneWidget);
    expect(find.text('Encontre seu\npróximo filme'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
  });
}
