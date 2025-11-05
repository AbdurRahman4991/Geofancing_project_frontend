import 'package:flutter/material.dart';
import '/services/attendance_history_api_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/helpers/date_helper.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  List<dynamic> attendanceData = [];
  bool isLoading = true;
  String? selectedStatus;
  String? selectedMonth;
  String? selectedYear;
  @override
  void initState() {
    super.initState();
    fetchAttendanceData(); // Load when screen opens
  }

  Color _getStatusColor(String? status) {
  switch (status) {
    case 'Absent':
    case 'Weekend Holyday':
    case 'Goverment Holyday':
      return Colors.red; // লাল রঙ
    case 'Checked In':
      return Colors.green; // সবুজ রঙ
    case 'Checked Out':
    case 'Auto Checked Out':
      return Colors.orange; // কমলা রঙ
    case 'Outside Area':
      return Colors.blue; // নীল রঙ
    default:
      return Colors.black; // ডিফল্ট কালো
  }
}


  /// ✅ Fetch attendance data with filters
  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);

    try {
      final result = await AttendanceHistoryApiService.getAttendanceHistory(
        month: selectedMonth,
        status: selectedStatus,
        year: selectedYear,
      );

      setState(() {
        attendanceData = result?['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching attendance data: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Clear all filters
  void clearFilters() {
    setState(() {
      selectedStatus = null;
      selectedMonth = null;
      selectedYear = null;
    });
    fetchAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔽 Filters with Scrollable Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ✅ Status filter
                  DropdownButton2<String>(
                    value: selectedStatus,
                    hint: const Text("Status"),
                    items: const [
                      DropdownMenuItem(value: 'Checked In', child: Text('Checked In')),
                      DropdownMenuItem(value: 'Checked Out', child: Text('Checked Out')),
                      DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value);
                      fetchAttendanceData();
                    },
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ Month filter (Scrollable 12 months)
                  DropdownButton2<String>(
                    value: selectedMonth,
                    hint: const Text("Month"),
                    items: const [
                      DropdownMenuItem(value: 'january', child: Text('January')),
                      DropdownMenuItem(value: 'february', child: Text('February')),
                      DropdownMenuItem(value: 'march', child: Text('March')),
                      DropdownMenuItem(value: 'april', child: Text('April')),
                      DropdownMenuItem(value: 'may', child: Text('May')),
                      DropdownMenuItem(value: 'june', child: Text('June')),
                      DropdownMenuItem(value: 'july', child: Text('July')),
                      DropdownMenuItem(value: 'august', child: Text('August')),
                      DropdownMenuItem(value: 'september', child: Text('September')),
                      DropdownMenuItem(value: 'october', child: Text('October')),
                      DropdownMenuItem(value: 'november', child: Text('November')),
                      DropdownMenuItem(value: 'december', child: Text('December')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedMonth = value);
                      fetchAttendanceData();
                    },
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ Year filter
                  DropdownButton2<String>(
                    value: selectedYear,
                    hint: const Text("Year"),
                    items: const [
                      DropdownMenuItem(value: '2025', child: Text('2025')),
                      DropdownMenuItem(value: '2024', child: Text('2024')),
                      DropdownMenuItem(value: '2023', child: Text('2023')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedYear = value);
                      fetchAttendanceData();
                    },
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ Clear button
                  ElevatedButton.icon(
                    onPressed: clearFilters,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text("Clear"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🧾 Attendance Table / Loader
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceData.isEmpty
                      ? const Center(child: Text("No data found"))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(width: 1, color: Colors.grey),
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Check In')),
                              DataColumn(label: Text('Check Out')),
                              DataColumn(label: Text('Late')),
                              DataColumn(label: Text('Status')),
                            ],
                         rows: attendanceData.asMap().entries.map((entry) {
                          final index = entry.key + 1; // 👉 ইনডেক্স 1 থেকে শুরু হবে
                          final row = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(Text(index.toString())),
                              DataCell(Text(DateHelper.formatDate(row['check_in_time']))),
                              DataCell(Text(DateHelper.formatDate(row['check_out_time']))),
                              //DataCell( Container(color: ,) Text(  row['late'] ?? '-')),
                              DataCell(
                                Container(
                                    color: (row['late'] != null && row['late'].toString().isNotEmpty)
                                        ? Colors.yellow
                                        : Colors.transparent, // null বা empty হলে কোনো ব্যাকগ্রাউন্ড নেই
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      row['late']?.toString() ?? '-',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              DataCell(Text(row['status'] ?? '-', style: TextStyle(color: _getStatusColor(row['status'])),)),
                            ],
                          );
                        }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

