import '../../core/network/api_json_utils.dart';
import 'models.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.plan,
    this.wallet,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? plan;
  final WalletInfo? wallet;

  factory UserProfile.fromJson(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final user = map['user'] is Map ? Map<String, dynamic>.from(map['user'] as Map) : map;
    WalletInfo? wallet;
    if (user['wallet'] is Map || map['wallet'] is Map) {
      wallet = WalletInfo.fromJson(user['wallet'] ?? map['wallet']);
    }
    return UserProfile(
      id: ApiJsonUtils.readString(user, ['id', 'uuid', 'userId']) ?? '',
      name: ApiJsonUtils.readString(user, ['name', 'fullName', 'displayName']) ?? 'User',
      email: ApiJsonUtils.readString(user, ['email']) ?? '',
      avatarUrl: ApiJsonUtils.readString(user, ['avatar', 'avatarUrl', 'photo', 'image']),
      plan: ApiJsonUtils.readString(user, ['plan', 'subscription', 'subscriptionPlan']),
      wallet: wallet,
    );
  }
}

class SocialAccount {
  const SocialAccount({
    required this.id,
    required this.provider,
    required this.name,
    this.username,
    this.status = 'active',
    this.profileImage,
    this.platformName,
    this.connectedAt,
    this.lastSyncedAt,
  });

  final String id;
  final String provider;
  final String name;
  final String? username;
  final String status;
  final String? profileImage;
  final String? platformName;
  final String? connectedAt;
  final String? lastSyncedAt;

  bool get isConnected {
    final s = status.toLowerCase().trim();
    if (s.isEmpty) return true;
    return s == 'active' || s == 'connected' || s == 'ok' || s == 'live';
  }

  bool get isDisconnected {
    final s = status.toLowerCase().trim();
    return s == 'disconnected' || s == 'revoked' || s == 'inactive';
  }

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    var provider = ApiJsonUtils.readString(json, [
          'platform.slug',
          'platform.name',
          'provider',
          'type',
          'service',
        ]) ??
        '';

    String? platformName;
    final platformObj = json['platform'];
    if (platformObj is Map) {
      final map = Map<String, dynamic>.from(platformObj);
      final slug = ApiJsonUtils.readString(map, ['slug', 'name']);
      if (slug != null && slug.isNotEmpty) provider = slug;
      platformName = ApiJsonUtils.readString(map, ['name']);
    }

    return SocialAccount(
      id: ApiJsonUtils.readString(json, ['id', 'uuid', 'accountId']) ?? '',
      provider: provider.toLowerCase(),
      name: ApiJsonUtils.readString(json, [
            'displayName',
            'name',
            'title',
            'pageName',
            'username',
          ]) ??
          'Account',
      username: ApiJsonUtils.readString(json, ['username', 'handle', 'email']),
      status: (ApiJsonUtils.readString(json, ['status', 'state', 'connectionStatus']) ??
              'active')
          .toLowerCase(),
      profileImage: ApiJsonUtils.readString(json, [
        'profileImage',
        'profile_image',
        'avatar',
        'avatarUrl',
        'picture',
        'image',
      ]),
      platformName: platformName,
      connectedAt: ApiJsonUtils.readString(json, ['connectedAt', 'connected_at']),
      lastSyncedAt: ApiJsonUtils.readString(json, ['lastSyncedAt', 'last_synced_at']),
    );
  }
}

extension SocialAccountPreview on SocialAccount {
  String get previewLabel {
    final displayName = this.name.trim();
    if (displayName.isNotEmpty && displayName.toLowerCase() != 'account') {
      return displayName;
    }
    final user = username?.trim();
    if (user != null && user.isNotEmpty) {
      return user.replaceFirst(RegExp(r'^@'), '');
    }
    return provider;
  }

  String get previewHandle {
    final user = username?.trim();
    if (user != null && user.isNotEmpty) {
      return user.replaceFirst(RegExp(r'^@'), '');
    }
    final displayName = this.name.trim();
    if (displayName.isNotEmpty && displayName.toLowerCase() != 'account') {
      final cleaned =
          displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '');
      if (cleaned.isNotEmpty) return cleaned;
    }
    return provider.toLowerCase();
  }
}

/// Full `/social-accounts` payload (connected + disconnected + expired).
class SocialAccountsResult {
  const SocialAccountsResult({
    required this.accounts,
    required this.connected,
    required this.disconnected,
    this.expired = const [],
    this.total = 0,
    this.activeCount = 0,
    this.disconnectedCount = 0,
    this.expiredCount = 0,
  });

