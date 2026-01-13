# 记账本 Android 应用

一款基于 Flutter 开发的个人记账 Android 应用。

## 功能特性

### 用户系统
- 用户注册和登录
- 密码 SHA-256 加密存储
- 安全的用户认证

### 记账功能
- 收入记录（工资、奖金、兼职）
- 支出记录（餐饮、交通、购物、教育、医疗）
- 图标化分类选择
- 日期选择
- 备注功能
- 记录删除功能

### 统计功能
- 时间范围筛选（今日、本周、本月、本年、自定义）
- 总收入、总支出、结余显示
- 收入/支出分类统计柱状图
- 分类明细列表（金额、笔数）

## 技术栈

- **框架**: Flutter 3.0+
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **图表**: fl_chart
- **UI**: Material Design 3
- **加密**: crypto

## 项目结构

```
android_app/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── screens/
│   │   ├── auth_screen.dart      # 登录/注册页面
│   │   ├── home_screen.dart      # 主页面（记录列表）
│   │   ├── add_transaction_screen.dart  # 添加记录页面
│   │   └── statistics_screen.dart      # 统计页面
│   └── services/
│       └── database_service.dart # 数据库服务
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 项目说明
```

## 运行项目

### 前置要求

1. 安装 Flutter SDK
2. 配置 Android 开发环境
3. 安装 Android Studio 或 VS Code（带 Flutter 插件）

### 安装依赖

```bash
cd android_app
flutter pub get
```

### 运行应用

#### 使用 Android 模拟器
```bash
flutter run
```

#### 使用真机
1. 启用开发者选项和 USB 调试
2. 连接手机到电脑
3. 运行 `flutter devices` 查看设备
4. 运行 `flutter run -d <设备ID>`

### 构建 APK

```bash
flutter build apk --release
```

APK 文件位于 `build/app/outputs/flutter-apk/app-release.apk`

## 数据库

应用使用 SQLite 本地数据库，包含两个表：

### users 表
- id: 主键，自增
- username: 用户名，唯一
- password: SHA-256 加密的密码
- created_at: 创建时间

### transactions 表
- id: 主键，自增
- user_id: 用户 ID，外键
- type: 类型（income/expense）
- category: 分类
- amount: 金额
- date: 日期（时间戳）
- note: 备注
- created_at: 创建时间

## 开发说明

### 添加新功能

1. 在 `lib/screens/` 中创建新的页面
2. 在 `lib/services/` 中添加业务逻辑
3. 在 `main.dart` 中注册路由

### 修改样式

应用使用 Material Design 3，主题配置在 `main.dart` 中：
```dart
theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF667EEA),
  ),
),
```

### 数据库操作

所有数据库操作通过 `DatabaseService` 进行：
```dart
// 添加记录
await DatabaseService.instance.addTransaction({...});

// 获取记录
final transactions = await DatabaseService.instance.getTransactions(userId);

// 删除记录
await DatabaseService.instance.deleteTransaction(id);
```

## 依赖包

- `sqflite`: SQLite 数据库
- `path`: 文件路径处理
- `path_provider`: 获取应用路径
- `crypto`: 密码加密
- `intl`: 日期格式化
- `fl_chart`: 图表绘制
- `cupertino_icons`: iOS 图标

## 注意事项

1. 应用数据存储在本地，卸载应用会丢失数据
2. 密码使用 SHA-256 加密，但建议在生产环境中使用更安全的加密方式
3. 应用支持 Android 5.0+ (API 21+)

## 许可证

MIT License