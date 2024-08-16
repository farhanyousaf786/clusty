


import 'package:clusty_stf/services/storage/pref_storage.dart';
import 'package:clusty_stf/services/storage/storage.dart';
import 'package:clusty_stf/services/user_repo/user_apis.dart';
import 'package:clusty_stf/services/user_repo/user_repository.dart';
import 'package:get_it/get_it.dart';


final _locator = GetIt.instance;
IStorage get storage => _locator<IStorage>();
IUserRepository get userRepository => _locator<IUserRepository>();


abstract class DependencyInjectionEnvironment {
  static Future<void> setup() async {
    _locator.registerLazySingleton<IStorage>(() => PrefsStorage());
    _locator.registerLazySingleton<IUserRepository>(() => UserApi());
  }
}