  final List<SocialAccount> accounts;
  final List<SocialAccount> connected;
  final List<SocialAccount> disconnected;
  final List<SocialAccount> expired;
  final int total;
  final int activeCount;
  final int disconnectedCount;
  final int expiredCount;

  static SocialAccountsResult empty() => const SocialAccountsResult(
        accounts: [],
        connected: [],
        disconnected: [],
      );

  factory SocialAccountsResult.fromJson(dynamic data) {
    if (data is! Map) {
      final list = ApiJsonUtils.extractList(data).map(SocialAccount.fromJson).toList();
      final connected = list.where((a) => a.isConnected).toList();
      final disconnected = list.where((a) => a.isDisconnected).toList();
      return SocialAccountsResult(
        accounts: list,
        connected: connected,
        disconnected: disconnected,
        total: list.length,
        activeCount: connected.length,
        disconnectedCount: disconnected.length,
      );
    }

    final map = Map<String, dynamic>.from(data);

    List<SocialAccount> parseKey(String key) {
      final v = map[key];
      if (v is! List) return const [];
      return v
          .whereType<Map>()
          .map((e) => SocialAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final accounts = parseKey('accounts');
    final connected = map.containsKey('connected')
        ? parseKey('connected')
        : accounts.where((a) => a.isConnected).toList();
    final disconnected = map.containsKey('disconnected')
        ? parseKey('disconnected')
        : accounts.where((a) => a.isDisconnected).toList();
    final expired = parseKey('expired');

    final counts = map['counts'] is Map
        ? Map<String, dynamic>.from(map['counts'] as Map)
        : <String, dynamic>{};

    int readCount(String key, int fallback) {
      final v = counts[key] ?? map[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return fallback;
    }

    return SocialAccountsResult(
      accounts: accounts.isNotEmpty ? accounts : [...connected, ...disconnected, ...expired],
      connected: connected,
      disconnected: disconnected,
      expired: expired,
      total: readCount('total', accounts.length),
      activeCount: readCount('active', connected.length),
      disconnectedCount: readCount('disconnected', disconnected.length),
      expiredCount: readCount('expired', expired.length),
    );
  }
}

class NamedResource {
  const NamedResource({
    required this.id,
    required this.name,
    this.imageUrl,
    this.subtitle,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? subtitle;

  factory NamedResource.fromJson(Map<String, dynamic> json) {
    return NamedResource(
      id: ApiJsonUtils.readString(json, [
            'id',
            'uuid',
            'pageId',
            'boardId',
            'channelId',
            'profileId',
            'locationId',
          ]) ??
          '',
      name: ApiJsonUtils.readString(json, [
            'name',
            'title',
            'boardName',
            'pageName',
            'username',
            'displayName',
          ]) ??
          '—',
      imageUrl: ApiJsonUtils.readString(json, [
        'picture',
        'thumbnail',
        'profileImage',
        'image',
        'imageUrl',
        'avatar',
        'picture.data.url',
      ]),
      subtitle: ApiJsonUtils.readString(json, [
        'username',
        'customUrl',
        'category',
        'description',
      ]),
    );
  }
}

extension PostModelApi on PostModel {
  static PostModel fromApi(Map<String, dynamic> json) {
    // Unwrap common envelopes: { post: {...} } / { data: {...} }
    if (json['post'] is Map) {
      json = Map<String, dynamic>.from(json['post'] as Map);
    } else if (json['data'] is Map &&
        (json['data'] as Map).containsKey('title')) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }

    final statusRaw =
        (ApiJsonUtils.readString(json, ['status', 'state']) ?? 'draft').toLowerCase();
    var status = switch (statusRaw) {
      'scheduled' || 'pending' || 'queued' => PostStatus.scheduled,
      'publishing' || 'processing' => PostStatus.publishing,
      'published' || 'success' || 'live' || 'processed' => PostStatus.published,
      'partial' || 'partially_published' || 'partial_success' =>
        PostStatus.partial,
      'failed' || 'error' => PostStatus.failed,
      'cancelled' || 'canceled' => PostStatus.cancelled,
      _ => PostStatus.draft,
    };

    final platformsRaw = json['platforms'] ?? json['channels'];
    final platformResults = <PostPlatformResult>[];
    final platforms = <String>[];

    void addPlatformId(String? raw) {
      if (raw == null || raw.isEmpty) return;
      final normalized = _normalizePostPlatformId(raw);
      if (normalized == null || platforms.contains(normalized)) return;
      platforms.add(normalized);
    }

    if (platformsRaw is List && platformsRaw.isNotEmpty) {
      for (final p in platformsRaw) {
        if (p is String) {
          addPlatformId(p);
          continue;
        }
        if (p is! Map) continue;
        final map = Map<String, dynamic>.from(p);

        String? provider;
        final meta = map['metadata'];
        Map<String, dynamic>? metaMap;
        if (meta is Map) {
          metaMap = Map<String, dynamic>.from(meta);
          provider = ApiJsonUtils.readString(
            metaMap,
            ['provider', 'platform', 'slug', 'name'],
          );
        }
        provider ??= ApiJsonUtils.readString(map, [
          'provider',
          'platform',
          'slug',
          'name',
        ]);
        provider ??= _inferProviderFromMetadata(metaMap, map);
        final platformId = _normalizePostPlatformId(provider ?? '');
        if (platformId == null) continue;
        addPlatformId(platformId);

        final psRaw = ApiJsonUtils.readString(map, [
              'platformStatus',
              'status',
              'state',
            ])
            ?.toLowerCase();
        final platformStatus = switch (psRaw) {
          'scheduled' || 'pending' || 'queued' => PostStatus.scheduled,
          'publishing' || 'processing' => PostStatus.publishing,
          'published' || 'success' || 'live' || 'processed' =>
            PostStatus.published,
          'failed' || 'error' => PostStatus.failed,
          'cancelled' || 'canceled' => PostStatus.cancelled,
          'draft' => PostStatus.draft,
          _ => status == PostStatus.publishing
              ? PostStatus.publishing
              : PostStatus.published,
        };
        final errorMessage = ApiJsonUtils.readString(map, [
          'errorMessage',
          'error',
          'message',
          'reason',
        ]);
        final platformPostId = ApiJsonUtils.readString(map, [
          'platformPostId',
          'platform_post_id',
          'externalId',
          'external_id',
        ]);

        // Avoid duplicate rows for same platform id.
        final existing = platformResults.indexWhere(
          (r) => r.platformId == platformId,
        );
        final result = PostPlatformResult(
          platformId: platformId,
          status: platformStatus,
          errorMessage: errorMessage,
          platformPostId: platformPostId,
        );
        if (existing >= 0) {
          // Prefer failed / more specific outcome.
          if (platformStatus == PostStatus.failed ||
              platformResults[existing].status != PostStatus.failed) {
            platformResults[existing] = result;
          }
        } else {
          platformResults.add(result);
        }
      }

      if (platformResults.isNotEmpty) {
        final allPublished =
            platformResults.every((r) => r.status == PostStatus.published);
        final allFailed =
            platformResults.every((r) => r.status == PostStatus.failed);
        final anyFailed =
            platformResults.any((r) => r.status == PostStatus.failed);
        final anyPublished =
            platformResults.any((r) => r.status == PostStatus.published);
        final anyPublishing =
            platformResults.any((r) => r.status == PostStatus.publishing);

        if (allPublished) {
          status = PostStatus.published;
        } else if (allFailed) {
          status = PostStatus.failed;
        } else if (anyFailed && anyPublished) {
          status = PostStatus.partial;
        } else if (anyPublishing &&
            (status == PostStatus.publishing ||
                status == PostStatus.draft ||
                status == PostStatus.published)) {
          status = PostStatus.publishing;
        } else if (anyFailed &&
            (status == PostStatus.publishing || status == PostStatus.draft)) {
          status = PostStatus.failed;
        }
      }
    }

    for (final flag in _platformFlags.entries) {
      final v = json[flag.key];
      if (v == true || v == 'true' || v == 1 || v == '1') {
        addPlatformId(flag.value);
      }
    }

    // Ensure every known platform id has a result row when we only have ids.
    if (platformResults.isEmpty && platforms.isNotEmpty) {
      for (final id in platforms) {
        platformResults.add(
          PostPlatformResult(
            platformId: id,
            status: status == PostStatus.failed
                ? PostStatus.failed
                : status == PostStatus.partial
                    ? PostStatus.published
                    : status,
          ),
        );
      }
    } else if (platformResults.isNotEmpty) {
      for (final id in platforms) {
        if (!platformResults.any((r) => r.platformId == id)) {
          platformResults.add(
            PostPlatformResult(platformId: id, status: status),
          );
        }
      }
    }

    final dateRaw = ApiJsonUtils.readString(json, [
      'scheduledAt',
      'publishAt',
      'publishedAt',
      'createdAt',
      'updatedAt',
    ]);
    final scheduledDate = dateRaw == null ? null : DateTime.tryParse(dateRaw)?.toLocal();
    String? publishLabel = dateRaw;
    if (scheduledDate != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final h = scheduledDate.hour;
      final m = scheduledDate.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      publishLabel =
          '${months[scheduledDate.month - 1]} ${scheduledDate.day} · $hour12:$m $period';
    }

    String? thumbnail = ApiJsonUtils.readString(json, [
      'thumbnail',
      'thumbnailUrl',
      'image',
      'mediaUrl',
      'fileUrl',
      'url',
    ]);
    var mediaIsVideo = false;
    final mediaUrls = <String>[];
    final media = json['media'] ?? json['files'] ?? json['attachments'];
    if (media is List && media.isNotEmpty) {
      // Sort by order when present.
      final items = [...media];
      items.sort((a, b) {
        if (a is! Map || b is! Map) return 0;
        final ao = a['order'];
        final bo = b['order'];
        final ai = ao is num ? ao.toInt() : 0;
        final bi = bo is num ? bo.toInt() : 0;
        return ai.compareTo(bi);
      });

      for (final item in items) {
        if (item is String && item.startsWith('http')) {
          mediaUrls.add(item);
          continue;
        }
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final type =
              (ApiJsonUtils.readString(map, ['type', 'mediaType', 'mimeType']) ??
                      '')
                  .toLowerCase();
          final url = ApiJsonUtils.readString(map, [
            'url',
            'fileUrl',
            'thumbnail',
            'path',
            'src',
          ]);
          if (url == null || url.isEmpty || !url.startsWith('http')) continue;
          mediaUrls.add(url);
          if (type.contains('video') || _looksLikeVideoUrl(url)) {
            mediaIsVideo = true;
          }
        }
      }
    }

    if (mediaUrls.isNotEmpty) {
      thumbnail ??= mediaUrls.first;
    }
    if (!mediaIsVideo && thumbnail != null) {
      mediaIsVideo = _looksLikeVideoUrl(thumbnail);
    }
    // Mixed: if any video URL, treat as video (player for first).
    if (!mediaIsVideo) {
      mediaIsVideo = mediaUrls.any(_looksLikeVideoUrl);
    }

    return PostModel(
      id: ApiJsonUtils.readString(json, ['id', 'postId', 'uuid', '_id']) ?? '',
      title: ApiJsonUtils.readString(json, ['title']) ?? 'Untitled',
      caption: ApiJsonUtils.readString(json, ['caption', 'content', 'body']) ?? '',
      platforms: platforms,
      status: status,
      publishAt: publishLabel,
      thumbnail: thumbnail,
      mediaUrls: mediaUrls,
      mediaIsVideo: mediaIsVideo,
      scheduledDate: scheduledDate,
      platformResults: platformResults,
    );
  }

  static bool _looksLikeVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.m4v') ||
        lower.contains('.webm') ||
        lower.contains('.avi') ||
        lower.contains('/video/');
  }

  /// Infer brand when API omits `provider` but includes platform-specific ids.
  static String? _inferProviderFromMetadata(
    Map<String, dynamic>? meta,
    Map<String, dynamic> row,
  ) {
    bool has(String key) {
      final v = meta?[key] ?? row[key];
      return v != null && '$v'.isNotEmpty && '$v' != 'null';
    }

    if (has('boardId') || has('board_id') || has('pinterestBoardId')) {
      return 'pinterest';
    }
    if (has('youtubeChannelId') || has('channelId')) return 'youtube';
    if (has('googleBusinessProfileId') || has('locationId')) return 'google';
    if (has('instagramId') || has('igUserId')) return 'instagram';
    if (has('facebookPageId') || has('pageId')) return 'facebook';
    if (has('linkedinOrganizationId') || has('organizationId')) {
      return 'linkedin_organization';
    }
    if (has('tiktokAccountId')) return 'tiktok';
    if (has('snapchatProfileId') || has('publicProfileId')) return 'snapchat';
    return null;
  }

  static const _platformFlags = {
    'facebookPost': 'facebook',
    'instagramPost': 'instagram',
    'threadsPost': 'threads',
    'threadPost': 'threads',
    'linkedinPost': 'linkedin',
    'linkedinOrganizationPost': 'linkedin_organization',
    'linkedin_organizationPost': 'linkedin_organization',
    'tiktokPost': 'tiktok',
    'xPost': 'x',
    'twitterPost': 'x',
    'pinterestPost': 'pinterest',
    'youtubePost': 'youtube',
    'googleBusinessPost': 'google',
    'snapchatPost': 'snapchat',
  };

  static final _uuidLike = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String? _normalizePostPlatformId(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty || _uuidLike.hasMatch(v)) return null;
    return PlatformOAuth.uiIdFor(v);
  }
}

/// Maps UI platform ids ↔ OAuth `platform` query values.
///
/// Backend allows: google, meta, thread, x, linkedin, linkedin_organization,
/// pinterest, tiktok, snapchat (plus any newly added slugs).
abstract final class PlatformOAuth {
  static String platformFor(String platformId) => switch (platformId.toLowerCase()) {
        'facebook' || 'instagram' || 'meta' => 'meta',
        'youtube' || 'google' || 'google_business' => 'google',
        'twitter' || 'x' => 'x',
        'threads' || 'thread' => 'thread',
        'linkedin' => 'linkedin',
        'linkedin_organization' ||
        'linkedin-organization' ||
        'linkedin_org' ||
        'linkedin_page' ||
        'linkedinorganization' =>
          'linkedin_organization',
        'pinterest' => 'pinterest',
        'tiktok' => 'tiktok',
        'snapchat' || 'snap' => 'snapchat',
        _ => platformId.toLowerCase(),
      };

