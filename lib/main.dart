// ============================================================
// PGP Admin — Flutter Web
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ─── Admin emails ─────────────────────────────────────────────
// Add your admin email addresses here
const List<String> kAdminEmails = [
  'henrik@lupontech.com',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

// ─── App ─────────────────────────────────────────────────────
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PGP Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF185FA5)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF185FA5), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final email = snapshot.data!.email ?? '';
          if (kAdminEmails.contains(email)) {
            return const AdminShell();
          }
          // Logged in but not admin
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 48, color: Color(0xFFA32D2D)),
                const SizedBox(height: 16),
                const Text('Access denied', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign out'),
                ),
              ]),
            ),
          );
        }
        return const LoginScreen();
      },
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'Sign in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE0E0E0))),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF185FA5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 10),
                  const Text('PGP Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 24),
                _label('Email'),
                const SizedBox(height: 5),
                TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'admin@pgp.se')),
                const SizedBox(height: 12),
                _label('Password'),
                const SizedBox(height: 5),
                TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: '••••••••'), onSubmitted: (_) => _login()),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFA32D2D))),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF185FA5), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Admin Shell ──────────────────────────────────────────────
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _search = '';
  DocumentSnapshot? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(children: [
        // Sidebar
        Container(
          width: 220,
          decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFE8E8E8)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF185FA5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                const Text('PGP Admin', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 8),
            _navItem(Icons.people_outlined, 'Kunder', true),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, size: 14),
                label: const Text('Sign out', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF666666), side: const BorderSide(color: Color(0xFFDDDDDD)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ),
          ]),
        ),

        // Main content
        Expanded(
          child: _selectedCustomer == null
              ? _CustomerList(
            search: _search,
            onSearchChanged: (v) => setState(() => _search = v),
            onCustomerSelected: (doc) => setState(() => _selectedCustomer = doc),
          )
              : _CustomerDetail(
            doc: _selectedCustomer!,
            onBack: () => setState(() => _selectedCustomer = null),
          ),
        ),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Container(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F0FA) : Colors.transparent,
        border: Border(left: BorderSide(color: active ? const Color(0xFF185FA5) : Colors.transparent, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: active ? const Color(0xFF185FA5) : const Color(0xFF888888)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w500 : FontWeight.w400, color: active ? const Color(0xFF185FA5) : const Color(0xFF555555))),
      ]),
    );
  }
}

// ─── Customer List ────────────────────────────────────────────
class _CustomerList extends StatelessWidget {
  final String search;
  final Function(String) onSearchChanged;
  final Function(DocumentSnapshot) onCustomerSelected;

