import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/posts_refresh_bus.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_aspect_crop.dart';
import '../../../data/models/api_models.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/integrations_repository.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/social_repository.dart';

/// Matches Apidog `postStatus` enum: Draft | Publishing | Scheduled
enum CreatePostStatus { draft, publishing, scheduled }

extension CreatePostStatusApi on CreatePostStatus {
  String get apiValue => switch (this) {
        CreatePostStatus.draft => 'Draft',
        CreatePostStatus.publishing => 'Publishing',
        CreatePostStatus.scheduled => 'Scheduled',
      };

  String get actionLabel => switch (this) {
        CreatePostStatus.draft => 'Save draft',
        CreatePostStatus.publishing => 'Publish',
        CreatePostStatus.scheduled => 'Schedule',
      };

  String get successMessage => switch (this) {
        CreatePostStatus.draft => 'Draft saved',
        CreatePostStatus.publishing => 'Post published successfully',
        CreatePostStatus.scheduled => 'Post scheduled successfully',
      };
}

class CreatePostState extends Equatable {
  const CreatePostState({
    this.step = 0,
    this.title = '',
    this.caption = '',
    this.mediaFiles = const [],
    this.mediaOriginals = const [],
    this.mediaIsVideo = false,
    this.mediaAspectRatio = MediaAspectRatioPreset.square,
    this.mediaProcessing = false,
    this.selectedPlatforms = const {},
    this.availablePlatforms = const [],
    this.connectedAccounts = const [],
    this.postStatus = CreatePostStatus.publishing,
    this.scheduledAt,
    this.facebookPages = const [],
    this.instagramAccounts = const [],
    this.pinterestBoards = const [],
    this.youtubeChannels = const [],
    this.googleProfiles = const [],
    this.facebookPageId,
    this.instagramId,
    this.pinterestBoardId,
    this.youtubeChannelId,
    this.googleBusinessProfileId,
    this.publishing = false,
    this.error,
  });

  final int step;
  final String title;
  final String caption;
  final List<File> mediaFiles;
  /// Uncropped source images (same order as [mediaFiles] when images).
  final List<File> mediaOriginals;
  final bool mediaIsVideo;
  final MediaAspectRatioPreset mediaAspectRatio;
  final bool mediaProcessing;
  final Set<String> selectedPlatforms;
  final List<PlatformModel> availablePlatforms;
  final List<SocialAccount> connectedAccounts;
  final CreatePostStatus postStatus;
  final DateTime? scheduledAt;
  final List<NamedResource> facebookPages;
  final List<NamedResource> instagramAccounts;
  final List<NamedResource> pinterestBoards;
  final List<NamedResource> youtubeChannels;
  final List<NamedResource> googleProfiles;
  final String? facebookPageId;
  final String? instagramId;
  final String? pinterestBoardId;
  final String? youtubeChannelId;
  final String? googleBusinessProfileId;
  final bool publishing;
  final String? error;