  /// Maps API platform back to app UI id(s).
  static String uiIdFor(String apiPlatform) => switch (apiPlatform.toLowerCase()) {
        'meta' => 'facebook',
        'twitter' => 'x',
        'thread' || 'threads' => 'threads',
        'google_business' => 'google',
        'snap' => 'snapchat',
        'linkedin-organization' ||
        'linkedin_org' ||
        'linkedin_page' ||
        'linkedinorganization' ||
        'linkedin_organization' =>
          'linkedin_organization',
        _ => apiPlatform.toLowerCase(),
      };
}

/// Maps UI platform ids to create-post multipart field names.
abstract final class PlatformPostFields {
  static const fieldByPlatform = {
    'facebook': 'facebookPost',
    'instagram': 'instagramPost',
    'threads': 'threadPost',
    'linkedin': 'linkedinPost',
    'linkedin_organization': 'linkedinOrganizationPost',
    'tiktok': 'tiktokPost',
    'x': 'xPost',
    'pinterest': 'pinterestPost',
    'youtube': 'youtubePost',
    'google': 'googleBusinessPost',
    'snapchat': 'snapchatPost',
  };
}

extension PlatformModelCatalog on PlatformModel {
  static PlatformModel fromCatalogJson(Map<String, dynamic> json) {
    final slugRaw =
        ApiJsonUtils.readString(json, ['slug', 'provider', 'platform']) ?? '';
    final uiId = PlatformOAuth.uiIdFor(slugRaw);
    final name = ApiJsonUtils.readString(json, ['name', 'title']) ??
        (uiId.isEmpty ? 'Platform' : uiId);
    final status =
        (ApiJsonUtils.readString(json, ['status', 'state']) ?? 'active')
            .toLowerCase();
    final connected = json['connected'] == true ||
        json['connected'] == 1 ||
        json['connected'] == 'true';
    final costRaw = json['creditCost'] ?? json['credit_cost'] ?? 0;
    final creditCost = costRaw is int
        ? costRaw
        : costRaw is num
            ? costRaw.toInt()
            : int.tryParse('$costRaw') ?? 0;

    return PlatformModel(
      id: uiId.isEmpty ? slugRaw.toLowerCase() : uiId,
      name: name,
      color: _brandColor(uiId.isEmpty ? slugRaw : uiId),
      accounts: const [],
      availabilityStatus: status,
      creditCost: creditCost,
      connected: connected,
      description: ApiJsonUtils.readString(json, ['description']),
    );
  }

  static List<PlatformModel> listFromApi(dynamic data) {
    final rows = ApiJsonUtils.extractList(
      data,
      keys: const ['platforms', 'data', 'items', 'results'],
    );
    final out = <PlatformModel>[];
    final seen = <String>{};
    for (final row in rows) {
      final p = fromCatalogJson(row);
      if (p.id.isEmpty || seen.contains(p.id)) continue;
      // Prefer concrete brands over generic "meta" when both exist.
      if (p.id == 'meta') continue;
      seen.add(p.id);
      out.add(p);
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  static int _brandColor(String id) {
    return switch (id.toLowerCase()) {
      'facebook' => 0xFF1877F2,
      'instagram' => 0xFFE1306C,
      'threads' || 'thread' => 0xFF000000,
      'linkedin' => 0xFF0A66C2,
      'linkedin_organization' => 0xFFD4AF37,
      'tiktok' => 0xFF010101,
      'x' || 'twitter' => 0xFF000000,
      'pinterest' => 0xFFE60023,
      'youtube' => 0xFFFF0000,
      'google' => 0xFF4285F4,
      'snapchat' => 0xFFFFFC00,
      _ => 0xFF64748B,
    };
  }
}
