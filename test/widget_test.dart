import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_web_app/main.dart'; // تأكد أن هذا المسار صحيح لاسم مشروعك

void main() {
  testWidgets('Quran app loads correctly', (WidgetTester tester) async {
    // 1. بناء التطبيق الجديد (QuranApp بدلاً من MyApp)
    await tester.pumpWidget(const QuranApp());

    // 2. الانتظار قليلاً حتى تكتمل الرسوميات
    await tester.pumpAndSettle();

    // 3. التحقق من أن عنوان التطبيق موجود في الشاشة
    // هذا يؤكد أن التطبيق اشتغل ووصل للشاشة الرئيسية
    expect(find.text('القرآن الكريم - تلاوة تفاعلية'), findsOneWidget);

    // 4. التحقق من عدم وجود أيقونة الإضافة القديمة (للتأكد فقط)
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
