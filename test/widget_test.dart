import 'package:flutter_test/flutter_test.dart';
import 'package:nest/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NestApp());
  });
}
