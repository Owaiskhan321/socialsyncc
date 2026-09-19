import '../models/models.dart';

/// Parses mixed API date strings into [DateTime].
DateTime? parseApiDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();

  // Common display formats from older payloads
  final formats = [
    RegExp(r'^(\w{3})\s+(\d{1,2})(?:\s*[·•]\s*|\s+)(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false),
  ];
  for (final _ in formats) {
    // fallback: ignore non-ISO
  }
  return null;
}

String formatTimeLabel(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

String formatShortDate(DateTime dt) {
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
  return '${months[dt.month - 1]} ${dt.day} · ${formatTimeLabel(dt)}';
}

String greetingForNow([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Builds calendar day → events map from live posts for a given month.
Map<int, List<CalEvent>> calendarEventsForMonth({
  required List<PostModel> posts,
  required int year,
  required int month,
}) {
  final map = <int, List<CalEvent>>{};
  for (final post in posts) {
    final dt = post.scheduledDate ?? parseApiDate(post.publishAt);
    if (dt == null) continue;
    if (dt.year != year || dt.month != month) continue;
    map.putIfAbsent(dt.day, () => []).add(
          CalEvent(
            title: post.title,
            platforms: post.platforms,
            time: formatTimeLabel(dt),
          ),
        );
  }
  return map;
}

/// Analytics from `GET /posts/analytics` (with local posts fallback).
class LiveAnalytics {
  const LiveAnalytics({
    required this.published,
    required this.failed,
    required this.scheduled,
    required this.drafts,
    required this.trend,
    required this.freq,
    required this.pie,
    this.totalPosts = 0,
    this.totalPostsChangePercent = 0,
    this.publishedPercent = 0,
    this.nextScheduledAt,
    this.range,
    this.timezone,
  });

  final int published;
  final int failed;
  final int scheduled;
  final int drafts;
  final int totalPosts;
  final int totalPostsChangePercent;
  final int publishedPercent;
  final String? nextScheduledAt;
  final String? range;
  final String? timezone;
  final List<TrendPoint> trend;
  final List<FreqPoint> freq;
  final List<PieSlice> pie;

  factory LiveAnalytics.fromApi(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};

    int readInt(Map<String, dynamic> map, String key, [int fallback = 0]) {
      final v = map[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    const colors = {
      'facebook': 0xFF1877F2,
      'instagram': 0xFFE1306C,
      'linkedin': 0xFF0A66C2,
      'linkedin_organization': 0xFFD4AF37,
      'tiktok': 0xFF010101,
      'x': 0xFF555555,
      'pinterest': 0xFFE60023,
      'youtube': 0xFFFF0000,
      'google': 0xFF4285F4,
      'threads': 0xFF000000,
      'meta': 0xFF1877F2,
      'snapchat': 0xFFFFFC00,
    };

    final trendRaw = json['publishingTrend'];
    final trend = <TrendPoint>[];
    if (trendRaw is List) {
      for (final item in trendRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        trend.add(
          TrendPoint(
            date: '${m['date'] ?? ''}',
            pub: (m['published'] is num) ? (m['published'] as num).toDouble() : 0.0,
            fail: (m['failed'] is num) ? (m['failed'] as num).toDouble() : 0.0,
          ),
        );
      }
    }

    final freqRaw = json['postingFrequency'];
    final freq = <FreqPoint>[];
    if (freqRaw is List) {
      for (final item in freqRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        freq.add(
          FreqPoint(
            day: '${m['day'] ?? ''}',
            v: (m['count'] is num) ? (m['count'] as num).toDouble() : 0.0,
          ),
        );
      }
    }

    final pieRaw = json['platformDistribution'];
    final pie = <PieSlice>[];
    if (pieRaw is List) {
      for (final item in pieRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final slug = '${m['slug'] ?? ''}'.toLowerCase();
        final name = '${m['platform'] ?? slug}'.trim();
        final count = (m['count'] is num) ? (m['count'] as num).toDouble() : 0.0;
        if (count <= 0 && name.isEmpty) continue;
        pie.add(
          PieSlice(
            name: name.isEmpty ? slug : name,
            value: count,
            color: colors[slug] ?? 0xFF64748B,
          ),
        );
      }
    }

    final published = readInt(summary, 'published');
    final failed = readInt(summary, 'failed');
    final scheduled = readInt(summary, 'scheduled');
    final total = readInt(summary, 'totalPosts');

    return LiveAnalytics(
      published: published,
      failed: failed,
      scheduled: scheduled,
      drafts: (total - published - failed - scheduled).clamp(0, total).toInt(),
      totalPosts: total,
      totalPostsChangePercent: readInt(summary, 'totalPostsChangePercent'),
      publishedPercent: readInt(summary, 'publishedPercent'),
      nextScheduledAt: summary['nextScheduledAt']?.toString(),
      range: json['range']?.toString(),
      timezone: json['timezone']?.toString(),
      trend: trend,
      freq: freq,
      pie: pie,
    );
  }

  factory LiveAnalytics.fromPosts(List<PostModel> posts, {int rangeDays = 30}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: rangeDays));

    var published = 0;
    var failed = 0;
    var scheduled = 0;
    var drafts = 0;

    final weekBuckets = <String, ({double pub, double fail})>{};
    final weekday = List<double>.filled(7, 0);
    final platformCounts = <String, int>{};

    for (final post in posts) {
      switch (post.status) {
        case PostStatus.published:
          published++;
        case PostStatus.partial:
          published++;
          failed++;
        case PostStatus.failed:
          failed++;
        case PostStatus.scheduled:
        case PostStatus.publishing:
          scheduled++;
        case PostStatus.draft:
        case PostStatus.cancelled:
          drafts++;
      }

      for (final p in post.platforms) {
        platformCounts[p] = (platformCounts[p] ?? 0) + 1;
      }

      final dt = post.scheduledDate ?? parseApiDate(post.publishAt) ?? now;
      if (dt.isBefore(start)) continue;

      weekday[dt.weekday - 1] += 1;

      final key = '${dt.month}/${dt.day}';
      final cur = weekBuckets[key] ?? (pub: 0.0, fail: 0.0);
      weekBuckets[key] = (
        pub: cur.pub +
            (post.status == PostStatus.published ||
                    post.status == PostStatus.partial
                ? 1
                : 0),
        fail: cur.fail +
            (post.status == PostStatus.failed ||
                    post.status == PostStatus.partial
                ? 1
                : 0),
      );
    }

    final sortedKeys = weekBuckets.keys.toList()
      ..sort((a, b) {
        final pa = a.split('/');
        final pb = b.split('/');
        final da = DateTime(now.year, int.parse(pa[0]), int.parse(pa[1]));
        final db = DateTime(now.year, int.parse(pb[0]), int.parse(pb[1]));
        return da.compareTo(db);
      });

    final trendList = sortedKeys.take(8).map((k) {
      final v = weekBuckets[k]!;
      return TrendPoint(date: k, pub: v.pub, fail: v.fail);
    }).toList();

    if (trendList.isEmpty) {
      trendList.add(
        TrendPoint(date: '—', pub: published.toDouble(), fail: failed.toDouble()),
      );
    }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final freq = List.generate(7, (i) => FreqPoint(day: days[i], v: weekday[i]));

    const colors = {
      'facebook': 0xFF1877F2,
      'instagram': 0xFFE1306C,
      'linkedin': 0xFF0A66C2,
      'linkedin_organization': 0xFFD4AF37,
      'tiktok': 0xFF010101,
      'x': 0xFF555555,
      'pinterest': 0xFFE60023,
      'youtube': 0xFFFF0000,
      'google': 0xFF4285F4,
      'threads': 0xFF000000,
      'snapchat': 0xFFFFFC00,
    };
    const names = {
      'facebook': 'Facebook',
      'instagram': 'Instagram',
      'linkedin': 'LinkedIn',
      'linkedin_organization': 'LinkedIn Org',
      'tiktok': 'TikTok',
      'x': 'X',
      'pinterest': 'Pinterest',
      'youtube': 'YouTube',
      'google': 'Google',
      'threads': 'Threads',
      'snapchat': 'Snapchat',
    };

    final pie = platformCounts.entries
        .map(
          (e) => PieSlice(
            name: names[e.key] ?? e.key,
            value: e.value.toDouble(),
            color: colors[e.key] ?? 0xFF64748B,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LiveAnalytics(
      published: published,
      failed: failed,
      scheduled: scheduled,
      drafts: drafts,
      totalPosts: published + failed + scheduled + drafts,
      trend: trendList,
      freq: freq,
      pie: pie,
    );
  }
}

/// Builds in-app notifications from live post status (no notifications API).
List<NotificationModel> notificationsFromPosts(List<PostModel> posts) {
  final items = <NotificationModel>[];
  for (final post in posts) {
    if (post.status == PostStatus.failed) {
      items.add(
        NotificationModel(
          id: 'fail-${post.id}',
          type: 'failed',
          title: 'Publishing Failed',
          body: post.failedPlatforms.isNotEmpty
              ? '"${post.title}" failed on ${post.failedPlatforms.map((p) => p.platformId).join(', ')}.'
              : '"${post.title}" failed to publish.',
          time: post.publishAt ?? 'Recently',
          read: false,
        ),
      );
    } else if (post.status == PostStatus.partial) {
      items.add(
        NotificationModel(
          id: 'partial-${post.id}',
          type: 'failed',
          title: 'Partially Published',
          body: post.failedPlatforms.isNotEmpty
              ? '"${post.title}" failed on ${post.failedPlatforms.map((p) => p.platformId).join(', ')}.'
              : '"${post.title}" published with some platform failures.',
          time: post.publishAt ?? 'Recently',
          read: false,
        ),
      );
    } else if (post.status == PostStatus.published) {
      items.add(
        NotificationModel(
          id: 'ok-${post.id}',
          type: 'success',
          title: 'Post Published',
          body: '"${post.title}" was published${post.platforms.isEmpty ? '' : ' to ${post.platforms.join(', ')}'}.',
          time: post.publishAt ?? 'Recently',
          read: true,
        ),
      );
    } else if (post.status == PostStatus.scheduled) {
      items.add(
        NotificationModel(
          id: 'sch-${post.id}',
          type: 'clock',
          title: 'Scheduled Post',
          body: '"${post.title}" is scheduled${post.publishAt != null ? ' for ${post.publishAt}' : ''}.',
          time: post.publishAt ?? 'Upcoming',
          read: false,
        ),
      );
    }
  }
  return items.take(30).toList();
}
