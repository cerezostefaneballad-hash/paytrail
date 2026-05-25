import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SemesterReportScreen extends StatefulWidget {
  const SemesterReportScreen({super.key});

  @override
  State<SemesterReportScreen> createState() => _SemesterReportScreenState();
}

class _SemesterReportScreenState extends State<SemesterReportScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String _selectedYear = '';
  String _selectedSemester = '';
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final response = await api.getSemesterReport(
        academicYear: _selectedYear.isEmpty ? null : _selectedYear,
        semester: _selectedSemester.isEmpty ? null : _selectedSemester,
      );
      if (!mounted) return;
      setState(() {
        _report = response;
        final years = response['available_years'];
        if (years != null && years is List) {
          _availableYears = List<String>.from(years);
        } else {
          _availableYears = [];
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
          ? const Center(child: Text('No report data available'))
          : Column(
        children: [
          _buildFilterBar(),
          _buildSummaryCards(),
          Expanded(child: _buildReportList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedYear.isEmpty ? null : _selectedYear,
              hint: const Text('All Years'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Years')),
                ..._availableYears.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedYear = value ?? '';
                });
                _loadReport();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSemester.isEmpty ? null : _selectedSemester,
              hint: const Text('All Semesters'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('All Semesters')),
                DropdownMenuItem(value: '1st sem', child: Text('1st Semester')),
                DropdownMenuItem(value: '2nd sem', child: Text('2nd Semester')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value ?? '';
                });
                _loadReport();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _report?['summary'];
    final totalStudents = summary != null && summary['total_students'] != null
        ? summary['total_students']
        : 0;
    final totalCollected = summary != null && summary['total_collected'] != null
        ? (summary['total_collected'] as num).toDouble()
        : 0.0;
    final totalReceivable = summary != null && summary['total_receivable'] != null
        ? (summary['total_receivable'] as num).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              'Total Students',
              '$totalStudents',
              Icons.people,
              const Color(0xFF3A2B6A),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              'Collected',
              '₱${totalCollected.toStringAsFixed(2)}',
              Icons.receipt,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              'Receivable',
              '₱${totalReceivable.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    final reportList = _report?['report'];
    if (reportList == null || reportList is! List || reportList.isEmpty) {
      return const Center(child: Text('No students found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: reportList.length,
      itemBuilder: (context, index) {
        final student = reportList[index] as Map<String, dynamic>;
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final status = student['status'] as String? ?? 'Not Enrolled';
    Color statusColor;
    if (status == 'Fully Paid') {
      statusColor = Colors.green;
    } else if (status == 'Partial') {
      statusColor = Colors.orange;
    } else if (status == 'Unpaid') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    final hasCarryOver = student['has_carry_over'] == true;
    final carriedAmount = (student['carried_amount'] as num?)?.toDouble() ?? 0.0;
    final fullName = student['full_name'] as String? ?? 'Unknown';
    final studentId = student['student_id'] as String? ?? '';
    final yearLevel = student['year_level'] as String? ?? '';
    final totalPayable = (student['total_payable'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (student['total_paid'] as num?)?.toDouble() ?? 0.0;
    final outstandingBalance = (student['outstanding_balance'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Text(
            fullName.isNotEmpty ? fullName.substring(0, 1) : '?',
            style: TextStyle(color: statusColor),
          ),
        ),
        title: Text(fullName),
        subtitle: Text('ID: $studentId • Year: $yearLevel'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCarryOver)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Carry-over balance: ₱${carriedAmount.toStringAsFixed(2)} from previous term',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                _infoRow('Total Payable', '₱${totalPayable.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _infoRow('Total Paid', '₱${totalPaid.toStringAsFixed(2)}', color: Colors.green),
                const SizedBox(height: 6),
                _infoRow('Outstanding Balance', '₱${outstandingBalance.toStringAsFixed(2)}',
                    color: outstandingBalance > 0 ? Colors.red : Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}