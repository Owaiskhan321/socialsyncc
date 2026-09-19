import '../../data/repositories/user_repository.dart';
import 'session_storage.dart';

/// Refreshes cached user fields from `GET auth/me`.
Future<void> syncUserProfileFromApi() async {
  final token = await SessionStorage.getToken();
  if (token == null || token.isEmpty) return;

  final profile = await UserRepository().fetchMe();
  await SessionStorage.saveSession(
    token: token,
    email: profile.email.isNotEmpty ? profile.email : await SessionStorage.getEmail(),
    name: profile.name,
    userId: profile.id.isNotEmpty ? profile.id : await SessionStorage.getUserId(),
    credits: profile.wallet?.credits,
    freeCredits: profile.wallet?.freeCredits,
  );
}
