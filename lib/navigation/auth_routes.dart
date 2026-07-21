/// Route guards for logged-in vs guest users.
abstract final class AuthRoutes {
  static const guestOnly = {
    '/welcome',
    '/login',
    '/register',
    '/forgot-password',
    '/otp-verify',
    '/reset-password',
    '/auth-success',
  };

  static const requiresAuth = {
    '/home',
    '/create',
    '/notifications',
    '/profile',
    '/settings',
    '/subscription',
    '/platforms',
  };

  static bool isProtected(String location) {
    if (requiresAuth.contains(location)) return true;
    if (location.startsWith('/platforms')) return true;
    if (location.startsWith('/posts/')) return true;
    return false;
  }

  static bool isGuestAuthScreen(String location) {
    if (guestOnly.contains(location)) return true;
    if (location.startsWith('/otp-verify')) return true;
    return false;
  }
}
