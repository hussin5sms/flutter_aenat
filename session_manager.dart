import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fproject/show/LoginPage3.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Timer? _sessionTimer;
  final Duration _sessionTimeout = const Duration(minutes: 5); // 5 دقائق

  // دالة لبدء الجلسة
  void startSession(BuildContext context) {
    _cancelTimer();
    _sessionTimer = Timer(_sessionTimeout, () => _logout(context));
  }

  // دالة لإعادة ضبط الجلسة عند أي نشاط
  void resetSession(BuildContext context) {
    if (_sessionTimer != null) {
      _cancelTimer();
      startSession(context);
    }
  }

  // دالة لإلغاء المؤقت
  void _cancelTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // دالة لتسجيل الخروج التلقائي
  void _logout(BuildContext context) {
    _cancelTimer();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage3(deviceId: '')), // استبدل بمسار شاشة الدخول الفعلي
          (Route<dynamic> route) => false,
    );
  }

  // دالة للتحقق من وجود جلسة نشطة
  bool isSessionActive() {
    return _sessionTimer != null && _sessionTimer!.isActive;
  }
}