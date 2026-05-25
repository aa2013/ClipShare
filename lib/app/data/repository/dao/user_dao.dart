import 'package:floor/floor.dart';

import '../entity/tables/user.dart';

@dao
@Deprecated('no longer use')
abstract class UserDao {
  ///根据用户 id 获取用户信息
  @Query("select * from user where id = :id")
  Future<User?> getById(int id);

  ///添加用户
  @insert
  Future<int> add(User user);

  ///更新用户信息 todo
  @update
  Future<int> updateUser(User user);
}
