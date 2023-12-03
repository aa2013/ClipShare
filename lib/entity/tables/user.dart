import 'package:floor/floor.dart';

@entity
class User {
  @PrimaryKey()
  ///用户id（uuid）
  String? id;

  ///账号
  late String account;

  ///密码
  late String password;

  ///设备类型
  late String type;

  User({
    this.id,
    required this.account,
    required this.password,
    required this.type,
  });
}
