import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

abstract interface class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers();
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final SupabaseClient _supabase;
  const UsersRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.profilesTable)
          .select()
          .order('username');

      return (data as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ServerException('Failed to load users');
    }
  }
}
