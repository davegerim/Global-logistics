import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:global_logistics_app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GlobalLogisticsApp()),
    );
    await tester.pump();
    expect(find.byType(GlobalLogisticsApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
