import 'package:flutter/material.dart';
import 'package:fproject/show/SearchResultsPage03.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
//import 'package:fproject/search_results.dart';

class DropDownPage03 extends StatefulWidget {
  @override
  _DropDownPage03State createState() => _DropDownPage03State();
}

class _DropDownPage03State extends State<DropDownPage03> {
  final String baseUrl = 'https://hussein.org.ly/new_api/3/';
  final _formKey = GlobalKey<FormState>();

  List companies = [], items = [], countries = [];
  bool _isLoading = false;

  TextEditingController orderDateController = TextEditingController();
  TextEditingController orderNumberController = TextEditingController();
  TextEditingController noticeNumberController = TextEditingController();
  TextEditingController sampleNumberController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController itemController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/get_companies01.php')),
        http.get(Uri.parse('$baseUrl/get_items.php')),
        http.get(Uri.parse('$baseUrl/get_countries.php')),
      ]);

      setState(() {
        companies = json.decode(responses[0].body);
        items = json.decode(responses[1].body);
        countries = json.decode(responses[2].body);
      });
    } catch (e) {
      _showError('خطأ في تحميل البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateOrderNumber() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_order_number.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orderNumberController.text = data['last_number'].toString();
        });
        await http.post(
          Uri.parse('$baseUrl/update_order_number.php'),
          body: {'number': orderNumberController.text},
        );
      } else {
        _showError('فشل في توليد رقم الطلب');
      }
    } catch (e) {
      _showError('خطأ في توليد رقم الطلب: $e');
    }
  }

  bool _isValidValueInList(List list, String key, String value) {
    return list.any((item) => item[key].toString().trim() == value.trim());
  }

  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isValidValueInList(companies, 'name_company', companyController.text) ||
        !_isValidValueInList(items, 'name_senf', itemController.text) ||
        !_isValidValueInList(countries, 'namec', countryController.text)) {
      _showError('القيمة المدخلة غير موجودة في القائمة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? idCompany = _getIdByName(companies, 'name_company', 'ID_num', companyController.text);
      String? idItem = _getIdByName(items, 'name_senf', 'ID', itemController.text);
      String? idCountry = _getIdByName(countries, 'namec', 'ID', countryController.text);
//nameCompany
      String? nameCompany = _getIdByName(companies, 'name_company', 'name_company', companyController.text);
      String? nameItem = _getIdByName(items, 'name_senf', 'name_senf', itemController.text);

      final response = await http.post(
        //
        //Uri.parse('$baseUrl/save_order.php'),
        Uri.parse('$baseUrl/add_data.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "number_talab": orderNumberController.text,
          "date_number_talab": orderDateController.text,
          "year_number_talab": DateTime.parse(orderDateController.text).year,
          "num_Aektar": noticeNumberController.text,
          "num_aena": sampleNumberController.text,
          "id_company": idCompany,
          "id_item": idItem,
          "id_country": idCountry,
          "name_company": nameCompany,
          "name_item": nameItem,
        }),
      );

      final data = json.decode(response.body);
      _showSuccess(data['message'] ?? 'تم الحفظ بنجاح');
    } catch (e) {
      _showError('حدث خطأ أثناء حفظ البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _formKey.currentState?.reset();
    setState(() {
      orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      orderNumberController.clear();
      noticeNumberController.clear();
      sampleNumberController.clear();
      companyController.clear();
      itemController.clear();
      countryController.clear();
    });
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأكيد المسح", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("هل أنت متأكد أنك تريد مسح جميع البيانات؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearFields();
            },
            child: Text("نعم، امسح", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String? _getIdByName(List dataList, String nameKey, String idKey, String name) {
    final match = dataList.firstWhere(
          (e) => e[nameKey].toString().trim() == name.trim(),
      orElse: () => null,
    );
    return match != null ? match[idKey].toString() : null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdownSearch({
    required String label,
    required List sourceList,
    required String displayKey,
    required TextEditingController controller,
    required String validationMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TypeAheadFormField(
        textFieldConfiguration: TextFieldConfiguration(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade300),
            ),
            filled: true,
            fillColor: Colors.blue.shade50,
            prefixIcon: Icon(Icons.search, color: Colors.blue),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                controller.clear();
                setState(() {});
              },
            )
                : null,
          ),
        ),
        suggestionsCallback: (pattern) {
          return sourceList.where((item) =>
          item[displayKey] != null &&
              item[displayKey].toString().toLowerCase().startsWith(pattern.toLowerCase()));
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            title: Text(suggestion[displayKey]?.toString() ?? 'غير متوفر'),
            tileColor: Colors.blue.shade50,
          );
        },
        onSuggestionSelected: (suggestion) {
          controller.text = suggestion[displayKey]?.toString() ?? '';
          setState(() {});
        },
        validator: (value) => value!.isEmpty ? validationMessage : null,
        noItemsFoundBuilder: (context) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة عينة جديدة"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDateField(),
              SizedBox(height: 12),
              _buildOrderNumberSection(),
              SizedBox(height: 12),
              _buildDropdownSearch(
                label: "الشركة",
                sourceList: companies,
                displayKey: "name_company",
                controller: companyController,
                validationMessage: "يجب اختيار الشركة",
              ),
              _buildDropdownSearch(
                label: "الصنف",
                sourceList: items,
                displayKey: "name_senf",
                controller: itemController,
                validationMessage: "يجب اختيار الصنف",
              ),
              _buildDropdownSearch(
                label: "بلد المنشأ",
                sourceList: countries,
                displayKey: "namec",
                controller: countryController,
                validationMessage: "يجب اختيار بلد المنشأ",
              ),
              SizedBox(height: 12),
              _buildNumberField("رقم الإخطار", noticeNumberController),
              SizedBox(height: 12),
              _buildSampleNumberField(),
              SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: orderDateController,
      decoration: InputDecoration(
        labelText: "تاريخ الطلب",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        filled: true,
        fillColor: Colors.blue.shade50,
        prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
      ),
      readOnly: true,
      validator: (value) => value!.isEmpty ? "يجب إدخال تاريخ الطلب" : null,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade800,
                  onPrimary: Colors.white,
                  onSurface: Colors.blue.shade800,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            orderDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
          });
        }
      },
    );
  }

  Widget _buildOrderNumberSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: orderNumberController,
            decoration: InputDecoration(
              labelText: "رقم الطلب",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? "يجب إدخال رقم الطلب" : null,
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: _generateOrderNumber,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: Text(
            "توليد رقم",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        filled: true,
        fillColor: Colors.blue.shade50,
      ),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? "يجب إدخال $label" : null,
    );
  }

  Widget _buildSampleNumberField() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField("رقم العينة", sampleNumberController),
        ),
        SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue, size: 32),
              onPressed: () {
                int current = int.tryParse(sampleNumberController.text) ?? 0;
                setState(() {
                  sampleNumberController.text = (current + 1).toString();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red, size: 32),
              onPressed: () {
                int current = int.tryParse(sampleNumberController.text) ?? 0;
                setState(() {
                  sampleNumberController.text = (current > 0 ? current - 1 : 0).toString();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("حفظ البيانات", style: TextStyle(fontSize: 18)),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showClearConfirmationDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("مسح الكل", style: TextStyle(color: Colors.red, fontSize: 18)),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchResultsPage03()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "البحث في العينات",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}