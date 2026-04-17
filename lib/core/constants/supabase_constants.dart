/// Supabase credentials are injected at build time via --dart-define-from-file.
/// Never hard-code real values here.
///
/// To run:
///   flutter run --dart-define-from-file=config.json
/// To build:
///   flutter build apk --dart-define-from-file=config.json
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // Table names
  static const String messagesTable = 'messages';
  static const String profilesTable = 'profiles';
  static const String roomsTable = 'rooms';
  static const String roomMembersTable = 'room_members';
  static const String directMessagesTable = 'direct_messages';

  // Realtime channel
  static const String chatChannel = 'public:messages';

  // Message limits
  static const int maxMessageLength = 2000;
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
}
