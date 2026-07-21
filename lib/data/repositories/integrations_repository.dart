import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_json_utils.dart';
import '../models/api_models.dart';

class MetaPagesResult {
  const MetaPagesResult({
    required this.pages,
    required this.instagramAccounts,
  });

  final List<NamedResource> pages;
  final List<NamedResource> instagramAccounts;
}

class IntegrationsRepository {
  IntegrationsRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<MetaPagesResult> fetchMetaPages() async {
    final res = await _client.get(ApiConstants.facebookPages);
    final list = ApiJsonUtils.extractList(res.data);
    final pages = <NamedResource>[];
    final instagrams = <NamedResource>[];

    for (final map in list) {
      final page = NamedResource.fromJson(map);
      if (page.id.isNotEmpty) pages.add(page);

      final ig = map['instagram'];
      if (ig is Map) {
        final igMap = Map<String, dynamic>.from(ig);
        final id = ApiJsonUtils.readString(igMap, ['id']) ?? '';
        if (id.isEmpty) continue;
        instagrams.add(
          NamedResource(
            id: id,
            name: ApiJsonUtils.readString(igMap, ['name', 'username']) ?? 'Instagram',
            imageUrl: ApiJsonUtils.readString(igMap, [
              'profileImage',
              'profile_picture_url',
              'picture',
            ]),
            subtitle: ApiJsonUtils.readString(igMap, ['username']) != null
                ? '@${ApiJsonUtils.readString(igMap, ['username'])}'
                : page.name,
          ),
        );
      }
    }

    return MetaPagesResult(pages: pages, instagramAccounts: instagrams);
  }

  Future<List<NamedResource>> fetchFacebookPages() async {
    final result = await fetchMetaPages();
    return result.pages;
  }

  Future<List<NamedResource>> fetchPinterestBoards() async {
    final res = await _client.get(ApiConstants.pinterestBoards);
    return ApiJsonUtils.extractList(res.data)
        .map(NamedResource.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  Future<List<NamedResource>> fetchYoutubeChannels() async {
    final res = await _client.get(ApiConstants.youtubeChannels);
    return ApiJsonUtils.extractList(res.data)
        .map(NamedResource.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  Future<List<NamedResource>> fetchGoogleBusinessProfiles() async {
    final res = await _client.get(ApiConstants.googleBusinessProfiles);
    return ApiJsonUtils.extractList(res.data)
        .map(NamedResource.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
}