  CreatePostState copyWith({
    int? step,
    String? title,
    String? caption,
    List<File>? mediaFiles,
    List<File>? mediaOriginals,
    bool? mediaIsVideo,
    MediaAspectRatioPreset? mediaAspectRatio,
    bool? mediaProcessing,
    Set<String>? selectedPlatforms,
    List<PlatformModel>? availablePlatforms,
    List<SocialAccount>? connectedAccounts,
    CreatePostStatus? postStatus,
    DateTime? scheduledAt,
    List<NamedResource>? facebookPages,
    List<NamedResource>? instagramAccounts,
    List<NamedResource>? pinterestBoards,
    List<NamedResource>? youtubeChannels,
    List<NamedResource>? googleProfiles,
    String? facebookPageId,
    String? instagramId,
    String? pinterestBoardId,
    String? youtubeChannelId,
    String? googleBusinessProfileId,
    bool? publishing,
    String? error,
    bool clearError = false,
    bool clearMediaOriginals = false,
  }) =>
      CreatePostState(
        step: step ?? this.step,
        title: title ?? this.title,
        caption: caption ?? this.caption,
        mediaFiles: mediaFiles ?? this.mediaFiles,
        mediaOriginals: clearMediaOriginals
            ? const []
            : (mediaOriginals ?? this.mediaOriginals),
        mediaIsVideo: mediaIsVideo ?? this.mediaIsVideo,
        mediaAspectRatio: mediaAspectRatio ?? this.mediaAspectRatio,
        mediaProcessing: mediaProcessing ?? this.mediaProcessing,
        selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
        availablePlatforms: availablePlatforms ?? this.availablePlatforms,
        connectedAccounts: connectedAccounts ?? this.connectedAccounts,
        postStatus: postStatus ?? this.postStatus,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        facebookPages: facebookPages ?? this.facebookPages,
        instagramAccounts: instagramAccounts ?? this.instagramAccounts,
        pinterestBoards: pinterestBoards ?? this.pinterestBoards,
        youtubeChannels: youtubeChannels ?? this.youtubeChannels,
        googleProfiles: googleProfiles ?? this.googleProfiles,
        facebookPageId: facebookPageId ?? this.facebookPageId,
        instagramId: instagramId ?? this.instagramId,
        pinterestBoardId: pinterestBoardId ?? this.pinterestBoardId,
        youtubeChannelId: youtubeChannelId ?? this.youtubeChannelId,
        googleBusinessProfileId:
            googleBusinessProfileId ?? this.googleBusinessProfileId,
        publishing: publishing ?? this.publishing,
        error: clearError ? null : (error ?? this.error),
      );

