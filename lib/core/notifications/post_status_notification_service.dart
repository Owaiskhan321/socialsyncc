import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/models.dart';
import '../events/post_status_bus.dart';
import '../logger/app_logger.dart';
import '../widgets/app_messenger.dart';

/// Shows in-app toasts (foreground) and system notifications (background)
/// when Pusher reports a post reached a terminal status.
class PostStatusNotificationService with WidgetsBindingObserver {
  PostStatusNotificationService._();

  static final PostStatusNotificationService instance =
      PostStatusNotificationService._();

  static const _channelId = 'socialsyncc_post_status';
  static const _channelName = 'Post updates';
  static const _dedupeWindow = Duration(seconds: 4);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<PostStatusUpdate>? _sub;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  String? _lastDedupeKey;
  DateTime? _lastDedupeAt;
  var _listening = false;
  var _notificationsReady = false;

  /// Subscribe immediately — must run before [runApp] so early Pusher events
  /// are not missed.
  void ensureListening() {
    if (_listening || kIsWeb) return;
    WidgetsBinding.instance.addObserver(this);
    _sub ??= PostStatusBus.instance.stream.listen(_onPostStatus);
    _listening = true;
    AppLogger.i('Post status toast listener active');
  }

  Future<void> initialize() async {
    ensureListening();
    if (_notificationsReady || kIsWeb) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _notifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      if (Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: 'Post publish results',
                importance: Importance.high,
              ),
            );
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      _notificationsReady = true;
      AppLogger.i('Post status system notifications ready');
    } catch (e, st) {
      AppLogger.w('System notifications init failed (toasts still work)', e, st);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _sub = null;
    _listening = false;
    _notificationsReady = false;
  }

  void _onPostStatus(PostStatusUpdate update) {
    final status = update.status;
    if (status == null || !_isTerminal(status)) return;
    if (_isDuplicate(update)) return;

    final title = _notificationTitle(status);
    final body = _notificationBody(update);

    AppLogger.i('Post status alert: $title — $body (foreground=$_isForeground)');

    if (_isForeground) {
      AppMessenger.showSnack(
        body,
        isError: status == PostStatus.failed,
        isSuccess: status == PostStatus.published,
      );
      return;
    }

    if (_notificationsReady) {
      unawaited(_showSystemNotification(
        id: update.postId.hashCode,
        title: title,
        body: body,
      ));
    }
  }

  bool get _isForeground => _lifecycle == AppLifecycleState.resumed;

  bool _isTerminal(PostStatus status) =>
      status == PostStatus.published ||
      status == PostStatus.failed ||
      status == PostStatus.partial ||
      status == PostStatus.cancelled;

  bool _isDuplicate(PostStatusUpdate update) {
    final key = '${update.postId}|${update.status?.name}';
    final now = DateTime.now();
    if (_lastDedupeKey == key &&
        _lastDedupeAt != null &&
        now.difference(_lastDedupeAt!) < _dedupeWindow) {
      return true;
    }
    _lastDedupeKey = key;
    _lastDedupeAt = now;
    return false;
  }

  String _notificationTitle(PostStatus status) => switch (status) {
        PostStatus.published => 'Post published',
        PostStatus.failed => 'Post failed',
        PostStatus.partial => 'Partially published',
        PostStatus.cancelled => 'Post cancelled',
        _ => 'Post update',
      };

  String _notificationBody(PostStatusUpdate update) {
    if (update.message != null && update.message!.trim().isNotEmpty) {
      return update.message!.trim();
    }
    final label = update.title?.trim().isNotEmpty == true
        ? '"${update.title!.trim()}"'
        : 'Your post';
    return switch (update.status) {
      PostStatus.published => '$label was published successfully.',
      PostStatus.failed => '$label failed to publish. Please try again.',
      PostStatus.partial =>
        '$label was published on some platforms but not all.',
      PostStatus.cancelled => '$label was cancelled.',
      _ => '$label status updated.',
    };
  }

  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Post publish results',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.w('Local notification failed', e, st);
    }
  }
}
