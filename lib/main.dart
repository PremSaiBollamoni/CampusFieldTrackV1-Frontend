import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/app_export.dart';
import '../presentation/auth_screen/login_screen.dart';
import '../services/api_service.dart';
import '../services/tracking_service.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TrackingService().initialize();

  bool hasShownError = false;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _storage = const FlutterSecureStorage();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  String _userRole = 'USER';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'auth_token');
    final role = await _storage.read(key: 'user_role');
    setState(() {
      _isAuthenticated = token != null;
      _userRole = role ?? 'USER';
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.background,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'campusfieldtrack',
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          onGenerateRoute: (settings) {
            if (!_isAuthenticated &&
                settings.name != AppRoutes.login &&
                settings.name != AppRoutes.initial) {
              return MaterialPageRoute(builder: (_) => LoginScreen());
            }
            return AppRoutes.onGenerateRoute(settings);
          },
          initialRoute: _isAuthenticated 
              ? (_userRole == 'ADMIN' ? AppRoutes.adminDashboard : AppRoutes.homeDashboard)
              : AppRoutes.login,
        );
      },
    );
  }
}