  String get scheduleDateLabel {
    if (scheduledAt == null) return 'Select date';
    final d = scheduledAt!;
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String get scheduleTimeLabel {
    if (scheduledAt == null) return 'Select time';
    final h = scheduledAt!.hour;
    final m = scheduledAt!.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  bool get canNext => switch (step) {
        0 =>
          title.trim().isNotEmpty &&
              caption.trim().isNotEmpty &&
              !mediaProcessing,
        1 => selectedPlatforms.isNotEmpty,
        2 => postStatus != CreatePostStatus.scheduled || scheduledAt != null,
        _ => !publishing,
      };

  /// Sum of credit costs for currently selected platforms.
  int get selectedCreditsCost {
    var total = 0;
    for (final p in availablePlatforms) {
      if (selectedPlatforms.contains(p.id)) {
        total += p.creditCost < 0 ? 0 : p.creditCost;
      }
    }
    return total;
  }

  @override
  List<Object?> get props => [
        step,
        title,
        caption,
        mediaFiles,
        mediaOriginals,
        mediaIsVideo,
        mediaAspectRatio,
        mediaProcessing,
        selectedPlatforms,
        availablePlatforms,
        connectedAccounts,
        postStatus,
        scheduledAt,
        facebookPages,
        instagramAccounts,
        pinterestBoards,
        youtubeChannels,
        googleProfiles,
        facebookPageId,
        instagramId,
        pinterestBoardId,
        youtubeChannelId,
        googleBusinessProfileId,
        publishing,
        error,
      ];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit({
    PostsRepository? postsRepo,
    IntegrationsRepository? integrationsRepo,
    SocialRepository? socialRepo,
  })  : _postsRepo = postsRepo ?? PostsRepository(),
        _integrationsRepo = integrationsRepo ?? IntegrationsRepository(),
        _socialRepo = socialRepo ?? SocialRepository(),
        super(
          CreatePostState(
            scheduledAt: DateTime.now().add(const Duration(days: 1)),
            availablePlatforms: const [],
          ),
        ) {
    _loadPlatformsAndResources();
  }

  final PostsRepository _postsRepo;
  final IntegrationsRepository _integrationsRepo;
  final SocialRepository _socialRepo;

  Future<void> _loadPlatformsAndResources() async {
    try {
      final accounts = await _socialRepo.fetchSocialAccounts();
      final connected = accounts.where((a) => a.isConnected).toList();
      final connectedIds = _socialRepo.connectedPlatformIds(accounts);
      var catalog = <PlatformModel>[];
      try {
        catalog = await _socialRepo.fetchPlatformCatalog();
      } catch (_) {}

      final available = catalog.isNotEmpty
          ? catalog
              .map(
                (p) => p.copyWith(
                  connected: connectedIds.contains(p.id),
                  accounts: _socialRepo
                      .accountsForPlatform(p.id, connected)
                      .map((a) => a.previewLabel)
                      .toList(),
                ),
              )
              .where((p) => p.isActive && connectedIds.contains(p.id))
              .toList()
              .sortedByConnection(connectedIds)
          : _socialRepo
              .mergePlatforms(accounts)
              .where((p) => connectedIds.contains(p.id))
              .toList()
              .sortedByConnection(connectedIds);
      if (!isClosed) {
        emit(
          state.copyWith(
            availablePlatforms: available,
            connectedAccounts: connected,
          ),
        );
      }
    } catch (e) {
      AppLogger.d('Create post platforms load: $e');
    }

    await Future.wait([
      _loadMeta(),
      _loadPinterest(),
      _loadYoutube(),
      _loadGoogleBusiness(),
    ]);
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await _integrationsRepo.fetchMetaPages();
      if (isClosed) return;
      emit(
        state.copyWith(
          facebookPages: meta.pages,
          instagramAccounts: meta.instagramAccounts,
          facebookPageId: state.facebookPageId ??
              (meta.pages.isNotEmpty ? meta.pages.first.id : null),
          instagramId: state.instagramId ??
              (meta.instagramAccounts.isNotEmpty
                  ? meta.instagramAccounts.first.id
                  : null),
        ),
      );
    } catch (e) {
      AppLogger.d('Meta pages unavailable: $e');
    }
  }

  Future<void> _loadPinterest() async {
    try {
      final boards = await _integrationsRepo.fetchPinterestBoards();
      if (isClosed) return;
      emit(
        state.copyWith(
          pinterestBoards: boards,
          pinterestBoardId: state.pinterestBoardId ??
              (boards.isNotEmpty ? boards.first.id : null),
        ),
      );
    } catch (e) {
      AppLogger.d('Pinterest boards unavailable: $e');
    }
  }

  Future<void> _loadYoutube() async {
    try {
      final channels = await _integrationsRepo.fetchYoutubeChannels();
      if (isClosed) return;
      emit(
        state.copyWith(
          youtubeChannels: channels,
          youtubeChannelId: state.youtubeChannelId ??
              (channels.isNotEmpty ? channels.first.id : null),
        ),
      );
    } catch (e) {
      AppLogger.d('YouTube channels unavailable: $e');
    }
  }

  Future<void> _loadGoogleBusiness() async {
    try {
      final profiles = await _integrationsRepo.fetchGoogleBusinessProfiles();
      if (isClosed) return;
      emit(
        state.copyWith(
          googleProfiles: profiles,
          googleBusinessProfileId: state.googleBusinessProfileId ??
              (profiles.isNotEmpty ? profiles.first.id : null),
        ),
      );
    } catch (e) {
      AppLogger.d('Google Business profiles unavailable: $e');
    }
  }

  void setTitle(String v) => emit(state.copyWith(title: v, clearError: true));
  void setCaption(String v) => emit(state.copyWith(caption: v, clearError: true));

  static const maxImages = 5;
  static const maxFileBytes = 90 * 1024 * 1024; // 90 MB
  static const maxVideoDuration = Duration(seconds: 30);

  static bool isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.3gp');
  }

  bool get hasVideo =>
      state.mediaIsVideo || state.mediaFiles.any((f) => isVideoPath(f.path));

  bool isVideoFile(File file) =>
      state.mediaIsVideo || isVideoPath(file.path);

