import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeleteAenaPage extends StatefulWidget {
  @override
  _DeleteAenaPageState createState() => _DeleteAenaPageState();
}

class _DeleteAenaPageState extends State<DeleteAenaPage> {
  final TextEditingController _numAenaController = TextEditingController();
  bool isLoading = false;

  Future<void> deleteAena() async {
    final String numAena = _numAenaController.text.trim();
    final int currentYear = DateTime.now().year;

    if (numAena.isEmpty) {
      _showMessage("يرجى إدخال رقم العينة");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hussein.org.ly/new_api/2/delete_aena.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "num_aena": numAena,
          "aena_year": currentYear,
        }),
      );

      // اطبع الاستجابة للتصحيح في حالة وجود خطأ
      print("Response body: ${response.body}");

      if (response.headers['content-type']?.contains('application/json') == true) {
        final result = jsonDecode(response.body);
        _showMessage(result['message']);
      } else {
        _showMessage("الرد من الخادم ليس بتنسيق JSON.");
      }
    } catch (e) {
      _showMessage("حدث خطأ أثناء الحذف: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حذف عينة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _numAenaController,
              decoration: InputDecoration(labelText: 'رقم العينة'),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : deleteAena,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('حذف العينة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
