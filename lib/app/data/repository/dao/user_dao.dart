import 'package:clipshare/app/data/repository/db/app_database.dart';
import 'package:clipshare/app/data/repository/db/app_tables.dart';
import 'package:clipshare/app/data/repository/entity/tables/user.dart';
import 'package:drift/drift.dart';

part 'user_dao.g.dart';

@Deprecated('no longer use')
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.attachedDatabase);

  /// 根据用户 id 获取已废弃用户信息。
  Future<User?> getById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 添加已废弃用户信息，保留旧备份兼容能力。
  Future<int> add(User user) {
    return into(users).insert(_companion(user));
  }

  /// 更新已废弃用户信息。
  Future<int> updateUser(User user) {
    return (update(users)..where((tbl) => tbl.id.equalsNullable(user.id))).write(_companion(user));
  }

  /// 将用户领域对象转换为 Drift 写入对象。
  UsersCompanion _companion(User user) {
    return UsersCompanion.insert(
      id: Value(user.id),
      account: user.account,
      password: user.password,
      type: user.type,
    );
  }
}
