import 'package:equatable/equatable.dart';

enum PostStatus {
  draft,
  scheduled,
  publishing,
  published,
  /// Some platforms published, at least one failed.
  partial,
  failed,
  cancelled,
}

class PlatformModel extends Equatable {
  const PlatformModel({
    required this.id,
    required this.name,
    required this.color,
    required this.accounts,
    this.availabilityStatus = 'active',
    this.creditCost = 0,
    this.connected = false,
    this.description,
  });

  final String id;
  final String name;
  final int color;
  final List<String> accounts;
  /// API `status`: active | comingSoon
  final String availabilityStatus;
  final int creditCost;
  final bool connected;
  final String? description;

  bool get isComingSoon {
    final s = availabilityStatus.toLowerCase();
    return s == 'comingsoon' ||
        s == 'coming_soon' ||
        s == 'coming-soon' ||
        s == 'soon';
  }

  bool get isActive => !isComingSoon;

  /// Sort key: connected (0) → not connected (1) → coming soon (2).
  int connectionSortRank([Set<String> connectedIds = const {}]) {
    if (isComingSoon) return 2;
    if (connected || connectedIds.contains(id)) return 0;
    return 1;
  }

  PlatformModel copyWith({
    String? id,
    String? name,
    int? color,
    List<String>? accounts,
    String? availabilityStatus,
    int? creditCost,
    bool? connected,
    String? description,
  }) =>
      PlatformModel(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        accounts: accounts ?? this.accounts,
        availabilityStatus: availabilityStatus ?? this.availabilityStatus,
        creditCost: creditCost ?? this.creditCost,
        connected: connected ?? this.connected,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        accounts,
        availabilityStatus,
        creditCost,
        connected,
        description,
      ];
}

extension PlatformListSorting on List<PlatformModel> {
  /// Connected first, then not connected, then coming soon (name as tiebreaker).
  List<PlatformModel> sortedByConnection([
    Set<String> connectedIds = const {},
  ]) {
    final copy = [...this];
    copy.sort((a, b) {
      final rank = a
          .connectionSortRank(connectedIds)
          .compareTo(b.connectionSortRank(connectedIds));
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }
}

class WalletInfo extends Equatable {
  const WalletInfo({
    this.id,
    this.credits = 0,
    this.freeCredits = 0,
  });

  final String? id;
  final int credits;
  final int freeCredits;

  int get totalCredits => credits + freeCredits;

  factory WalletInfo.fromJson(dynamic data) {
    Map<String, dynamic> map = {};
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
      if (map['wallet'] is Map) {
        map = Map<String, dynamic>.from(map['wallet'] as Map);
      } else if (map['user'] is Map) {
        final user = Map<String, dynamic>.from(map['user'] as Map);
        if (user['wallet'] is Map) {
          map = Map<String, dynamic>.from(user['wallet'] as Map);
        }
      } else if (map['data'] is Map) {
        final nested = Map<String, dynamic>.from(map['data'] as Map);
        if (nested['wallet'] is Map) {
          map = Map<String, dynamic>.from(nested['wallet'] as Map);
        } else {
          map = nested;
        }
      }
    }
    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return WalletInfo(
      id: map['id']?.toString(),
      credits: readInt(map['credits']),
      freeCredits: readInt(map['freeCredits'] ?? map['free_credits']),
    );
  }

  @override
  List<Object?> get props => [id, credits, freeCredits];
}

/// Per-platform publish outcome from API `platforms[]`.
class PostPlatformResult extends Equatable {
  const PostPlatformResult({
    required this.platformId,
    required this.status,
    this.errorMessage,
    this.platformPostId,
  });

  final String platformId;
  final PostStatus status;
  final String? errorMessage;
  final String? platformPostId;

  bool get isFailed => status == PostStatus.failed;
  bool get isPublished => status == PostStatus.published;

  PostPlatformResult copyWith({
    String? platformId,
    PostStatus? status,
    String? errorMessage,
    String? platformPostId,
  }) =>
      PostPlatformResult(
        platformId: platformId ?? this.platformId,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        platformPostId: platformPostId ?? this.platformPostId,
      );

