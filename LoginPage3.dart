import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fproject/show/ChoicePage03.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage3 extends StatefulWidget {
  final String deviceId;

  const LoginPage3({super.key, required this.deviceId});

  @override
  State<LoginPage3> createState() => _LoginPage3State();
}

class _LoginPage3State extends State<LoginPage3> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final String _loginUrl = 'https://hussein.org.ly/new_api/3/login2.php';
  final String _serverTimeUrl = 'https://hussein.org.ly/new_api/3/get_server_time.php';
  final String _deviceLogUrl = 'https://hussein.org.ly/new_api/3/log_device.php';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> isWorkingTimeFromServer() async {
    try {
      final response = await http.get(Uri.parse(_serverTimeUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int day = int.parse(data['day'].toString());
        int hour = int.parse(data['hour'].toString());

        if (day == 5 || day == 6) return false;
        if (hour >= 8 && hour < 23) return true;
      }
      return false;
    } catch (e) {
      debugPrint("خطأ أثناء جلب الوقت من السيرفر: $e");
      return false;
    }
  }

  Future<void> _logDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      final response = await http.post(
        Uri.parse(_deviceLogUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'device_id': widget.deviceId,
          'login_time': DateTime.now().toIso8601String(),
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'os_version': androidInfo.version.release,
          'sdk_version': androidInfo.version.sdkInt,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint("فشل في تسجيل بيانات الجهاز: ${response.body}");
      }
    } catch (e) {
      debugPrint("خطأ في تسجيل معلومات الجهاز: $e");
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool allowed = await isWorkingTimeFromServer();
      if (!allowed) {
        _showError('❌ التطبيق يعمل فقط خلال أوقات الدوام الرسمية (الأحد إلى الخميس من 8 صباحًا إلى 4 بعد الظهر)');
        return;
      }

      final loginResponse = await http.post(
        Uri.parse(_loginUrl),
        body: {
          'Uname': _usernameController.text.trim(),
          'Upassword': _passwordController.text.trim(),
          'device_id': widget.deviceId,
        },
      ).timeout(const Duration(seconds: 30));

      if (loginResponse.statusCode == 200) {
        await _logDeviceInfo();
      }

      _handleLoginResponse(loginResponse);
    } catch (e) {
      _showError('حدث خطأ أثناء تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLoginResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    try {
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChoicePage03()),
        );
      } else {
        _showError(data['message'] ?? 'بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      _showError('خطأ في معالجة الاستجابة من الخادم');
      debugPrint('JSON parsing error: $e');
    }
  }

  void _showError(String message) {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_person, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        'تسجيل الدخول',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Text(
                      //   'رقم الجهاز: ${widget.deviceId}',
                      //   style: TextStyle(color: Colors.white70, fontSize: 12),
                      // ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'اسم المستخدم',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          validator: (value) => value!.isEmpty ? 'الرجاء إدخال اسم المستخدم' : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'كلمة المرور',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          validator: (value) => value!.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'الإصدار 1.5',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}