  /// Returns error message on failure, otherwise null.
  /// Pass [asVideo] when picked via video picker (path may lack extension).
  Future<String?> addMediaFiles(
    List<File> files, {
    bool asVideo = false,
  }) async {
    if (files.isEmpty) return null;

    final videos = asVideo
        ? files
        : files.where((f) => isVideoPath(f.path)).toList();
    final images = asVideo
        ? <File>[]
        : files.where((f) => !isVideoPath(f.path)).toList();

    if (videos.isNotEmpty && images.isNotEmpty) {
      return 'Choose either one video or up to $maxImages images — not both.';
    }

    if (videos.length > 1) {
      return 'Only one video can be uploaded.';
    }

    if (videos.isNotEmpty) {
      final video = videos.first;
      final size = await video.length();
      if (size > maxFileBytes) {
        return 'Video must be 90 MB or smaller.';
      }
      emit(
        state.copyWith(
          mediaFiles: [video],
          mediaOriginals: const [],
          clearMediaOriginals: true,
          mediaIsVideo: true,
          mediaAspectRatio: MediaAspectRatioPreset.square,
          clearError: true,
        ),
      );
      return null;
    }

    if (hasVideo) {
      return 'Remove the video first to add images.';
    }

    final originals = List<File>.from(state.mediaOriginals);
    if (originals.isEmpty && state.mediaFiles.isNotEmpty && !state.mediaIsVideo) {
      originals.addAll(state.mediaFiles);
    }

    for (final image in images) {
      if (originals.length >= maxImages) {
        final applied = await _applyAspectToOriginals(originals);
        emit(
          state.copyWith(
            mediaFiles: applied,
            mediaOriginals: originals,
            mediaIsVideo: false,
            clearError: true,
          ),
        );
        return 'Maximum $maxImages images allowed.';
      }
      final size = await image.length();
      if (size > maxFileBytes) {
        return 'Each image must be 90 MB or smaller.';
      }
      originals.add(image);
    }

    final applied = await _applyAspectToOriginals(originals);
    emit(
      state.copyWith(
        mediaFiles: applied,
        mediaOriginals: originals,
        mediaIsVideo: false,
        clearError: true,
      ),
    );
    return null;
  }

  Future<List<File>> _applyAspectToOriginals(List<File> originals) async {
    if (originals.isEmpty) {
      return List<File>.from(originals);
    }
    try {
      return await cropImageFilesToAspectRatio(
        originals,
        state.mediaAspectRatio.ratio,
      );
    } catch (e, st) {
      AppLogger.e('Aspect crop failed', e, st);
      return List<File>.from(originals);
    }
  }

  Future<void> setMediaAspectRatio(MediaAspectRatioPreset preset) async {
    if (state.mediaIsVideo || state.mediaProcessing) return;
    if (state.mediaAspectRatio == preset) return;

    final originals = state.mediaOriginals.isNotEmpty
        ? state.mediaOriginals
        : (state.mediaIsVideo ? const <File>[] : state.mediaFiles);
    if (originals.isEmpty) {
      emit(state.copyWith(mediaAspectRatio: preset));
      return;
    }

    emit(state.copyWith(mediaProcessing: true, mediaAspectRatio: preset));
    try {
      final files = await cropImageFilesToAspectRatio(originals, preset.ratio);
      if (isClosed) return;
      emit(
        state.copyWith(
          mediaFiles: files,
          mediaOriginals: originals,
          mediaAspectRatio: preset,
          mediaProcessing: false,
          clearError: true,
        ),
      );
    } catch (e, st) {
      AppLogger.e('setMediaAspectRatio failed', e, st);
      if (!isClosed) {
        emit(
          state.copyWith(
            mediaProcessing: false,
            error: 'Could not apply aspect ratio. Try again.',
          ),
        );
      }
    }
  }

  void removeMediaAt(int index) {
    final nextFiles = List<File>.from(state.mediaFiles)..removeAt(index);
    final nextOriginals = List<File>.from(
      state.mediaOriginals.isNotEmpty
          ? state.mediaOriginals
          : state.mediaFiles,
    );
    if (index >= 0 && index < nextOriginals.length) {
      nextOriginals.removeAt(index);
    }
    emit(
      state.copyWith(
        mediaFiles: nextFiles,
        mediaOriginals: nextOriginals,
        mediaIsVideo: nextFiles.isNotEmpty && state.mediaIsVideo,
        mediaAspectRatio: nextFiles.isEmpty
            ? MediaAspectRatioPreset.square
            : state.mediaAspectRatio,
        clearError: true,
      ),
    );
  }

