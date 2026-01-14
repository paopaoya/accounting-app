import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载主题设置
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
  
  // 初始化数据库
  await DatabaseService.instance.database;
  
  runApp(AccountingApp(isDarkMode: isDarkMode));
}

class AccountingApp extends StatefulWidget {
  final bool isDarkMode;

  const AccountingApp({super.key, required this.isDarkMode});

  @override
  State<AccountingApp> createState() => _AccountingAppState();
}

class _AccountingAppState extends State<AccountingApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthScreen(
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: args['userId'],
              username: args['username'],
              toggleTheme: _toggleTheme,
              isDarkMode: _isDarkMode,
            ),
          );
        }
        return null;
      },
    );
  }
}