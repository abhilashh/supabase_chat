# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands must be run from the project root.

```bash
# Install dependencies
flutter pub get

# Run in debug mode (credentials required)
flutter run --dart-define-from-file=config.json

# Run on a specific device
flutter run --dart-define-from-file=config.json -d <device-id>
flutter devices   # list available devices

# Run all tests
flutter test

# Run a single test file
flutter test test/core/validators/input_validator_test.dart

# Run tests matching a name pattern
flutter test --name "SignInUseCase"

# Lint / static analysis
flutter analyze

# Build release APK
flutter build apk --dart-define-from-file=config.json
```

## Credentials

Supabase credentials are **never hardcoded**. They are injected via `--dart-define-from-file`. Copy `config.json.example` → `config.json` and fill in the real values from the Supabase dashboard (Settings → API). `config.json` is gitignored.

## Architecture

Clean Architecture with three horizontal layers per feature, plus a shared core.

```
lib/
├── core/
│   ├── constants/     # SupabaseConstants (dart-define values + limits)
│   ├── errors/        # Exceptions (AppAuthException, ServerException) and Failures
│   ├── providers/     # supabaseClientProvider — single SupabaseClient instance
│   ├── usecases/      # UseCase<T,P> interface + NoParams
│   └── validators/    # InputValidator — pure static methods returning Either<ValidationFailure, T>
├── features/
│   ├── auth/
│   │   ├── data/      # AuthRemoteDataSourceImpl, UserModel, AuthRepositoryImpl, auth_providers.dart
│   │   ├── domain/    # UserEntity, AuthRepository (abstract), SignIn/SignUp/SignOut use cases
│   │   └── presentation/  # AuthNotifier + sealed AuthState, LoginPage, RegisterPage
│   └── chat/
│       ├── data/      # ChatRemoteDataSourceImpl, MessageModel, ChatRepositoryImpl, chat_providers.dart
│       ├── domain/    # MessageEntity, ChatRepository (abstract), Send/Get/Subscribe use cases
│       └── presentation/  # ChatNotifier, messagesStreamProvider, ChatPage
├── app/
│   ├── app.dart       # App widget — UncontrolledProviderScope + MaterialApp.router
│   └── router.dart    # GoRouter with auth redirect guard (_AuthRouterNotifier bridge)
└── main.dart          # Supabase.initialize() → ProviderContainer → runApp(App)
```

## Dependency flow

`main.dart` creates a single `ProviderContainer` and passes it to both `App` and `createRouter`. This ensures the router's redirect guard and the widget tree share the exact same provider instances.

Provider dependency chain (bottom → top):
```
supabaseClientProvider
  → authRemoteDataSourceProvider → authRepositoryProvider
      → SignIn/SignUp/SignOut use cases → AuthNotifier
  → chatRemoteDataSourceProvider → chatRepositoryProvider
      → SendMessageUseCase → ChatNotifier
      → subscribeToMessages → messagesStreamProvider (StreamProvider)
```

## State management patterns

- **`AuthNotifier`** (`Notifier<AuthState>`) — sealed `AuthState` (Initial/Loading/Authenticated/Unauthenticated/Error). `build()` calls `_checkCurrentUser()` **asynchronously** — the state starts as `AuthInitial` and transitions after the session check. In tests, read the provider eagerly then `await Future.delayed(Duration.zero)` before acting.
- **`ChatNotifier`** (`Notifier<AsyncValue<void>>`) — handles send actions. Contains a client-side sliding-window rate limiter (5 messages / 10 s).
- **`messagesStreamProvider`** (`StreamProvider`) — wraps Supabase realtime stream; auto-cancels on dispose.
- **GoRouter redirect** — `_AuthRouterNotifier` bridges `authNotifierProvider` to a `ChangeNotifier` so GoRouter re-evaluates the redirect whenever auth state changes. `AuthInitial` does not redirect (session check in progress).

## Validation

`InputValidator` (in `core/validators/`) validates all user input and returns `Either<ValidationFailure, T>`. Use cases call it before touching the network — a failed validation short-circuits immediately and the repository is never called. Validation rules mirror the DB-level `CHECK` constraints in the SQL migration.

## Error handling

`AuthRemoteDataSourceImpl._sanitiseAuthError` maps `AuthApiException` to safe user-facing strings by inspecting `e.message` (for named codes like `over_email_send_rate_limit`) then falling back to `e.statusCode`. Raw Supabase error text is never forwarded to the UI.

## Database

SQL migration is in `supabase/migrations/001_initial_schema.sql`. Run it once in the Supabase SQL Editor. Key design decisions:
- RLS `WITH CHECK (sender_id = auth.uid())` prevents sender spoofing server-side.
- No UPDATE/DELETE policies on `messages` — immutability enforced at DB level.
- A trigger auto-creates a `profiles` row on signup, so the app does not need a separate upsert.

## Tests

```
test/
├── helpers/        # mocks.dart (mocktail mocks), fixtures.dart (shared test data)
├── core/validators/
└── features/
    ├── auth/  (domain/usecases, data/repositories, presentation/providers)
    └── chat/  (domain/usecases, data/repositories, presentation/providers)
```

Uses `mocktail` for mocking. Repository and notifier tests use `ProviderContainer` with `overrides` — no real Supabase connection needed.
