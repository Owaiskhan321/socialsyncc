import '../../core/logger/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_json_utils.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import 'app_data.dart';

class SocialRepository {
  SocialRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  /// Full social-accounts payload (connected + disconnected + counts).
  Future<SocialAccountsResult> fetchSocialAccountsResult() async {
    AppLogger.event('api_social_accounts');
    final res = await _client.get(ApiConstants.socialAccounts);
    return SocialAccountsResult.fromJson(res.data);
  }

  /// Connected accounts only (for home / create post / etc.).
  Future<List<SocialAccount>> fetchSocialAccounts() async {
    final result = await fetchSocialAccountsResult();
    return result.connected;
  }

  /// Returns OAuth URL to open in browser (from JSON or redirect Location).
  Future<String> fetchOAuthConnectUrl(String platformId) async {
    final platform = PlatformOAuth.platformFor(platformId);
    AppLogger.event('api_oauth_connect', {'platform': platform});
    final res = await _client.get(
      ApiConstants.oauthConnect,
      queryParameters: {'platform': platform},
    );

    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final url = ApiJsonUtils.readString(map, [
        'authorizationUrl',
        'authorization_url',
        'url',
        'redirectUrl',
        'authUrl',
        'link',
      ]);
      if (url != null && url.startsWith('http')) return url;
    }
    if (res.data is String && (res.data as String).startsWith('http')) {
      return res.data as String;
    }
    if (res.message.startsWith('http')) return res.message;

    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/';
    return '${base}oauth/connect?platform=$platform';
  }

  Future<void> disconnect(String platformId) async {
    final platform = PlatformOAuth.platformFor(platformId);
    AppLogger.event('api_oauth_disconnect', {'platform': platform});
    await _client.post(
      ApiConstants.oauthDisconnect,
      queryParameters: {'platform': platform},
    );
  }

  /// UI platform id for a social account slug (meta → facebook, thread → threads).
  String uiPlatformIdFor(SocialAccount account) =>
      _normalizeProvider(account.provider);

  /// Builds platform list for UI from static seed + live social accounts.
  List<PlatformModel> mergePlatforms(List<SocialAccount> accounts) {
    final byProvider = <String, List<String>>{};
    for (final a in accounts) {
      if (!a.isConnected) continue;
      final key = _normalizeProvider(a.provider);
      byProvider.putIfAbsent(key, () => []).add(a.name);
      if (key == 'facebook') {
        byProvider.putIfAbsent('instagram', () => []).add(a.name);
      }
      if (key == 'google') {
        byProvider.putIfAbsent('youtube', () => []).add(a.name);
      }
    }

    return AppData.platforms.map((p) {
      final names = byProvider[p.id] ?? const [];
      return PlatformModel(
        id: p.id,
        name: p.name,
        color: p.color,
        accounts: names.isEmpty ? const [] : names,
      );
    }).toList();
  }

  Set<String> connectedPlatformIds(List<SocialAccount> accounts) {
    final ids = <String>{};
    for (final a in accounts) {
      if (!a.isConnected) continue;
      final key = _normalizeProvider(a.provider);
      if (AppData.platforms.any((p) => p.id == key)) {
        ids.add(key);
      }
      if (key == 'facebook') {
        ids.add('instagram');
      }
      if (key == 'google') {
        ids.add('youtube');
      }
    }
    return ids;
  }

  /// Accounts that belong to a UI platform id (meta → facebook & instagram).
  List<SocialAccount> accountsForPlatform(
    String platformId,
    List<SocialAccount> accounts,
  ) {
    return accounts.where((a) {
      if (!a.isConnected) return false;
      final key = _normalizeProvider(a.provider);
      if (key == platformId) return true;
      if (platformId == 'instagram' && key == 'facebook') return true;
      if (platformId == 'youtube' && key == 'google') return true;
      return false;
    }).toList();
  }

  String _normalizeProvider(String raw) {
    final p = raw.toLowerCase();
    return switch (p) {
      'meta' => 'facebook',
      'twitter' || 'x (twitter)' => 'x',
      'thread' || 'threads' => 'threads',
      'linkedin-organization' ||
      'linkedin_org' ||
      'linkedin_page' ||
      'linkedinorganization' ||
      'linkedin_organization' =>
        'linkedin_organization',
      'google business' || 'google_business' => 'google',
      'youtube' => 'youtube',
      _ => PlatformOAuth.uiIdFor(p),
    };
  }
}
