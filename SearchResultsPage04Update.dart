import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchResultsPage04Update extends StatefulWidget {
  @override
  _SearchResultsPage04UpdateState createState() => _SearchResultsPage04UpdateState();
}

class _SearchResultsPage04UpdateState extends State<SearchResultsPage04Update> {
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
                 importer.name_company, tbl_aena.num_order, tbl_aena.date_aena, tbl_aena.id
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
                 importer.name_company, tbl_aena.num_order, tbl_aena.date_aena, tbl_aena.id
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

  void _editSample(Map<String, dynamic> sample) {
    Get.to(() => EditSamplePage(sample: sample));
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('بحث'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final sample = results[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('العينة: ${sample['num_aena']} | ${sample['name_senf']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الإخطار: ${sample['NUM_EKTAR']}'),
                        Text('الشركة: ${sample['name_company']}'),
                        Text('الطلب: ${sample['num_order']}'),
                        Text('التاريخ: ${sample['date_aena']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSample(sample),
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
}

// صفحة التعديل (بشكل مبدأي - يمكن توسعتها لاحقاً)
class EditSamplePage extends StatelessWidget {
  final Map<String, dynamic> sample;

  const EditSamplePage({required this.sample});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تعديل العينة"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text("هنا سيتم تعديل العينة رقم: ${sample['num_aena']} (لم يتم تنفيذ النموذج بعد)"),
      ),
    );
  }
}
