import '../../core/network/api_json_utils.dart';
import 'models.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.plan,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? plan;

  factory UserProfile.fromJson(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final user = map['user'] is Map ? Map<String, dynamic>.from(map['user'] as Map) : map;
    return UserProfile(
      id: ApiJsonUtils.readString(user, ['id', 'uuid', 'userId']) ?? '',
      name: ApiJsonUtils.readString(user, ['name', 'fullName', 'displayName']) ?? 'User',
      email: ApiJsonUtils.readString(user, ['email']) ?? '',
      avatarUrl: ApiJsonUtils.readString(user, ['avatar', 'avatarUrl', 'photo', 'image']),
      plan: ApiJsonUtils.readString(user, ['plan', 'subscription', 'subscriptionPlan']),
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
      'failed' || 'error' => PostStatus.failed,
      'cancelled' || 'canceled' => PostStatus.cancelled,
      _ => PostStatus.draft,
    };

    // Prefer platform-level outcome when overall status is still mid-flight.
    final platformsRaw = json['platforms'] ?? json['channels'];
    if (platformsRaw is List && platformsRaw.isNotEmpty) {
      final platformStatuses = <String>[];
      for (final p in platformsRaw) {
        if (p is! Map) continue;
        final map = Map<String, dynamic>.from(p);
        final ps = ApiJsonUtils.readString(map, [
              'platformStatus',
              'status',
              'state',
            ])
            ?.toLowerCase();
        if (ps != null && ps.isNotEmpty) platformStatuses.add(ps);
      }
      if (platformStatuses.isNotEmpty) {
        final allPublished = platformStatuses.every(
          (s) => s == 'published' || s == 'success' || s == 'live',
        );
        final anyFailed = platformStatuses.any(
          (s) => s == 'failed' || s == 'error',
        );
        if (allPublished) {
          status = PostStatus.published;
        } else if (anyFailed &&
            (status == PostStatus.publishing || status == PostStatus.draft)) {
          status = PostStatus.failed;
        }
      }
    }

    final platforms = <String>[];
    void addPlatform(String? raw) {
      if (raw == null || raw.isEmpty) return;
      final normalized = _normalizePostPlatformId(raw);
      if (normalized == null || platforms.contains(normalized)) return;
      platforms.add(normalized);
    }

    if (platformsRaw is List) {
      for (final p in platformsRaw) {
        if (p is String) {
          addPlatform(p);
        } else if (p is Map) {
          final map = Map<String, dynamic>.from(p);
          // Prefer metadata.provider — row `id` is a UUID, not the brand.
          String? provider;
          final meta = map['metadata'];
          if (meta is Map) {
            provider = ApiJsonUtils.readString(
              Map<String, dynamic>.from(meta),
              ['provider', 'platform', 'slug', 'name'],
            );
          }
          provider ??= ApiJsonUtils.readString(map, [
            'provider',
            'platform',
            'slug',
            'name',
          ]);
          addPlatform(provider);
        }
      }
    }

    for (final flag in _platformFlags.entries) {
      final v = json[flag.key];
      if (v == true || v == 'true' || v == 1 || v == '1') {
        addPlatform(flag.value);
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
    if (thumbnail == null || thumbnail.isEmpty) {
      final media = json['media'] ?? json['files'] ?? json['attachments'];
      if (media is List && media.isNotEmpty) {
        final first = media.first;
        if (first is String && first.startsWith('http')) {
          thumbnail = first;
        } else if (first is Map) {
          thumbnail = ApiJsonUtils.readString(Map<String, dynamic>.from(first), [
            'url',
            'fileUrl',
            'thumbnail',
            'path',
            'src',
          ]);
        }
      }
    }

    return PostModel(
      id: ApiJsonUtils.readString(json, ['id', 'postId', 'uuid', '_id']) ?? '',
      title: ApiJsonUtils.readString(json, ['title']) ?? 'Untitled',
      caption: ApiJsonUtils.readString(json, ['caption', 'content', 'body']) ?? '',
      platforms: platforms,
      status: status,
      publishAt: publishLabel,
      thumbnail: thumbnail,
      scheduledDate: scheduledDate,
    );
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
/// pinterest, tiktok (plus any newly added slugs).
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
        _ => platformId.toLowerCase(),
      };

  /// Maps API platform back to app UI id(s).
  static String uiIdFor(String apiPlatform) => switch (apiPlatform.toLowerCase()) {
        'meta' => 'facebook',
        'twitter' => 'x',
        'thread' || 'threads' => 'threads',
        'google_business' => 'google',
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
  };
}
