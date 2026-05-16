import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/student.dart';
import 'student_form_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> _students = [];
  bool _loading = true;
  String _search = '';
  String _year = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AuthProvider>().api
          .getStudents(year: _year, search: _search);
      setState(() {
        _students = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('${s.fullName} will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && s.id != null) {
      await context.read<AuthProvider>().api.deleteStudent(s.id!);
      _load();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Fully Paid': return Colors.green;
      case 'Partial':    return Colors.orange;
      default:           return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StudentFormScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _search = v,
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _year.isEmpty ? null : _year,
                hint: const Text('Year'),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1st year')),
                  DropdownMenuItem(value: '2', child: Text('2nd year')),
                  DropdownMenuItem(value: '3', child: Text('3rd year')),
                  DropdownMenuItem(value: '4', child: Text('4th year')),
                ],
                onChanged: (v) {
                  setState(() => _year = v ?? '');
                  _load();
                },
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? const Center(child: Text('No students found'))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (_, i) {
                  final s = _students[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(s.fullName),
                      subtitle: Text('${s.studentId}  •  ₱${s.balance.toStringAsFixed(2)} balance'),
                      trailing: Wrap(spacing: 4, children: [
                        Chip(
                          label: Text(s.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: _statusColor(s.status),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(s),
                        ),
                      ]),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentFormScreen(student: s)),
                        );
                        _load();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}