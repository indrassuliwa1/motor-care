import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart'; // Menggunakan relative path ke main.dart

void main() {
  testWidgets('Setup test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MotorCareApp());

    // Verify that our setup text is present.
    expect(find.text('Setup Project Berhasil!'), findsOneWidget);
  });
}