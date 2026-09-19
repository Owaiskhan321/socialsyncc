import '../../core/logger/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/session_storage.dart';
import '../models/api_models.dart';
import '../models/models.dart';

class UserRepository {
  UserRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<UserProfile> fetchMe() async {
    AppLogger.event('api_auth_me');
    final res = await _client.get(ApiConstants.me);
    final profile = UserProfile.fromJson(res.data);
    if (profile.wallet != null) {
      await SessionStorage.saveWallet(
        credits: profile.wallet!.credits,
        freeCredits: profile.wallet!.freeCredits,
      );
    }
    return profile;
  }

  Future<WalletInfo> fetchWallet() async {
    AppLogger.event('api_wallet');
    final res = await _client.get(ApiConstants.wallet);
    final wallet = WalletInfo.fromJson(res.data);
    await SessionStorage.saveWallet(
      credits: wallet.credits,
      freeCredits: wallet.freeCredits,
    );
    return wallet;
  }
}

class ContactRepository {
  ContactRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<String> submit({
    required String name,
    required String email,
    required String inquiry,
    required String message,
  }) async {
    AppLogger.event('api_contact');
    final res = await _client.post(
      ApiConstants.contact,
      body: {
        'name': name,
        'email': email,
        'inquiry': inquiry,
        'message': message,
      },
    );
    return res.message.isNotEmpty ? res.message : 'Message sent';
  }
}

class PusherRepository {
  PusherRepository({ApiClient? client}) : _client = client ?? appApiClient;

  final ApiClient _client;

  Future<Map<String, dynamic>> authenticate({
    required String socketId,
    required String channelName,
  }) async {
    AppLogger.event('api_pusher_auth', {'channel': channelName});
    final res = await _client.post(
      ApiConstants.pusherAuth,
      body: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
    );
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {'auth': res.data?.toString() ?? ''};
  }
}
