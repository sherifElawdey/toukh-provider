abstract final class AppRoutes {
  AppRoutes._();

  static const welcome = '/welcome';
  static const splash = '/splash';
  static const appUpdate = '/app-update';
  static const login = '/login';

  static const registerKind = '/register/kind';
  static const registerCategory = '/register/category';
  static const registerCredentials = '/register/credentials';
  static const registerProfile = '/register/profile';
  static const registerMap = '/register/map';
  static const registerHours = '/register/hours';
  static const registerDelivery = '/register/delivery';
  static const registerReview = '/register/review';

  static const requestSubmitted = '/request-submitted';
  static const forgotPassword = '/forgot-password';
  static const verifyOtp = '/verify-otp';
  static const resetPassword = '/reset-password';

  static const accountBlocked = '/account/blocked';
  static const accountUnverified = '/account/unverified';
  static const accountVerifyPhone = '/account/verify-phone';
  static const profilePending = '/account/profile-pending';

  static const postLoginStatus = '/post-login-status';

  static const permissions = '/permissions';

  static const registrationMenu = '/registration/menu';
  static const registrationPortfolio = '/registration/portfolio';
  static const pendingApproval = '/pending-approval';

  static const home = '/home';
  static const orders = '/orders';
  static const menu = '/menu';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static const legalTerms = '/legal/terms';
  static const legalPrivacy = '/legal/privacy';
  static const legalDeclaration = '/legal/declaration';

  /// Registration wizard (before Firebase user exists).
  static const Set<String> registerWizardPaths = {
    registerKind,
    registerCategory,
    registerCredentials,
    registerProfile,
    registerMap,
    registerHours,
    registerDelivery,
    registerReview,
  };

  static bool isShellPathOrSubroute(String matchedLocation) {
    if (matchedLocation.startsWith('/legal/')) return true;
    if (matchedLocation == notifications ||
        matchedLocation.startsWith('$notifications/')) {
      return true;
    }
    for (final p in shellPaths) {
      if (matchedLocation == p || matchedLocation.startsWith('$p/')) {
        return true;
      }
    }
    return false;
  }

  static const Set<String> authFlowPaths = {
    login,
    requestSubmitted,
    forgotPassword,
    verifyOtp,
    resetPassword,
    postLoginStatus,
    accountVerifyPhone,
  };

  static const Set<String> shellPaths = {home, orders, menu, settings};
}
