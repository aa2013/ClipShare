# ClipShare 发版流程

每次发布新版本（如 1.5.2 → 1.5.3），按以下步骤同步更新日志与官方文档。

> 前置：需提供官方文档项目 ClipShareDoc 在本机的路径，下文以 `<ClipShareDoc路径>` 占位，请按实际环境替换。
> ClipShareDoc 为独立仓库：`https://github.com/aa2013/ClipShareDoc.git`

## 1. 修改版本号
- `pubspec.yaml` 中 `version: x.y.z+NN`（如 `1.5.3+30`）
  - build 号（`+30`）用于下载 URL 与文档 version code
- 确定发布日期

## 2. 汇总提交记录
```bash
git log <上个版本tag>..HEAD --oneline
```
- 只保留用户可感知的变更，剔除纯技术细节
- 措辞参考此前版本更新日志，保持一致风格

## 3. 更新 Flutter 项目内更新日志
路径：`assets/md/updateLogs-*.md`（Windows / MacOS / Linux / IOS / Android 共 5 个文件），按实际受影响平台写入对应文件

- 顶部插入：`# 🏷️vX.Y.Z`
- 条目格式：`+ ` 前缀 + emoji 图标，**行尾保留两个空格**（markdown 换行）
- **条目顺序固定：✨新增 → 🛠️修复 → ⚡优化**

## 4. 同步官方文档项目（在 `<ClipShareDoc路径>` 下）

### 4.1 下载表格
`docs/docs/zh-CN/history_version.md`、`docs/docs/en-US/history_version.md`
- 表格 10 行链接全部替换版本号 + build 号（例 `1.5.2+29` → `1.5.3+30`）
- URL 模式：
  - 桌面端：`.../releases/clipshare/{ver}/clipshare-{ver}+{build}-{platform}.{ext}`
  - Android：`.../{ver}/app-arm64-v8a-release-v{ver}.apk`（arm64-v8a / armeabi-v7a / x86_64）
  - iOS：`.../{ver}/clipshare-{ver}-{build}-nosign.ipa`

### 4.2 更新日志区块（同上两个 history_version.md）
- 最新版本区块前插入 `### 🏷️ vX.Y.Z - <发布日期>`
- 保留不兼容提示 `> 注意，此版本不兼容旧版本(<1.5.0)设备连接`
- **分类统一为：通用 / 桌面端 / Android / Windows / Linux / MacOS / iOS（无内容写 `--`）**
- 内容与第 3 步一致：去掉 `+` 前缀、行尾两空格、顺序固定 新增→修复→优化

### 4.3 首页版本号
`docs/docs/zh-CN/index.md`、`docs/docs/en-US/index.md`
- `立即下载 V1.5.2` → `立即下载 V1.5.3`（英文 `Download V1.5.2 Now`）

### 4.4 版本信息 JSON
`docs/public/version-info.json`、`docs/public/version-info.en.json`
- `downloads`：5 平台 URL + version 更新
- `logs`：数组**顶部**插入 5 条，顺序 MacOS → Linux → Windows → Android → IOS
  - `version.name`（1.5.3）、`version.code`（build 号 30）
  - `desc`：合并该平台内容，`\n` 分隔，顺序 新增→修复→优化
- `DownloadPage.vue` 自动读 JSON，无需修改

## 5. 校验
- JSON 有效性：
  `node -e "JSON.parse(require('fs').readFileSync('<json>','utf8'))"`
- grep 检查下载表格 / downloads 无上一版本号残留

## 6. 提交
- ClipShareDoc 改动提交到其独立仓库
- clipshare 改动（pubspec、assets/md、docs/RELEASE_PROCESS.md）提交到 clipshare 仓库
