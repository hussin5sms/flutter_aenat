import 'package:flutter/material.dart';
import 'package:fproject/session_manager.dart';
import 'package:fproject/show/DropDownPage03.dart';
import 'package:fproject/show/SearchResultsPage04Update.dart';
import 'package:fproject/time_utils.dart';
import 'package:fproject/webview_page.dart';
import 'package:fproject/DeleteAenaPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChoicePage03 extends StatefulWidget {
  @override
  _ChoicePage03State createState() => _ChoicePage03State();
}

class _ChoicePage03State extends State<ChoicePage03> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    fetchFlagValue();
  }

  Future<void> fetchFlagValue() async {
    try {
      final response = await http.get(
        Uri.parse('https://hussein.org.ly/new_api/3/get_flag.php'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            isChecked = result['flag_value'] == 1;
          });
        } else {
          _showError(result['message']);
        }
      } else {
        _showError("فشل في جلب حالة المفتاح");
      }
    } catch (e) {
      _showError("حدث خطأ أثناء الاتصال بالخادم");
    }
  }

  Future<void> toggleSwitch(bool value) async {
    try {
      final int newFlag = value ? 1 : 0;

      final response = await http.post(
        Uri.parse('https://hussein.org.ly/new_api/3/update_flag.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"flag": newFlag}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            isChecked = value;
          });
        } else {
          _showError(result['message']);
        }
      } else {
        _showError("فشل الاتصال بالسيرفر");
      }
    } catch (e) {
      _showError("حدث خطأ أثناء التحديث");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // إعادة ضبط مؤقت الجلسة عند الضغط على أي زر
          SessionManager().resetSession(context);
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: Size(double.infinity, 70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 28), // للحفاظ على التوازن
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'القائمة الرئيسية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade600,
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // إعادة ضبط مؤقت الجلسة عند لمس أي مكان في الشاشة
          SessionManager().resetSession(context);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [


                      // _buildActionButton(
                      //   title: 'إضافة عينة',
                      //   icon: Icons.add_circle_outline,
                      //   color: Colors.blueAccent,
                      //   onPressed: () {
                      //
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(builder: (context) => DropDownPage03()),
                      //     );
                      //   },
                      // ),
                      _buildActionButton(
                        title: 'إضافة عينة',
                        icon: Icons.add_circle_outline,
                        color: Colors.blueAccent,
                        onPressed: () async {
                          bool isWorkingTime = await checkWorkingTime(context);
                          if (isWorkingTime) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DropDownPage03()),
                            );
                          }
                        },
                      ),



                      _buildActionButton(
                        title: 'تعديل عينة',
                        icon: Icons.edit,
                        color: Colors.green,
                        onPressed: () {

                          // وظيفة التعديل يمكن إضافتها لاحقًا
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => EditSamplePage(sample: sample)), // استبدل بـ اسم الصفحة الحقيقية
                          // );
                        },
                      ),
                      _buildActionButton(
                        title: 'حذف عينة',
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                        onPressed: () async {
    bool isWorkingTime = await checkWorkingTime(context);
    if (isWorkingTime) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeleteAenaPage()),
                          );
    }
                        },
                      ),
                      _buildActionButton(
                        title: 'بحث',
                        icon: Icons.search,
                        color: Colors.lime.shade600,
                        onPressed: () async {
    bool isWorkingTime = await checkWorkingTime(context);
    if (isWorkingTime) {

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SearchResultsPage04Update()),
                          );
                          }
                        },
                      ),
                      _buildActionButton(
                        title: 'عرض صفحة النتائج',
                        icon: Icons.web,
                        color: Colors.orange,
                        onPressed: () async {
                          bool isWorkingTime = await checkWorkingTime(context);
                          if (isWorkingTime) {

    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => WebViewPage(
    url: "https://hussein.org.ly/nfdcc/find03.aspx?token=YourSecureToken123",
    ),
    ),
    );
    }
                        },



                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // إعادة ضبط مؤقت الجلسة عند التفاعل مع السويتش
                  SessionManager().resetSession(context);
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'فتح النسخ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Transform.scale(
                        scale: 1.3,
                        child: Switch(
                          value: isChecked,
                          onChanged: (value) {
                            SessionManager().resetSession(context);
                            toggleSwitch(value);
                          },
                          activeColor: Colors.blue,
                          activeTrackColor: Colors.blue.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'الإصدار 1.5',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}