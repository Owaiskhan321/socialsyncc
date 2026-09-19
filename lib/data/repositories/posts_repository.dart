import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/logger/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_json_utils.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import '../services/live_data_helpers.dart';

class PostsRepository {
  PostsRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<List<PostModel>> fetchPosts() async {
    AppLogger.event('api_posts_list');
    final res = await _client.get(ApiConstants.posts);
    final items = ApiJsonUtils.extractList(res.data);
    return items.map(PostModelApi.fromApi).toList();
  }

  /// `GET /posts/analytics?range=7d|30d|90d`
  Future<LiveAnalytics> fetchAnalytics({String range = '30d'}) async {
    AppLogger.event('api_posts_analytics', {'range': range});
    final res = await _client.get(
      ApiConstants.postsAnalytics,
      queryParameters: {'range': range},
    );
    final data = res.data;
    if (data is Map) {
      return LiveAnalytics.fromApi(Map<String, dynamic>.from(data));
    }
    return const LiveAnalytics(
      published: 0,
      failed: 0,
      scheduled: 0,
      drafts: 0,
      trend: [],
      freq: [],
      pie: [],
    );
  }

  Future<PostModel> fetchPost(String id) async {
    AppLogger.event('api_posts_view', {'id': id});
    final res = await _client.get(ApiConstants.postById(id));
    final data = res.data;
    if (data is Map) {
      return PostModelApi.fromApi(Map<String, dynamic>.from(data));
    }
    // Some APIs wrap as { post: {...} } — already handled inside fromApi keys,
    // but if body itself isn't a map, fall back to empty parse.
    return PostModelApi.fromApi({'id': id});
  }

  Future<void> deletePost(String id) async {
    AppLogger.event('api_posts_delete', {'id': id});
    await _client.delete(ApiConstants.postById(id));
  }

  /// Publish a draft: POST /posts/publish { postId }
  Future<PostModel?> publishPost(String postId) async {
    AppLogger.event('api_posts_publish', {'postId': postId});
    final res = await _client.post(
      ApiConstants.postsPublish,
      body: {'postId': postId},
    );
    final data = res.data;
    if (data is Map) {
      return PostModelApi.fromApi(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<PostModel> createPost({
    required String title,
    required String caption,
    required Set<String> platformIds,
    String postStatus = 'Publishing',
    String? scheduledAtIso,
    String? facebookPageId,
    String? pinterestBoardId,
    String? youtubeChannelId,
    String? googleBusinessProfileId,
    String? linkedinOrganizationId,
    String? linkedinLink,
    List<File> files = const [],
    bool treatAsVideo = false,
  }) async {
    // Up to 5 images (or 1 video) under form field `files`.
    final filesToSend = files.take(5).toList();

    // Match Apidog form-data shape as closely as possible.
    final fields = <String, String>{
      'title': title,
      'caption': caption,
      'postStatus': postStatus,
    };

    if (postStatus == 'Scheduled' &&
        scheduledAtIso != null &&
        scheduledAtIso.isNotEmpty) {
      fields['scheduledAt'] = scheduledAtIso;
    }

    // Only selected platform flags as "true" (same as successful Apidog request).
    for (final entry in PlatformPostFields.fieldByPlatform.entries) {
      if (platformIds.contains(entry.key)) {
        fields[entry.value] = 'true';
      }
    }

    if ((platformIds.contains('facebook') ||
            platformIds.contains('instagram')) &&
        facebookPageId != null &&
        facebookPageId.isNotEmpty) {
      fields['facebookPageId'] = facebookPageId;
    }

    // Instagram is linked via Meta page — do not send instagramId (API rejects it).

    if (platformIds.contains('pinterest') &&
        pinterestBoardId != null &&
        pinterestBoardId.isNotEmpty) {
      fields['pinterestBoardId'] = pinterestBoardId;
    }

    if (platformIds.contains('youtube') &&
        youtubeChannelId != null &&
        youtubeChannelId.isNotEmpty) {
      fields['youtubeChannelId'] = youtubeChannelId;
    }

    if (platformIds.contains('google') &&
        googleBusinessProfileId != null &&
        googleBusinessProfileId.isNotEmpty) {
      fields['googleBusinessProfileId'] = googleBusinessProfileId;
    }

    if (platformIds.contains('linkedin_organization')) {
      fields['linkedinOrganizationPost'] = 'true';
      if (linkedinOrganizationId != null && linkedinOrganizationId.isNotEmpty) {
        fields['linkedinOrganizationId'] = linkedinOrganizationId;
      }
    }

    if (linkedinLink != null && linkedinLink.isNotEmpty) {
      fields['linkedinLink'] = linkedinLink;
    }

    final multipartFiles = <http.MultipartFile>[];
    for (final file in filesToSend) {
      final bytes = await file.readAsBytes();
      final filename = _safeFileName(file, preferVideo: treatAsVideo);
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: filename,
          contentType: _mediaTypeFor(filename),
        ),
      );
    }

    AppLogger.event('api_posts_create', {
      'platforms': platformIds.toList(),
      'postStatus': postStatus,
      'files': multipartFiles.length,
    });
    AppLogger.d(
      'POST /posts body fields: $fields | '
      'files: ${multipartFiles.map((f) => '${f.filename} (${f.length} bytes, ${f.contentType})').toList()}',
    );

    final res = await _client.postMultipart(
      ApiConstants.posts,
      fields: fields,
      files: multipartFiles.isEmpty ? null : multipartFiles,
    );

    final data = res.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      // Processing response may not look like a full PostModel yet.
      if (map['postId'] != null || map['status'] == 'processing') {
        return PostModel(
          id: (map['postId'] ?? map['id'] ?? '').toString(),
          title: title,
          caption: caption,
          platforms: platformIds.toList(),
          status: postStatus == 'Draft'
              ? PostStatus.draft
              : postStatus == 'Scheduled'
                  ? PostStatus.scheduled
                  : PostStatus.publishing,
        );
      }
      return PostModelApi.fromApi(map);
    }
    return PostModel(
      id: '',
      title: title,
      caption: caption,
      platforms: platformIds.toList(),
      status: PostStatus.publishing,
    );
  }

  String _safeFileName(File file, {bool preferVideo = false}) {
    final raw = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : (preferVideo ? 'upload.mp4' : 'upload.jpg');
    if (raw.contains('.') && raw.length > 3) return raw;
    return preferVideo ? 'upload.mp4' : 'upload.jpg';
  }

  MediaType _mediaTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    return MediaType('image', 'jpeg');
  }
}
