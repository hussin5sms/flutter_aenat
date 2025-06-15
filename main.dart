import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fproject/show/ChoicePage03.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// استبدل هذه الصفحات بما يناسبك
import 'package:fproject/show/LoginPage3.dart';


void main() {
  runApp(MyApp());
}

// ===== APP ENTRY =====
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تسجيل عينات',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorObservers: [SessionNavigatorObserver()],
      home: FutureBuilder<String>(
        future: _getDeviceId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AppLifecycleWrapper(deviceId: snapshot.data!);
          } else {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}

// ===== GET DEVICE ID =====
Future<String> _getDeviceId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  try {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id ?? androidInfo.fingerprint ?? 'unknown-device';
  } catch (e) {
    return 'error-device';
  }
}

// ===== SESSION MANAGER =====
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _sessionTimer;
  final Duration _sessionTimeout = const Duration(minutes: 5);
  late String deviceId;

  void setDeviceId(String id) {
    deviceId = id;
  }

  void startSession(BuildContext context) {
    _cancelTimer();
    _sessionTimer = Timer(_sessionTimeout, () => _logout(context));
  }

  void resetSession(BuildContext context) {
    _cancelTimer();
    startSession(context);
  }

  void _cancelTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _logout(BuildContext context) async {
    _cancelTimer();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage3(deviceId: deviceId)),
          (Route<dynamic> route) => false,
    );
  }
}

// ===== NAVIGATION OBSERVER =====
class SessionNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _resetSession(route.navigator?.context);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _resetSession(previousRoute?.navigator?.context);
  }

  void _resetSession(BuildContext? context) {
    if (context != null) {
      SessionManager().resetSession(context);
    }
  }
}

// ===== APP WRAPPER =====
class AppLifecycleWrapper extends StatefulWidget {
  final String deviceId;

  const AppLifecycleWrapper({Key? key, required this.deviceId}) : super(key: key);

  @override
  _AppLifecycleWrapperState createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionManager.setDeviceId(widget.deviceId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionManager.resetSession(context);
    }
  }

  void _handleUserInteraction() {
    _sessionManager.resetSession(context);
  }

  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleUserInteraction,
      onPanDown: (_) => _handleUserInteraction(),
      behavior: HitTestBehavior.opaque,
      child: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              _sessionManager.startSession(context);
              return ChoicePage03(); // استبدلها بصفحتك الرئيسية
            } else {
              return LoginPage3(deviceId: widget.deviceId);
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
