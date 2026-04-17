import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/constants/supabase_constants.dart';
import 'core/network/app_http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    httpClient: AppHttpClient(),
  );

  // Create a single ProviderContainer so the router and the app
  // share the exact same provider instances.
  final container = ProviderContainer();

  runApp(App(container: container));
}
