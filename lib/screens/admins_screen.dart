import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AuthProvider>().api.getAdmins();
      if (!mounted) return;
      setState(() {
        _admins = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _showForm({Map<String, dynamic>? admin}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminFormDialog(admin: admin),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete admin?'),
        content: Text('${admin['full_name']} will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<AuthProvider>().api.deleteAdmin(admin['id']);
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _admins.isEmpty
            ? ListView(children: const [
          SizedBox(height: 120),
          Center(child: Text('No admins yet. Tap + to add one.')),
        ])
            : ListView.builder(
          itemCount: _admins.length,
          itemBuilder: (_, i) {
            final a = _admins[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(a['full_name'] ?? ''),
                subtitle: Text('@${a['username'] ?? ''}'),
                trailing: Wrap(spacing: 0, children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showForm(admin: a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _delete(a),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminFormDialog extends StatefulWidget {
  final Map<String, dynamic>? admin;
  const _AdminFormDialog({this.admin});

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  late final TextEditingController _username;
  late final TextEditingController _fullName;
  late final TextEditingController _password;
  bool _saving = false;
  bool get _isEdit => widget.admin != null;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.admin?['username'] ?? '');
    _fullName = TextEditingController(text: widget.admin?['full_name'] ?? '');
    _password = TextEditingController();
  }

  Future<void> _save() async {
    if (_username.text.isEmpty || _fullName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and full name are required')),
      );
      return;
    }
    if (!_isEdit && _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    setState(() => _saving = true);
    final api = context.read<AuthProvider>().api;
    try {
      if (_isEdit) {
        await api.updateAdmin(
          widget.admin!['id'],
          _username.text.trim(),
          _fullName.text.trim(),
          _password.text.isEmpty ? null : _password.text,
        );
      } else {
        await api.createAdmin(_username.text.trim(), _fullName.text.trim(), _password.text);
      }
      if (mounted) Navigator.pop(context, true);
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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Admin' : 'Add Admin'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fullName,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _isEdit ? 'New Password (leave blank to keep current)' : 'Password',
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}