# 使用 GitHub Actions 构建 APK

## 方法一：使用 GitHub Actions（推荐）

### 1. 初始化 Git 仓库

```bash
cd android_app
git init
git add .
git commit -m "Initial commit"
```

### 2. 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建新仓库（例如：`accounting-app`）
3. 不要初始化 README、.gitignore 或 license

### 3. 推送代码到 GitHub

```bash
git remote add origin https://github.com/你的用户名/accounting-app.git
git branch -M main
git push -u origin main
```

### 4. 触发构建

推送代码后，GitHub Actions 会自动开始构建：

1. 访问你的仓库页面
2. 点击 "Actions" 标签
3. 查看构建进度

### 5. 下载 APK

构建完成后（约 5-10 分钟）：

**从 Actions 下载：**
1. 进入 "Actions" 标签
2. 点击最近的构建任务
3. 滚动到底部，找到 "Artifacts" 部分
4. 下载 `app-release` 文件

**从 Releases 下载：**
1. 进入仓库的 "Releases" 标签
2. 下载最新的 Release 中的 APK 文件

## 方法二：手动触发构建

### 1. 启用 GitHub Actions

1. 进入仓库页面
2. 点击 "Settings" 标签
3. 左侧菜单选择 "Actions" > "General"
4. 在 "Actions permissions" 中选择 "Allow all actions and reusable workflows"
5. 点击 "Save"

### 2. 手动触发构建

1. 进入 "Actions" 标签
2. 左侧选择 "Build Android APK" 工作流
3. 点击 "Run workflow"
4. 选择分支（通常是 `main`）
5. 点击 "Run workflow" 按钮

## 方法三：本地构建（需要安装 Flutter）

### 安装 Flutter

1. 下载 Flutter SDK
   - 访问 https://flutter.dev/docs/get-started/install/windows
   - 下载最新的 stable 版本（推荐 3.16.0 或更高）

2. 解压到 `C:\flutter`

3. 配置环境变量
   - 右键 "此电脑" > "属性" > "高级系统设置" > "环境变量"
   - 在 "系统变量" 中找到 "Path"，点击 "编辑"
   - 添加 `C:\flutter\bin`
   - 点击 "确定" 保存

4. 验证安装
   ```bash
   flutter doctor
   ```

5. 安装 Android Studio
   - 下载并安装 Android Studio
   - 打开 Android Studio，安装 Android SDK
   - 接受所有许可证：
     ```bash
     flutter doctor --android-licenses
     ```

### 构建 APK

```bash
cd android_app
flutter pub get
flutter build apk --release
```

APK 文件位置：
```
build\app\outputs\flutter-apk\app-release.apk
```

## 常见问题

### Q: 构建失败怎么办？
A: 检查 Actions 日志，查看具体错误信息。常见问题：
- 依赖版本冲突
- 代码语法错误
- Flutter 版本不兼容

### Q: 如何修改应用名称？
A: 编辑 `android/app/src/main/AndroidManifest.xml`，修改 `android:label` 属性。

### Q: 如何修改应用图标？
A: 替换 `android/app/src/main/res/mipmap-*` 目录下的图标文件。

### Q: 如何修改应用版本号？
A: 编辑 `android/app/build.gradle`，修改 `versionCode` 和 `versionName`。

### Q: APK 签名是什么？
A: Release APK 需要签名才能发布到应用商店。当前配置使用调试签名，可以安装但无法发布到 Google Play。

## 发布到 Google Play

如需发布到 Google Play，需要：

1. 创建签名密钥
2. 配置签名
3. 生成 AAB 文件（不是 APK）
4. 上传到 Google Play Console

详细步骤请参考 Flutter 官方文档。