  @override
  List<Object?> get props => [platformId, status, errorMessage, platformPostId];
}

class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.title,
    required this.caption,
    required this.platforms,
    required this.status,
    this.publishAt,
    this.thumbnail,
    this.mediaUrls = const [],
    this.mediaIsVideo = false,
    this.scheduledDate,
    this.platformResults = const [],
  });

  final String id;
  final String title;
  final String caption;
  final List<String> platforms;
  final PostStatus status;
  final String? publishAt;
  /// First media URL (for list thumbnails).
  final String? thumbnail;
  /// All media URLs (images or single video).
  final List<String> mediaUrls;
  final bool mediaIsVideo;
  final DateTime? scheduledDate;
  /// Per-platform outcomes (empty when API only sends ids).
  final List<PostPlatformResult> platformResults;

  List<String> get displayMediaUrls {
    if (mediaUrls.isNotEmpty) return mediaUrls;
    if (thumbnail != null && thumbnail!.isNotEmpty) return [thumbnail!];
    return const [];
  }

  bool get hasPartialFailure =>
      status == PostStatus.partial ||
      (platformResults.any((p) => p.isFailed) &&
          platformResults.any((p) => p.isPublished));

  List<PostPlatformResult> get failedPlatforms =>
      platformResults.where((p) => p.isFailed).toList();

  /// Prefer detailed results; fall back to plain platform ids.
  List<PostPlatformResult> get displayPlatformResults {
    if (platformResults.isNotEmpty) return platformResults;
    return platforms
        .map(
          (id) => PostPlatformResult(
            platformId: id,
            status: status == PostStatus.failed
                ? PostStatus.failed
                : status == PostStatus.publishing
                    ? PostStatus.publishing
                    : status == PostStatus.scheduled
                        ? PostStatus.scheduled
                        : status == PostStatus.draft
                            ? PostStatus.draft
                            : PostStatus.published,
          ),
        )
        .toList();
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? caption,
    List<String>? platforms,
    PostStatus? status,
    String? publishAt,
    String? thumbnail,
    List<String>? mediaUrls,
    bool? mediaIsVideo,
    DateTime? scheduledDate,
    List<PostPlatformResult>? platformResults,
  }) =>
      PostModel(
        id: id ?? this.id,
        title: title ?? this.title,
        caption: caption ?? this.caption,
        platforms: platforms ?? this.platforms,
        status: status ?? this.status,
        publishAt: publishAt ?? this.publishAt,
        thumbnail: thumbnail ?? this.thumbnail,
        mediaUrls: mediaUrls ?? this.mediaUrls,
        mediaIsVideo: mediaIsVideo ?? this.mediaIsVideo,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        platformResults: platformResults ?? this.platformResults,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        caption,
        platforms,
        status,
        publishAt,
        thumbnail,
        mediaUrls,
        mediaIsVideo,
        scheduledDate,
        platformResults,
      ];
}

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String time;
  final bool read;

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
      );

  @override
  List<Object?> get props => [id, type, title, body, time, read];
}

class PlanModel extends Equatable {
  const PlanModel({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.current = false,
    this.popular = false,
  });

  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool current;
  final bool popular;

  @override
  List<Object?> get props => [name, price, period, features, current, popular];
}

class CalEvent extends Equatable {
  const CalEvent({
    required this.title,
    required this.platforms,
    required this.time,
  });

  final String title;
  final List<String> platforms;
  final String time;

  @override
  List<Object?> get props => [title, platforms, time];
}

class TrendPoint extends Equatable {
  const TrendPoint({required this.date, required this.pub, required this.fail});
  final String date;
  final double pub;
  final double fail;
  @override
  List<Object?> get props => [date, pub, fail];
}

class FreqPoint extends Equatable {
  const FreqPoint({required this.day, required this.v});
  final String day;
  final double v;
  @override
  List<Object?> get props => [day, v];
}

class PieSlice extends Equatable {
  const PieSlice({required this.name, required this.value, required this.color});
  final String name;
  final double value;
  final int color;
  @override
  List<Object?> get props => [name, value, color];
}
