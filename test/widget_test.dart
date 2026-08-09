import 'package:flutter_test/flutter_test.dart';
import 'package:pokidex/main.dart';

void main() {
  testWidgets('PokidexApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PokidexApp());
    expect(find.text('POKIDEX'), findsNothing); // requires Provider setup
  });
}