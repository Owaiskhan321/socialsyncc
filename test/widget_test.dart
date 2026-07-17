import 'package:flutter_test/flutter_test.dart';
import 'package:socialsyncc/core/theme/app_colors.dart';
import 'package:socialsyncc/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AppButton renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Sign In'),
        ),
      ),
    );
    expect(find.text('Sign In'), findsOneWidget);
    expect(AppColors.primary, const Color(0xFF2563EB));
  });
}
