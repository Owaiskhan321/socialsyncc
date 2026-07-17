import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dismisses the soft keyboard. Use on taps outside fields / before API calls.
abstract final class KeyboardDismiss {
  static void hide([BuildContext? context]) {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (context != null) {
      FocusScope.of(context).unfocus();
    }
  }
}

/// Wrap any screen so tapping empty space dismisses the keyboard.
class KeyboardDismissScope extends StatelessWidget {
  const KeyboardDismissScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => KeyboardDismiss.hide(context),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
