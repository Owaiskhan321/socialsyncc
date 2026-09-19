import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../logger/app_logger.dart';
import '../theme/app_colors.dart';
import '../../navigation/app_router.dart';

/// Global [ScaffoldMessenger] for toasts outside widget trees.
abstract final class AppMessenger {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnack(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    void present() {
      final snack = SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError
            ? AppColors.danger
            : isSuccess
                ? AppColors.success
                : AppColors.gray900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      );

      final keyed = scaffoldMessengerKey.currentState;
      if (keyed != null) {
        keyed.hideCurrentSnackBar();
        keyed.showSnackBar(snack);
        AppLogger.d('Toast shown via global messenger');
        return;
      }

      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        final messenger = ScaffoldMessenger.maybeOf(ctx);
        if (messenger != null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(snack);
          AppLogger.d('Toast shown via navigator context');
          return;
        }
      }

      AppLogger.w('Toast skipped — no ScaffoldMessenger in tree');
    }

    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      present();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => present());
    }
  }
}
