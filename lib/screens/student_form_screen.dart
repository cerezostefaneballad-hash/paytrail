import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/student.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  late final TextEditingController _sid;
  late final TextEditingController _first;
  late final TextEditingController _middle;
  late final TextEditingController _last;
  late String _year;

  late final TextEditingController _amt1;
  late final TextEditingController _amt2;
  late final TextEditingController _amt3;

  String? _date1;
  String? _date2;
  String? _date3;

  bool _saving = false;
  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _sid    = TextEditingController(text: s?.studentId ?? '');
    _first  = TextEditingController(text: s?.firstName ?? '');
    _middle = TextEditingController(text: s?.middleName ?? '');
    _last   = TextEditingController(text: s?.lastName ?? '');
    _year   = s?.yearLevel ?? '1';
    _amt1   = TextEditingController(text: s?.firstAmount.toString()  ?? '0');
    _amt2   = TextEditingController(text: s?.secondAmount.toString() ?? '0');
    _amt3   = TextEditingController(text: s?.thirdAmount.toString()  ?? '0');
    _date1  = s?.firstDate;
    _date2  = s?.secondDate;
    _date3  = s?.thirdDate;
  }

  Future<void> _save() async {
    if (_sid.text.isEmpty || _first.text.isEmpty || _last.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() => _saving = true);
    final api = context.read<AuthProvider>().api;
    final payload = Student(
      studentId: _sid.text.trim(),
      firstName: _first.text.trim(),
      middleName: _middle.text.trim().isEmpty ? null : _middle.text.trim(),
      lastName: _last.text.trim(),
      yearLevel: _year,
      firstAmount: double.tryParse(_amt1.text) ?? 0,
      firstDate: _date1,
      secondAmount: double.tryParse(_amt2.text) ?? 0,
      secondDate: _date2,
      thirdAmount: double.tryParse(_amt3.text) ?? 0,
      thirdDate: _date3,
    );
    try {
      if (_isEdit) {
        await api.updateStudent(widget.student!.id!, payload);
      } else {
        await api.createStudent(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(int which) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final iso = picked.toIso8601String().substring(0, 10);
      setState(() {
        if (which == 1) _date1 = iso;
        if (which == 2) _date2 = iso;
        if (which == 3) _date3 = iso;
      });
    }
  }

  Widget _paymentRow(String label, TextEditingController amt, int which, String? date) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: amt,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _pickDate(which),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(date ?? 'Pick date'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Student' : 'Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _sid,    decoration: const InputDecoration(labelText: 'Student ID *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _first,  decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _middle, decoration: const InputDecoration(labelText: 'Middle Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _last,   decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _year,
            decoration: const InputDecoration(labelText: 'Year Level', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: '1', child: Text('1st year')),
              DropdownMenuItem(value: '2', child: Text('2nd year')),
              DropdownMenuItem(value: '3', child: Text('3rd year')),
              DropdownMenuItem(value: '4', child: Text('4th year')),
            ],
            onChanged: (v) => setState(() => _year = v ?? '1'),
          ),
          const SizedBox(height: 24),
          const Text('Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _paymentRow('1st Payment', _amt1, 1, _date1), const SizedBox(height: 12),
          _paymentRow('2nd Payment', _amt2, 2, _date2), const SizedBox(height: 12),
          _paymentRow('3rd Payment', _amt3, 3, _date3),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _saving ? const CircularProgressIndicator() : const Text('Save'),
          ),
        ]),
      ),
    );
  }
}