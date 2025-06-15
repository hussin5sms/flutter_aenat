
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class EditSamplePage extends StatefulWidget {
  final Map<String, dynamic> sample;

  const EditSamplePage({required this.sample});

  @override
  _EditSamplePageState createState() => _EditSamplePageState();
}

class _EditSamplePageState extends State<EditSamplePage> {
  late TextEditingController numAenaController;
  late TextEditingController numEktarController;
  late TextEditingController numOrderController;
  late TextEditingController dateAenaController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    numAenaController = TextEditingController(text: widget.sample['num_aena']);
    numEktarController = TextEditingController(text: widget.sample['NUM_EKTAR']);
    numOrderController = TextEditingController(text: widget.sample['num_order']);
    dateAenaController = TextEditingController(text: widget.sample['date_aena']);
  }

  Future<void> _saveChanges() async {
    setState(() {
      isSaving = true;
    });

    final response = await http.post(
      Uri.parse('https://hussein.org.ly/new_api/2/update_sample.php'),
      body: {
        'id': widget.sample['id'].toString(),
        'num_aena': numAenaController.text.trim(),
        'NUM_EKTAR': numEktarController.text.trim(),
        'num_order': numOrderController.text.trim(),
        'date_aena': dateAenaController.text.trim(),
      },
    );

    if (response.statusCode == 200 && response.body.contains("success")) {
      Get.snackbar("تم", "تم تعديل البيانات بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(); // العودة بعد الحفظ
    } else {
      Get.snackbar("خطأ", "فشل في تعديل البيانات", backgroundColor: Colors.red, colorText: Colors.white);
    }

    setState(() {
      isSaving = false;
    });
  }

  @override
  void dispose() {
    numAenaController.dispose();
    numEktarController.dispose();
    numOrderController.dispose();
    dateAenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل بيانات العينة'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(numAenaController, "رقم العينة"),
            _buildTextField(numEktarController, "رقم الإخطار"),
            _buildTextField(numOrderController, "رقم الطلب"),
            _buildTextField(dateAenaController, "تاريخ العينة (مثال: 2025-06-06)"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSaving ? null : _saveChanges,
              icon: Icon(Icons.save),
              label: isSaving ? Text("جاري الحفظ...") : Text("حفظ التعديلات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
