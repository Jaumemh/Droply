import 'package:droply/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders sprint 1 infrastructure shell', (tester) async {
    await tester.pumpWidget(const DroplyApp());
    await tester.pumpAndSettle();

    expect(find.text('Droply'), findsOneWidget);
    expect(find.text('Sprint 1: Infraestructura y Datos'), findsOneWidget);
    expect(find.text('Checklist tecnico del sprint'), findsOneWidget);
  });
}
