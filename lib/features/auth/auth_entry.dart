enum AuthIntent { signIn, unlockAi, syncWardrobe }

/// Navigation-only context for the authentication screen.
class AuthEntry {
  const AuthEntry({required this.intent, this.returnLocation});

  const AuthEntry.signIn() : this(intent: AuthIntent.signIn);

  final AuthIntent intent;
  final String? returnLocation;

  static const allowedReturnLocations = <String>{
    '/home',
    '/wardrobe',
    '/missing',
    '/chat',
    '/profile',
    '/settings',
  };

  String? get safeReturnLocation {
    final location = returnLocation;
    return location != null && allowedReturnLocations.contains(location)
        ? location
        : null;
  }
}