  /// Saves a user-adjusted crop for one image (already at the selected ratio).
  void updateMediaCropAt(int index, File croppedFile) {
    if (state.mediaIsVideo) return;
    final files = List<File>.from(state.mediaFiles);
    if (index < 0 || index >= files.length) return;
    files[index] = croppedFile;
    emit(state.copyWith(mediaFiles: files, clearError: true));
  }

  File sourceFileForCropAt(int index) {
    if (state.mediaOriginals.isNotEmpty &&
        index >= 0 &&
        index < state.mediaOriginals.length) {
      return state.mediaOriginals[index];
    }
    return state.mediaFiles[index];
  }

  void togglePlatform(String id) {
    final next = Set<String>.from(state.selectedPlatforms);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    emit(state.copyWith(selectedPlatforms: next, clearError: true));
  }

  void setPostStatus(CreatePostStatus status) =>
      emit(state.copyWith(postStatus: status, clearError: true));

  void setScheduledAt(DateTime v) => emit(state.copyWith(scheduledAt: v, clearError: true));
  void setFacebookPageId(String? id) =>
      emit(state.copyWith(facebookPageId: id, clearError: true));
  void setInstagramId(String? id) =>
      emit(state.copyWith(instagramId: id, clearError: true));
  void setPinterestBoardId(String? id) =>
      emit(state.copyWith(pinterestBoardId: id, clearError: true));
  void setYoutubeChannelId(String? id) =>
      emit(state.copyWith(youtubeChannelId: id, clearError: true));
  void setGoogleBusinessProfileId(String? id) =>
      emit(state.copyWith(googleBusinessProfileId: id, clearError: true));

  void next() {
    if (!state.canNext || state.step >= 3) return;
    AppLogger.event('create_next', {'step': state.step + 1});
    emit(state.copyWith(step: state.step + 1));
  }

  void back() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  Future<bool> publish() async {
    if (state.publishing) return false;

    final selected = state.selectedPlatforms;
    final needsMedia = selected.contains('instagram') ||
        selected.contains('pinterest') ||
        selected.contains('tiktok') ||
        selected.contains('youtube') ||
        selected.contains('snapchat');
    if (needsMedia && state.mediaFiles.isEmpty) {
      final label = selected.contains('instagram')
          ? 'Instagram'
          : selected.contains('pinterest')
              ? 'Pinterest'
              : selected.contains('youtube')
                  ? 'YouTube'
                  : selected.contains('snapchat')
                      ? 'Snapchat'
                      : 'this platform';
      emit(
        state.copyWith(
          error:
              'Add at least one image or video — required for $label.',
        ),
      );
      return false;
    }

    emit(state.copyWith(publishing: true, clearError: true));
    try {
      await _postsRepo.createPost(
        title: state.title.trim(),
        caption: state.caption.trim(),
        platformIds: selected,
        postStatus: state.postStatus.apiValue,
        scheduledAtIso: state.postStatus == CreatePostStatus.scheduled
            ? state.scheduledAt?.toUtc().toIso8601String()
            : null,
        facebookPageId: (selected.contains('facebook') ||
                selected.contains('instagram'))
            ? state.facebookPageId
            : null,
        pinterestBoardId:
            selected.contains('pinterest') ? state.pinterestBoardId : null,
        youtubeChannelId:
            selected.contains('youtube') ? state.youtubeChannelId : null,
        googleBusinessProfileId:
            selected.contains('google') ? state.googleBusinessProfileId : null,
        files: state.mediaFiles,
        treatAsVideo: state.mediaIsVideo,
      );
      PostsRefreshBus.instance.ping();
      emit(state.copyWith(publishing: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(publishing: false, error: e.message));
      return false;
    } catch (e, st) {
      AppLogger.e('Publish failed', e, st);
      emit(state.copyWith(publishing: false, error: 'Could not publish. Try again.'));
      return false;
    }
  }
}
