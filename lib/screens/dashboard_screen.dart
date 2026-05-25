import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'students_screen.dart';
import 'admins_screen.dart';
import 'settings_screen.dart';
import 'semester_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await context.read<AuthProvider>().api.dashboard();
      if (!mounted) return;
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _navigate(Widget screen) async {
    Navigator.pop(context); // close drawer
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadStats();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final fullName = user?['full_name'] ?? 'Administrator';
    final username = user?['username'] ?? 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        title: const Text('PayTrail'),
        backgroundColor: const Color(0xFF3A2B6A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, fullName, username),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _welcomeBanner(fullName),
            const SizedBox(height: 24),
            const _SectionTitle('Overview'),
            const SizedBox(height: 12),
            _statsGrid(),
            const SizedBox(height: 24),
            const _SectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            _quickActions(),
            const SizedBox(height: 24),
            const _SectionTitle('Payment Summary'),
            const SizedBox(height: 12),
            _paymentSummaryCard(),
          ],
        ),
      ),
    );
  }

  // ---------- DRAWER ----------
  Widget _buildDrawer(BuildContext context, String fullName, String username) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A2B6A), Color(0xFF2F215B)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@$username',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.dashboard_outlined, 'Dashboard', null, active: true),
                _drawerItem(Icons.people_outline, 'Manage Students', const StudentsScreen()),
                _drawerItem(Icons.admin_panel_settings_outlined, 'Manage Admins', const AdminsScreen()),
                _drawerItem(Icons.settings_outlined, 'System Settings', const SettingsScreen()),
                _drawerItem(Icons.receipt_long_outlined, 'Semester Report', const SemesterReportScreen()),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF3A2B6A)),
                SizedBox(width: 8),
                Text(
                  'PayTrail v1.0',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Widget? screen, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3A2B6A).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? const Color(0xFF3A2B6A) : Colors.grey.shade700),
        title: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF3A2B6A) : Colors.grey.shade800,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          if (screen != null) {
            _navigate(screen);
          } else {
            Navigator.pop(context); // already on dashboard
          }
        },
      ),
    );
  }

  // ---------- WELCOME BANNER ----------
  Widget _welcomeBanner(String fullName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final firstName = fullName.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2B6A), Color(0xFF6B5BAF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Here\'s what\'s happening today.',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------- STATS GRID ----------
  Widget _statsGrid() {
    final total = _stats?['total'] ?? 0;
    final paid = _stats?['paid'] ?? 0;
    final partial = _stats?['partial'] ?? 0;
    final unpaid = _stats?['unpaid'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        _statCard('Total Students', total, Icons.people, const Color(0xFF3A2B6A)),
        _statCard('Fully Paid', paid, Icons.check_circle, const Color(0xFF00C897)),
        _statCard('Partial', partial, Icons.timelapse, const Color(0xFFFF9F43)),
        _statCard('Unpaid', unpaid, Icons.warning, const Color(0xFFFF6B6B)),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- QUICK ACTIONS ----------
  Widget _quickActions() {
    return Row(
      children: [
        Expanded(child: _actionCard(
          Icons.person_add, 'Add Student', const Color(0xFF3A2B6A),
              () => _navigate(const StudentsScreen()),
        )),
        const SizedBox(width: 12),
        Expanded(child: _actionCard(
          Icons.settings, 'Settings', const Color(0xFF4FA8FF),
              () => _navigate(const SettingsScreen()),
        )),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2A44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- PAYMENT SUMMARY CARD ----------
  Widget _paymentSummaryCard() {
    final total = (_stats?['total'] ?? 0) as int;
    final paid = (_stats?['paid'] ?? 0) as int;
    final partial = (_stats?['partial'] ?? 0) as int;
    final unpaid = (_stats?['unpaid'] ?? 0) as int;
    final paidPct = total > 0 ? (paid / total) : 0.0;
    final partialPct = total > 0 ? (partial / total) : 0.0;
    final unpaidPct = total > 0 ? (unpaid / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2A44),
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No students recorded yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    Expanded(
                      flex: (paidPct * 100).round(),
                      child: Container(color: const Color(0xFF00C897)),
                    ),
                    Expanded(
                      flex: (partialPct * 100).round(),
                      child: Container(color: const Color(0xFFFF9F43)),
                    ),
                    Expanded(
                      flex: (unpaidPct * 100).round(),
                      child: Container(color: const Color(0xFFFF6B6B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _legendRow(const Color(0xFF00C897), 'Fully Paid', paid, total),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFFF9F43), 'Partial', partial, total),
            const SizedBox(height: 8),
            _legendRow(const Color(0xFFFF6B6B), 'Unpaid', unpaid, total),
          ],
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2A44),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF666666),
      letterSpacing: 0.5,
    ),
  );
}