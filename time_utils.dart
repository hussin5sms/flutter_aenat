import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// رابط API لجلب الوقت من السيرفر
const String serverTimeUrl = 'https://hussein.org.ly/new_api/3/get_server_time.php';

/// دالة لفحص ما إذا كان الوقت مناسبًا (من الأحد إلى الخميس، 8 ص إلى 4 م)
Future<bool> checkWorkingTime(BuildContext context) async {
  try {
    final response = await http.get(Uri.parse(serverTimeUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      int day = int.parse(data['day'].toString());   // 0=الأحد، 6=السبت
      int hour = int.parse(data['hour'].toString());

      // التحقق من أيام الجمعة والسبت (5 و6)
      if (day == 5 || day == 6) {
        _showAlert(context, '❌ التطبيق غير متاح يومي الجمعة والسبت');
        return false;
      }

      // التحقق من الساعات (8 صباحًا إلى 4 مساءً)
      if (hour < 8 || hour >= 23) {
        _showAlert(context, '❌ التطبيق يعمل من الساعة 8 صباحًا إلى 4 مساءً فقط');
        return false;
      }

      return true;
    } else {
      _showAlert(context, '⚠️ تعذر التحقق من الوقت. الرجاء المحاولة لاحقًا');
      return false;
    }
  } catch (e) {
    _showAlert(context, '⚠️ خطأ في الاتصال بالسيرفر: $e');
    return false;
  }
}

void _showAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('تنبيه', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text('حسناً'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}