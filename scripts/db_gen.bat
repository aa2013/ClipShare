:: 生成数据库SQL代码
@echo off
setlocal enabledelayedexpansion

call flutter pub run build_runner build --delete-conflicting-outputs
set input_file="..\.dart_tool\build\generated\clipshare\lib\app\services\db_service.floor.g.part"
set output_file="..\lib\app\data\repository\db\app_db.floor.g.dart"
set added_line=part of 'package:clipshare/app/services/db_service.dart';
echo %added_line% > %output_file%
type %input_file% >> %output_file%
echo move file finished.

endlocal