  const _CustomerList({required this.search, required this.onSearchChanged, required this.onCustomerSelected});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
        color: Colors.white,
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kunder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            SizedBox(height: 2),
            Text('Alla registrerade kunder', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ])),
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Sök på namn eller email...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF888888)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE8E8E8)),

      // Table
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('customers').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Inga kunder ännu.', style: TextStyle(color: Color(0xFF888888))));
            }

            var docs = snapshot.data!.docs;

            // Filter by search
            if (search.isNotEmpty) {
              final q = search.toLowerCase();
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['companyName'] ?? '').toLowerCase();
                final email = (data['email'] ?? '').toLowerCase();
                final num = (data['customerNumber'] ?? '').toLowerCase();
                return name.contains(q) || email.contains(q) || num.contains(q);
              }).toList();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                child: Column(children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                    child: Row(children: [
                      _th('Företag', flex: 3),
                      _th('Email', flex: 3),
                      _th('Kundnummer', flex: 2),
                      _th('PGP ID', flex: 2),
                      _th('Registrerad', flex: 2),
                      const SizedBox(width: 40),
                    ]),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),

                  // Rows
                  ...docs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final doc = entry.value;
                    final d = doc.data() as Map<String, dynamic>;
                    final isLast = i == docs.length - 1;
                    final ts = d['createdAt'] as Timestamp?;
                    final date = ts != null ? _formatDate(ts.toDate()) : '—';

                    return Column(children: [
                      InkWell(
                        onTap: () => onCustomerSelected(doc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            Expanded(flex: 3, child: Row(children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFE8F0FA),
                                child: Text(
                                  (d['companyName'] ?? '?').toString().isNotEmpty ? (d['companyName'] as String)[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(child: Text(d['companyName'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ])),
                            Expanded(flex: 3, child: Text(d['email'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Text(d['customerNumber'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                            Expanded(flex: 2, child: Text(d['pgpId'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                            Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)))),
                            Icon(Icons.chevron_right, size: 18, color: const Color(0xFF888888)),
                          ]),
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                    ]);
                  }),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4)),
  );

  String _formatDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';
  String _month(int m) => ['jan','feb','mar','apr','maj','jun','jul','aug','sep','okt','nov','dec'][m - 1];
}

// ─── Customer Detail ──────────────────────────────────────────
class _CustomerDetail extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onBack;
  const _CustomerDetail({required this.doc, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'] as Timestamp?;
    final date = ts != null ? _formatDate(ts.toDate()) : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back button
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Tillbaka till kundlistan'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF185FA5), padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 20),

        // Customer header
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F0FA),
            child: Text(
              (d['companyName'] ?? '?').toString().isNotEmpty ? (d['companyName'] as String)[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['companyName'] ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${d['customerNumber'] ?? '—'} · Registrerad $date', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ]),
        ]),
        const SizedBox(height: 24),

        // Info grid
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _infoCard('Kontaktuppgifter', [
            _infoRow('Email', d['email']),
            _infoRow('PGP ID', d['pgpId']),
            _infoRow('Org.nummer', d['vatNumber']),
          ])),
          const SizedBox(width: 16),
          Expanded(child: _infoCard('Adress', [
            _infoRow('Gatuadress', d['address']),
            _infoRow('Postnummer', d['postalCode']),
            _infoRow('Stad', d['city']),
            _infoRow('Land', d['country']),
          ])),
        ]),
        const SizedBox(height: 16),

        // Orders
        _OrdersSection(uid: doc.id),
        const SizedBox(height: 16),

        // Subscriptions
        _SubscriptionsSection(uid: doc.id),
      ]),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      ...rows,
    ]),
  );

  Widget _infoRow(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)))),
      Expanded(child: Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  String _formatDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';
  String _month(int m) => ['jan','feb','mar','apr','maj','jun','jul','aug','sep','okt','nov','dec'][m - 1];
}

// ─── Orders Section ───────────────────────────────────────────
class _OrdersSection extends StatelessWidget {
  final String uid;
  const _OrdersSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Orders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('customers').doc(uid).collection('orders').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Text('Inga orders ännu.', style: TextStyle(fontSize: 13, color: Color(0xFF888888)));
            return Column(children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final ts = d['createdAt'] as Timestamp?;
              final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '—';
              final status = d['status'] ?? 'pending';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['orderNumber'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text('${d['productType'] == 'terminal' ? 'Endast terminal' : 'Allt-i-ett'} · ${d['total']} kr/mån · $date', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ])),
                  _statusBadge(status),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'paid': bg = const Color(0xFFE6F4EA); fg = const Color(0xFF2E7D32); label = 'Betald'; break;
      case 'cancelled': bg = const Color(0xFFF0F0F0); fg = const Color(0xFF888888); label = 'Avbruten'; break;
      default: bg = const Color(0xFFFFF8E1); fg = const Color(0xFFE65100); label = 'Väntande';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ─── Subscriptions Section ────────────────────────────────────
class _SubscriptionsSection extends StatelessWidget {
  final String uid;
  const _SubscriptionsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Subscriptions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('customers').doc(uid).collection('subscriptions').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Text('Inga subscriptions ännu.', style: TextStyle(fontSize: 13, color: Color(0xFF888888)));
            return Column(children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final cancelled = d['status'] == 'cancelled';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(d['price'] ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: cancelled ? const Color(0xFFF0F0F0) : const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(cancelled ? 'Avslutad' : 'Aktiv', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cancelled ? const Color(0xFF888888) : const Color(0xFF2E7D32))),
                  ),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────
Widget _label(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.5));