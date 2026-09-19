import 'dart:async';

import '../../data/models/models.dart';

/// Realtime post status update from Pusher (e.g. post.processed).
class PostStatusUpdate {
  const PostStatusUpdate({
    required this.postId,
    required this.eventName,
    this.status,
    this.message,
    this.title,
  });

  final String postId;
  final String eventName;
  final PostStatus? status;
  final String? message;
  final String? title;
}

/// Broadcasts Pusher-driven post status changes to UI cubits.
class PostStatusBus {
  PostStatusBus._();
  static final PostStatusBus instance = PostStatusBus._();

  final _controller = StreamController<PostStatusUpdate>.broadcast();

  Stream<PostStatusUpdate> get stream => _controller.stream;

  void emit(PostStatusUpdate update) {
    if (!_controller.isClosed) _controller.add(update);
  }
}