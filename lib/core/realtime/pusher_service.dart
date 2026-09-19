import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../data/models/models.dart';
import '../../data/repositories/user_repository.dart';
import '../events/post_status_bus.dart';
import '../logger/app_logger.dart';
import '../network/api_constants.dart';
import '../network/api_json_utils.dart';
import '../network/session_storage.dart';

/// Subscribes to the user's private Pusher channel after login.
class PusherRealtimeService {
  PusherRealtimeService._({
    PusherChannelsFlutter? pusher,
    PusherRepository? authRepo,
    UserRepository? userRepo,
  })  : _pusher = pusher ?? PusherChannelsFlutter.getInstance(),
        _authRepo = authRepo ?? PusherRepository(),
        _userRepo = userRepo ?? UserRepository();

  static final PusherRealtimeService instance = PusherRealtimeService._();

  /// Convenience for existing call sites.
  factory PusherRealtimeService() => instance;

  final PusherChannelsFlutter _pusher;
  final PusherRepository _authRepo;
  final UserRepository _userRepo;
  bool _initialized = false;

  Future<void> connectIfLoggedIn() async {
    final token = await SessionStorage.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final profile = await _userRepo.fetchMe();
      if (profile.id.isEmpty) return;
      await _connect(profile.id);
    } catch (e, st) {
      AppLogger.w('Pusher connect skipped', e, st);
    }
  }

  Future<void> _connect(String userId) async {
    if (_initialized) return;

    await _pusher.init(
      apiKey: PusherConfig.key,
      cluster: PusherConfig.cluster,
      onAuthorizer: (channelName, socketId, options) async {
        final auth = await _authRepo.authenticate(
          socketId: socketId,
          channelName: channelName,
        );
        // iOS plugin expects [String: String], not a JSON string.
        return auth.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      },
      onConnectionStateChange: (current, previous) {
        AppLogger.d('Pusher $previous → $current');
      },
      onError: (message, code, e) {
        AppLogger.w('Pusher error: $message ($code)', e);
      },
      onEvent: _onEvent,
    );

    await _pusher.subscribe(
      channelName: 'private-user-$userId',
      onEvent: _onEvent,
    );
    await _pusher.connect();
    _initialized = true;
    AppLogger.i('Pusher connected for user $userId');
  }

  void _onEvent(dynamic raw) {
    final PusherEvent event;
    if (raw is PusherEvent) {
      event = raw;
    } else {
      return;
    }

    final name = event.eventName;
    if (name.startsWith('pusher:') || name.startsWith('pusher_internal:')) {
      return;
    }

    AppLogger.d('Pusher event: $name data=${event.data}');

    final update = _parsePostStatusUpdate(event);
    if (update == null) return;

    AppLogger.i(
      'Post status via Pusher: ${update.postId} → '
      '${update.status?.name ?? 'unknown'} (${update.eventName})',
    );
    PostStatusBus.instance.emit(update);
  }

  /// Flexible parse — accepts any event that carries postId + status.
  static PostStatusUpdate? _parsePostStatusUpdate(PusherEvent event) {
    final map = _asMap(event.data);
    if (map == null) return null;

    // Prefer nested post object when present.
    Map<String, dynamic> payload = map;
    final nested = map['post'] ?? map['data'];
    if (nested is Map) {
      payload = Map<String, dynamic>.from(nested);
      // Keep top-level status if nested has none.
      if (ApiJsonUtils.readString(payload, ['status', 'state']) == null) {
        final topStatus = ApiJsonUtils.readString(map, ['status', 'state']);
        if (topStatus != null) payload = {...payload, 'status': topStatus};
      }
    }

    final postId = ApiJsonUtils.readString(payload, [
          'postId',
          'post_id',
          'id',
          'uuid',
          '_id',
        ]) ??
        ApiJsonUtils.readString(map, [
          'postId',
          'post_id',
        ]);
    if (postId == null || postId.isEmpty) return null;

    final statusRaw = ApiJsonUtils.readString(payload, ['status', 'state']) ??
        ApiJsonUtils.readString(map, ['status', 'state']);
    if (statusRaw == null || statusRaw.isEmpty) return null;
    final status = _parseStatus(statusRaw);
    if (status == null) return null;

    final message = ApiJsonUtils.readString(payload, [
          'message',
          'error',
          'errorMessage',
          'reason',
        ]) ??
        ApiJsonUtils.readString(map, ['message', 'error', 'errorMessage']);

    final title = ApiJsonUtils.readString(payload, ['title', 'name']) ??
        ApiJsonUtils.readString(map, ['title', 'name']);

    return PostStatusUpdate(
      postId: postId,
      eventName: event.eventName,
      status: status,
      message: message,
      title: title,
    );
  }

  static PostStatus? _parseStatus(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'scheduled' || 'pending' || 'queued' => PostStatus.scheduled,
      'publishing' || 'processing' => PostStatus.publishing,
      'published' || 'success' || 'live' || 'processed' => PostStatus.published,
      'partial' || 'partially_published' || 'partial_success' =>
        PostStatus.partial,
      'failed' || 'error' => PostStatus.failed,
      'cancelled' || 'canceled' => PostStatus.cancelled,
      'draft' => PostStatus.draft,
      _ => null,
    };
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data == null) return null;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  Future<void> disconnect() async {
    if (!_initialized) return;
    try {
      await _pusher.disconnect();
    } catch (_) {}
    _initialized = false;
  }
}
