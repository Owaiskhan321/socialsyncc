import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../data/repositories/user_repository.dart';
import '../logger/app_logger.dart';
import '../network/api_constants.dart';
import '../network/session_storage.dart';

/// Subscribes to the user's private Pusher channel after login.
class PusherRealtimeService {
  PusherRealtimeService({
    PusherChannelsFlutter? pusher,
    PusherRepository? authRepo,
    UserRepository? userRepo,
  })  : _pusher = pusher ?? PusherChannelsFlutter.getInstance(),
        _authRepo = authRepo ?? PusherRepository(),
        _userRepo = userRepo ?? UserRepository();

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
        return jsonEncode(auth);
      },
      onConnectionStateChange: (current, previous) {
        AppLogger.d('Pusher $previous → $current');
      },
      onError: (message, code, e) {
        AppLogger.w('Pusher error: $message ($code)', e);
      },
    );

    await _pusher.subscribe(channelName: 'private-user-$userId');
    await _pusher.connect();
    _initialized = true;
    AppLogger.i('Pusher connected for user $userId');
  }

  Future<void> disconnect() async {
    if (!_initialized) return;
    try {
      await _pusher.disconnect();
    } catch (_) {}
    _initialized = false;
  }
}
