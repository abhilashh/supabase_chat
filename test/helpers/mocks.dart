import 'package:mocktail/mocktail.dart';
import 'package:subasechatapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:subasechatapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:subasechatapp/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:subasechatapp/features/chat/domain/repositories/chat_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}
