import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Captured tap-source rectangle for an iOS-style app-launch transition.
class AppLaunchSourceData {
  const AppLaunchSourceData({
    required this.rect,
    this.borderRadius = 28,
  });

  final Rect rect;
  final double borderRadius;
}

/// Holds the next push origin until the matching [GoRoute] pageBuilder consumes it.
abstract final class AppLaunchOrigin {
  static AppLaunchSourceData? _pending;
  static DateTime? _lastPushAt;

  static bool get hasPending => _pending != null;

  /// Returns false if a push happened too recently (duplicate-tap guard).
  static bool beginPush({Duration cooldown = const Duration(milliseconds: 450)}) {
    final now = DateTime.now();
    if (_lastPushAt != null && now.difference(_lastPushAt!) < cooldown) {
      return false;
    }
    _lastPushAt = now;
    return true;
  }

  static void capture(AppLaunchSourceData data) {
    _pending = data;
  }

  static void captureFromKey(
    GlobalKey sourceKey, {
    double borderRadius = 28,
  }) {
    final rect = rectFromKey(sourceKey);
    if (rect != null) {
      _pending = AppLaunchSourceData(rect: rect, borderRadius: borderRadius);
    }
  }

  static void captureFromContext(
    BuildContext context, {
    double borderRadius = 28,
  }) {
    final rect = rectFromContext(context);
    if (rect != null) {
      _pending = AppLaunchSourceData(rect: rect, borderRadius: borderRadius);
    }
  }

  static Rect? rectFromKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    return rectFromContext(ctx);
  }

  static Rect? rectFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  /// Takes the pending origin (or a centered fallback) for the route lifetime.
  static AppLaunchSourceData consume({required Size screenSize}) {
    final pending = _pending;
    _pending = null;
    if (pending != null && pending.rect.width > 0 && pending.rect.height > 0) {
      return pending;
    }
    const size = 56.0;
    return AppLaunchSourceData(
      rect: Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: size,
        height: size,
      ),
      borderRadius: 20,
    );
  }

  static void clear() => _pending = null;
}

/// Navigator API: expand [destination] from [sourceKey].
Future<T?> pushFromSource<T extends Object?>({
  required BuildContext context,
  required GlobalKey sourceKey,
  required Widget destination,
  double borderRadius = 28,
  RouteSettings? settings,
}) {
  if (!AppLaunchOrigin.beginPush()) return Future<T?>.value();
  final rect = AppLaunchOrigin.rectFromKey(sourceKey);
  if (rect == null) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(settings: settings, builder: (_) => destination),
    );
  }
  return Navigator.of(context).push<T>(
    IOSAppLaunchRoute<T>(
      sourceRect: rect,
      sourceBorderRadius: borderRadius,
      page: destination,
      settings: settings,
    ),
  );
}

/// GoRouter-friendly push that captures the tapped widget as the expand origin.
extension AppLaunchGoRouter on BuildContext {
  Future<T?> pushFromSource<T extends Object?>(
    String location, {
    GlobalKey? sourceKey,
    BuildContext? sourceContext,
    Object? extra,
    double borderRadius = 28,
  }) {
    if (!AppLaunchOrigin.beginPush()) return Future<T?>.value();

    if (sourceKey != null) {
      AppLaunchOrigin.captureFromKey(sourceKey, borderRadius: borderRadius);
    } else {
      AppLaunchOrigin.captureFromContext(
        sourceContext ?? this,
        borderRadius: borderRadius,
      );
    }
    return GoRouter.of(this).push<T>(location, extra: extra);
  }
}

/// Custom [PageRoute] for raw [Navigator.push] usage.
class IOSAppLaunchRoute<T> extends PageRouteBuilder<T> {
  IOSAppLaunchRoute({
    required this.sourceRect,
    required Widget page,
    this.sourceBorderRadius = 28,
    super.settings,
    Duration transitionDuration = const Duration(milliseconds: 520),
    Duration reverseTransitionDuration = const Duration(milliseconds: 440),
  }) : super(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppLaunchTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              sourceRect: sourceRect,
              sourceBorderRadius: sourceBorderRadius,
              child: child,
            );
          },
        );

  final Rect sourceRect;
  final double sourceBorderRadius;
}

/// GoRouter [CustomTransitionPage] with the same expand-from-source behavior.
CustomTransitionPage<T> appLaunchTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  required Rect sourceRect,
  double sourceBorderRadius = 28,
  String? name,
  Object? arguments,
  String? restorationId,
  bool enableExpand = true,
  Duration transitionDuration = const Duration(milliseconds: 520),
  Duration reverseTransitionDuration = const Duration(milliseconds: 440),
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    child: child,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: enableExpand
        ? transitionDuration
        : Duration.zero,
    reverseTransitionDuration: enableExpand
        ? reverseTransitionDuration
        : Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!enableExpand) {
        return _SecondaryScale(
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      }
      return AppLaunchTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        sourceRect: sourceRect,
        sourceBorderRadius: sourceBorderRadius,
        child: child,
      );
    },
  );
}

/// Builds a go_router page that expands from the last captured tap origin.
CustomTransitionPage<T> buildAppLaunchPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool enableExpand = true,
}) {
  final screen = MediaQuery.sizeOf(context);
  final origin = enableExpand
      ? AppLaunchOrigin.consume(screenSize: screen)
      : AppLaunchSourceData(rect: Offset.zero & screen, borderRadius: 0);
  return appLaunchTransitionPage<T>(
    key: state.pageKey,
    name: state.name,
    child: child,
    sourceRect: origin.rect,
    sourceBorderRadius: origin.borderRadius,
    enableExpand: enableExpand,
  );
}

/// Renders the destination expanding from [sourceRect] → full screen,
/// and scales this page down when another route is pushed on top.
class AppLaunchTransition extends StatelessWidget {
  const AppLaunchTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.sourceRect,
    required this.sourceBorderRadius,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Rect sourceRect;
  final double sourceBorderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final end = Offset.zero & screen;

    final primary = CurvedAnimation(
      parent: animation,
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut,
    );
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([primary, secondary]),
      child: child,
      builder: (context, child) {
        final t = primary.value.clamp(0.0, 1.0);
        final rect = Rect.lerp(sourceRect, end, t)!;
        final radius = Tween<double>(begin: sourceBorderRadius, end: 0)
            .transform(t);
        final underScale = Tween<double>(begin: 1, end: 0.965).evaluate(secondary);
        final underOpacity = Tween<double>(begin: 1, end: 0.88).evaluate(secondary);
        final scrim = 0.18 * Curves.easeOut.transform(t);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (t < 1)
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: scrim),
                ),
              ),
            Opacity(
              opacity: underOpacity,
              child: Transform.scale(
                scale: underScale,
                alignment: Alignment.center,
                child: _ExpandingPage(
                  rect: rect,
                  borderRadius: radius,
                  screenSize: screen,
                  child: child!,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SecondaryScale extends StatelessWidget {
  const _SecondaryScale({
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: secondary,
      child: child,
      builder: (context, child) {
        final scale = Tween<double>(begin: 1, end: 0.965).evaluate(secondary);
        final opacity = Tween<double>(begin: 1, end: 0.88).evaluate(secondary);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

class _ExpandingPage extends StatelessWidget {
  const _ExpandingPage({
    required this.rect,
    required this.borderRadius,
    required this.screenSize,
    required this.child,
  });

  final Rect rect;
  final double borderRadius;
  final Size screenSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: rect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius.clamp(0, 48)),
            clipBehavior: Clip.antiAlias,
            child: RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: screenSize.width,
                  height: screenSize.height,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
