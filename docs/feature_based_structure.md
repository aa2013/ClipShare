# ClipShare Feature-Based 目录结构

```text
lib/
  main.dart
  src/
    core/
      app/
        providers/
          core_providers.dart
      constants/
        app_constants.dart
        route_constants.dart
      desktop/
        tray_manager.dart
      extensions/
        datetime_extension.dart
        string_extension.dart
      l10n/
        app_zh.arb
        app_en.arb
        l10n.dart
      platform/
        android_channel.dart
        clip_channel.dart
        multi_window_channel.dart
      routing/
        app_router.dart
        app_routes.dart
      theme/
        app_theme.dart
        code_editor_theme.dart
      transport/
        socket_manager.dart
        storage_manager.dart
        secure_socket_client.dart
        forward_socket_client.dart
      utils/
        file_util.dart
        log_util.dart
        notify_util.dart

    shared/
      actions/
        export_file_action.dart
        open_file_action.dart
      dialogs/
        common_dialog.dart
        text_edit_dialog.dart
      layouts/
        rounded_scaffold.dart
        custom_title_bar_layout.dart
      widgets/
        loading.dart
        empty_content.dart
        dot.dart

    repositories/
      history_repository.dart
      device_repository.dart
      settings_repository.dart

    features/
      splash/
        ui/

      home/
        ui/
          pages/
          widgets/
          providers/

      history/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      device/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      sync_file/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      rules/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      settings/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      authentication/
        ui/
          pages/
          widgets/
          providers/
        actions/

      statistics/
        ui/
          pages/
          widgets/
          providers/
        models/

      user_guide/
        ui/
          pages/
          widgets/
          providers/
        actions/

      update_log/
        ui/
          pages/
          widgets/

      debug/
        ui/
          pages/
          widgets/
          providers/
        actions/

      licenses/
        ui/
          pages/

      qr_code_scanner/
        ui/
          pages/
          widgets/
          providers/
        actions/

      clean_data/
        ui/
          pages/
          widgets/
          providers/
        models/
        actions/

      db_editor/
        ui/
          pages/
          widgets/
          providers/
        actions/
```

# 功能归类

## splash
- 启动页
- 初始化中转页
- 启动阶段状态判断

## home
- 应用主壳页面
- 导航容器
- 底部导航
- 侧边导航
- 首页级布局组件

## history
- 历史记录列表
- 历史详情
- 搜索
- 筛选
- 编辑历史内容
- 历史记录相关局部组件
- 历史记录相关操作流程

## device
- 设备列表
- 设备详情
- 设备配对
- 在线设备
- 设备卡片
- 设备状态展示
- 设备相关操作流程

## sync_file
- 文件同步页面
- 文件发送页面
- 待发送文件列表
- 文件同步状态展示
- 文件同步相关操作流程

## rules
- 规则列表
- 规则详情
- 脚本模块
- 脚本编辑
- 脚本测试
- 规则预览
- 规则卡片
- 规则相关操作流程

## settings
- 设置首页
- 各设置分组页
- 主题设置
- 语言设置
- 权限设置
- 通知设置
- 快捷键设置
- 同步设置
- 备份设置
- 关于页
- 设置相关操作流程

## authentication
- 密码输入
- 本地认证
- 身份校验页面
- 认证相关操作流程

## statistics
- 图表页
- 统计卡片
- 柱状图
- 饼图
- 各类统计维度展示

## user_guide
- 新手引导
- 权限引导
- 使用说明流程页
- 引导相关操作流程

## update_log
- 更新日志展示
- 版本说明页面

## debug
- 调试页面
- 诊断工具页
- 调试信息展示
- 调试相关操作流程

## licenses
- 开源许可证页面

## qr_code_scanner
- 二维码扫描
- 扫描结果处理
- 扫码相关局部组件
- 扫码相关操作流程

## clean_data
- 清理数据页面
- 清理策略配置
- 清理行为相关组件
- 清理相关操作流程

## db_editor
- 数据库浏览页
- 数据编辑页
- 数据查看工具页
- 数据编辑相关操作流程

# 放置规则

## core
只放无业务语义内容：

- 应用级 provider 注册入口
- 常量
- 桌面能力
- 扩展
- 国际化
- 平台能力
- 路由
- 主题
- 通信基础能力
- 通用工具函数

## shared
只放跨多个功能稳定复用的内容：

- 通用 actions
- 通用弹窗
- 通用布局
- 通用基础组件

## repositories
只放仓储定义与实现：

- 跨功能共享的数据访问入口
- 本地存储仓储
- 网络访问仓储
- 聚合后的统一仓储

## core/app/providers
只放应用级单例能力的 provider 注册：

- manager provider
- client provider
- 全局基础能力装配入口

## core/transport
只放跨功能复用的通信能力：

- socket manager
- storage manager
- secure socket client
- forward socket client

## core/desktop
只放桌面端全局能力：

- tray manager

## core/platform
只放平台相关基础接入能力：

- channel 封装
- 平台回调接入
- 系统能力适配

## features
每个功能自己的内容优先放自己目录下：

- ui
- models
- actions

## ui
只放界面层内容：

- 页面
- 视图专属组件
- Riverpod provider
- notifier
- state

## models
只放该功能自己的业务数据结构：

- 展示模型
- 业务模型
- 表单模型
- 筛选条件模型

## actions
只放该功能自己的操作流程：

- 提交
- 同步
- 配对
- 导入
- 导出
- 删除
- 扫描

## events
只放事件接入与事件转发：

- listener
- 平台事件入口
- 生命周期事件入口
- 外部消息分发入口

# 判断规则

- 先判断文件属于哪个功能，能归到某个功能就放 `features/<feature>/`
- 跟某个功能强绑定的流程逻辑放 `features/<feature>/actions/`
- 跟某个功能强绑定的事件接入放 `features/<feature>/events/`
- 只有被多个功能稳定复用，才放 `shared/`
- 仓储统一放 `repositories/`
- 应用级单例能力统一放 `core/`，并通过 `core/app/providers/` 注册
- 长生命周期、负责调度的全局能力命名使用 `manager`
- 底层通信、协议、连接封装命名使用 `client`
- 完全没有业务语义，才放 `core/`
- 不再新增全局 `modules/`、`views/`、`widgets/`、`services/`、`handlers/`、`listeners/`、`data/`

# 命名建议

- 目录统一使用小写下划线
- 文件名统一使用语义化命名
- provider 相关文件统一靠近各自 feature 放置
- action 文件统一使用动作语义命名
- 应用级单例文件统一使用 `manager` 命名
- 底层通信封装统一使用 `client` 命名

示例：

```text
history_page.dart
history_filter_bar.dart
history_provider.dart
history_state.dart
history_notifier.dart
sync_file_send_action.dart
device_pair_action.dart
rule_import_action.dart
settings_about_page.dart
socket_manager.dart
storage_manager.dart
tray_manager.dart
secure_socket_client.dart
forward_socket_client.dart
```
