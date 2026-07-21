import 'dart:async';

/// Broadcasts when the posts list should refresh in the background
/// (after create / delete) without blocking the UI.
class PostsRefreshBus {
  PostsRefreshBus._();
  static final PostsRefreshBus instance = PostsRefreshBus._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void ping() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
