import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _acadYear = TextEditingController();
  final _fee = TextEditingController();
  String _semester = '1st sem';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await context.read<AuthProvider>().api.getSettings();
      if (!mounted) return;
      if (s != null) {
        _acadYear.text = s['acad_year']?.toString() ?? '';
        _fee.text = s['semestral_fee']?.toString() ?? '';
        _semester = s['semester']?.toString() ?? '1st sem';
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _save() async {
    if (_acadYear.text.isEmpty || _fee.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    final feeValue = double.tryParse(_fee.text);
    if (feeValue == null || feeValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid fee amount')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().api.saveSettings(
        _acadYear.text.trim(),
        _semester,
        feeValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(child: Text(
                  'These settings define the active academic term and the semestral fee used to compute student balances.',
                  style: TextStyle(fontSize: 13),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _acadYear,
            decoration: const InputDecoration(
              labelText: 'Academic Year',
              hintText: 'e.g. 2025-2026',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _semester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1st sem', child: Text('1st Semester')),
              DropdownMenuItem(value: '2nd sem', child: Text('2nd Semester')),
            ],
            onChanged: (v) => setState(() => _semester = v ?? '1st sem'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Semestral Fee (₱)',
              hintText: 'e.g. 500.00',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Save Settings', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}