import 'package:flutter/material.dart';

import 'exit_app_dialog.dart';

/// Intercepts Android/iOS system back when this route is the navigation root.
class AppExitGuard extends StatelessWidget {
  const AppExitGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ExitAppDialog.handleBack(context);
      },
      child: child,
    );
  }
}
