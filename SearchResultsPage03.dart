
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SearchResultsPage03 extends StatefulWidget {
  @override
  _SearchResultsPage03State createState() => _SearchResultsPage03State();
}

class _SearchResultsPage03State extends State<SearchResultsPage03> {
  final TextEditingController searchController = TextEditingController();
  String selectedYear = DateTime.now().year.toString();
  List<Map<String, dynamic>> results = [];
  bool isLoading = false;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSamples();
  }

  Future<void> _loadRecentSamples() async {
    setState(() {
      isLoading = true;
      isSearching = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hussein.org.ly/new_api/3/search_results.php'),
        body: {
          'query': """
          SELECT Itemsnf.name_senf, tbl_aena.num_aena, tbl_aena.NUM_EKTAR, 
                 importer.name_company, tbl_aena.num_order, tbl_aena.date_aena
          FROM tbl_aena
          INNER JOIN Itemsnf ON tbl_aena.id_name_sonf = Itemsnf.ID
          INNER JOIN importer ON tbl_aena.id_company = importer.ID_num
          WHERE isshow=1 AND tbl_aena.aena_year='$selectedYear' AND id_aena_port=2
          ORDER BY date_aena DESC LIMIT 20
          """
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          results = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب البيانات");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _search() async {
    if (searchController.text.trim().isEmpty) {
      _loadRecentSamples();
      return;
    }

    setState(() {
      isLoading = true;
      isSearching = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hussein.org.ly/new_api/2/search_results.php'),
        body: {
          'query': """
          SELECT Itemsnf.name_senf, tbl_aena.num_aena, tbl_aena.NUM_EKTAR, 
                 importer.name_company, tbl_aena.num_order, tbl_aena.date_aena
          FROM tbl_aena
          INNER JOIN Itemsnf ON tbl_aena.id_name_sonf = Itemsnf.ID
          INNER JOIN importer ON tbl_aena.id_company = importer.ID_num
          WHERE isshow=1 AND (tbl_aena.num_aena='${searchController.text.trim()}' 
                 OR tbl_aena.num_order='${searchController.text.trim()}' 
                 OR tbl_aena.NUM_EKTAR='${searchController.text.trim()}')
                 AND tbl_aena.aena_year='$selectedYear' AND id_aena_port=2
          ORDER BY date_aena DESC
          """
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          results = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء البحث");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج البحث'),
        centerTitle: true,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'ابحث برقم الطلب، العينة أو الإخطار',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _loadRecentSamples();
                        },
                      )
                          : null,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: Text(
                    'بحث',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'السنة:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedYear,
                  onChanged: (newValue) {
                    setState(() {
                      selectedYear = newValue!;
                    });
                    isSearching ? _search() : _loadRecentSamples();
                  },
                  items: List.generate(5, (index) {
                    final year = (DateTime.now().year - index).toString();
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }),
                ),
                Spacer(),
                if (isSearching && results.isNotEmpty)
                  Text(
                    '${results.length} نتيجة',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Divider(height: 20),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      isSearching
                          ? 'لا توجد نتائج مطابقة للبحث'
                          : 'لا توجد عينات حديثة',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final date = item['date_aena'] != null
                      ? DateFormat('yyyy-MM-dd').format(
                      DateTime.parse(item['date_aena']))
                      : 'غير محدد';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        '${item['name_senf'] ?? 'غير محدد'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          _buildInfoRow('رقم العينة:', item['num_aena']),
                          _buildInfoRow('رقم الطلب:', item['num_order']),
                          _buildInfoRow('رقم الإخطار:', item['NUM_EKTAR']),
                          _buildInfoRow('الشركة:', item['name_company']),
                          _buildInfoRow('التاريخ:', date),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'غير محدد',
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}