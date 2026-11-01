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

// ─── Secondary Firebase app (invoicecustomer-bdde7) ──────────
const FirebaseOptions _invoiceCustomerOptions = FirebaseOptions(
  apiKey: 'AIzaSyDsG4IiGWDT6rx_w7PJYypYU7YseGWM_G4',
  appId: '1:13475529912:web:af10c1dc5d494cb71aa04d',
  messagingSenderId: '13475529912',
  projectId: 'invoicecustomer-bdde7',
  authDomain: 'invoicecustomer-bdde7.firebaseapp.com',
  storageBucket: 'invoicecustomer-bdde7.appspot.com',
  measurementId: 'G-CGSJ552B70',
);

FirebaseFirestore? invoiceCustomerDb;
String? invoiceCustomerInitError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    final app = await Firebase.initializeApp(
      name: 'invoicecustomer',
      options: _invoiceCustomerOptions,
    );
    invoiceCustomerDb = FirebaseFirestore.instanceFor(app: app);
  } catch (e) {
    try {
      final app = Firebase.app('invoicecustomer');
      invoiceCustomerDb = FirebaseFirestore.instanceFor(app: app);
    } catch (e2) {
      invoiceCustomerInitError = 'Init: $e\nReuse: $e2';
    }
  }
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
  DocumentSnapshot? _selectedInvoice;
  DocumentSnapshot? _selectedEndCustomer;
  DocumentSnapshot? _selectedPrepareOrder;
  int _navIndex = 0; // 0 = Kunder, 1 = Fakturor, 2 = Slutkunder, 3 = Terminaler-köp

  @override
  Widget build(BuildContext context) {
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
            _navItem(Icons.people_outlined, 'Kunder', _navIndex == 0, () {
              setState(() { _navIndex = 0; _search = ''; _selectedCustomer = null; });
            }),
            _navItem(Icons.receipt_long_outlined, 'Fakturor', _navIndex == 1, () {
              setState(() { _navIndex = 1; _search = ''; _selectedInvoice = null; });
            }),
            _navItem(Icons.store_outlined, 'Slutkunder', _navIndex == 2, () {
              setState(() { _navIndex = 2; _search = ''; _selectedEndCustomer = null; });
            }),
            _navItem(Icons.assignment_outlined, 'Terminaler-köp', _navIndex == 3, () {
              setState(() { _navIndex = 3; _search = ''; _selectedPrepareOrder = null; });
            }),
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
          child: _navIndex == 0
              ? (_selectedCustomer == null
                  ? _CustomerList(
                      search: _search,
                      onSearchChanged: (v) => setState(() => _search = v),
                      onCustomerSelected: (doc) => setState(() => _selectedCustomer = doc),
                    )
                  : _CustomerDetail(
                      doc: _selectedCustomer!,
                      onBack: () => setState(() => _selectedCustomer = null),
                    ))
              : _navIndex == 1
                  ? (_selectedInvoice == null
                      ? _InvoiceList(
                          search: _search,
                          onSearchChanged: (v) => setState(() => _search = v),
                          onInvoiceSelected: (doc) => setState(() => _selectedInvoice = doc),
                        )
                      : _InvoiceDetail(
                          doc: _selectedInvoice!,
                          onBack: () => setState(() => _selectedInvoice = null),
                        ))
                  : _navIndex == 2
                      ? (_selectedEndCustomer == null
                          ? _EndCustomerList(
                              search: _search,
                              onSearchChanged: (v) => setState(() => _search = v),
                              onSelected: (doc) => setState(() => _selectedEndCustomer = doc),
                            )
                          : _EndCustomerDetail(
                              doc: _selectedEndCustomer!,
                              onBack: () => setState(() => _selectedEndCustomer = null),
                            ))
                      : (_selectedPrepareOrder == null
                          ? _PrepareOrderList(
                              search: _search,
                              onSearchChanged: (v) => setState(() => _search = v),
                              onSelected: (doc) => setState(() => _selectedPrepareOrder = doc),
                            )
                          : _PrepareOrderDetail(
                              doc: _selectedPrepareOrder!,
                              onBack: () => setState(() => _selectedPrepareOrder = null),
                            )),
        ),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
      ),
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

// ─── Invoice List ─────────────────────────────────────────────
class _InvoiceList extends StatefulWidget {
  final String search;
  final Function(String) onSearchChanged;
  final Function(DocumentSnapshot) onInvoiceSelected;

  const _InvoiceList({required this.search, required this.onSearchChanged, required this.onInvoiceSelected});

  @override
  State<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<_InvoiceList> {
  static const int _pageSize = 25;
  final List<DocumentSnapshot> _docs = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    Query q = FirebaseFirestore.instance.collection('invoices1').orderBy('period', descending: true).limit(_pageSize);
    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

    final snap = await q.get();
    setState(() {
      _docs.addAll(snap.docs);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      _hasMore = snap.docs.length == _pageSize;
      _loading = false;
    });
  }

  List<DocumentSnapshot> get _filtered {
    if (widget.search.isEmpty) return _docs;
    final q = widget.search.toLowerCase();
    return _docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['stalle'] ?? '').toString().toLowerCase().contains(q) ||
          (data['faktura'] ?? '').toString().toLowerCase().contains(q) ||
          (data['serienr'] ?? '').toString().toLowerCase().contains(q) ||
          (data['kundref'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Fakturor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${_docs.length} inlästa${_hasMore ? '+' : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ])),
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Sök på ställe, faktura, serie...',
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
      Expanded(
        child: _docs.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _docs.isEmpty
                ? const Center(child: Text('Inga fakturor ännu.', style: TextStyle(color: Color(0xFF888888))))
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                          child: Row(children: [
                            _th('Ställe', flex: 3),
                            _th('Faktura', flex: 2),
                            _th('Serie', flex: 2),
                            _th('Period', flex: 3),
                            _th('Totalsumma', flex: 2),
                            const SizedBox(width: 40),
                          ]),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8E8E8)),
                        ...docs.asMap().entries.map((entry) {
                          final i = entry.key;
                          final doc = entry.value;
                          final d = doc.data() as Map<String, dynamic>;
                          final isLast = i == docs.length - 1;
                          return Column(children: [
                            InkWell(
                              onTap: () => widget.onInvoiceSelected(doc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(children: [
                                  Expanded(flex: 3, child: Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFF0F4FF),
                                      child: Text(
                                        (d['stalle'] ?? '?').toString().isNotEmpty ? (d['stalle'] as String)[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(child: Text(d['stalle'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  ])),
                                  Expanded(flex: 2, child: Text(d['faktura'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                  Expanded(flex: 2, child: Text(d['serienr'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                  Expanded(flex: 3, child: Text(d['period'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 2, child: Text('${d['totalsumma'] ?? '—'} ${d['valutakod'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)))),
                                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
                                ]),
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                          ]);
                        }),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        if (!_hasMore && _docs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Alla ${_docs.length} fakturor inladdade', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ),
                      ]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4)),
  );
}

// ─── Invoice Detail ───────────────────────────────────────────
class _InvoiceDetail extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onBack;
  const _InvoiceDetail({required this.doc, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Tillbaka till fakturalistan'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF185FA5), padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF0F4FF),
            child: Text(
              (d['stalle'] ?? '?').toString().isNotEmpty ? (d['stalle'] as String)[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['stalle'] ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('Faktura ${d['faktura'] ?? '—'} · ${d['period'] ?? '—'}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ]),
        ]),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _infoCard('Fakturauppgifter', [
            _infoRow('Fakturanr', d['faktura']),
            _infoRow('Avtalsnr', d['avtalsnr']),
            _infoRow('Kundref', d['kundref']),
            _infoRow('No', d['No']),
            _infoRow('Period', d['period']),
            _infoRow('Totalsumma', '${d['totalsumma'] ?? '—'} ${d['valutakod'] ?? ''}'),
            _infoRow('Kvantitet', d['kvantitet']),
          ])),
          const SizedBox(width: 16),
          Expanded(child: _infoCard('Terminal & Produkt', [
            _infoRow('Serienr', d['serienr']),
            _infoRow('Site ID', d['siteid']),
            _infoRow('Prodnummer', d['prodnummer']),
            _infoRow('Prodbeskrivning', d['prodbeskrivning']),
          ])),
        ]),
        const SizedBox(height: 16),
        _infoCard('Leveransadress', [
          _infoRow('Gatuadress', d['levadress']),
          _infoRow('Postnummer/Ort', d['postort']),
        ]),
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
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)))),
      Expanded(child: Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

// ─── End Customer List ────────────────────────────────────────
class _EndCustomerList extends StatefulWidget {
  final String search;
  final Function(String) onSearchChanged;
  final Function(DocumentSnapshot) onSelected;

  const _EndCustomerList({required this.search, required this.onSearchChanged, required this.onSelected});

  @override
  State<_EndCustomerList> createState() => _EndCustomerListState();
}

class _EndCustomerListState extends State<_EndCustomerList> {
  static const int _pageSize = 25;
  final List<DocumentSnapshot> _docs = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String? _error;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });

    try {
      final db = invoiceCustomerDb;
      if (db == null) throw Exception(invoiceCustomerInitError ?? 'invoiceCustomerDb är null');

      Query q = db.collectionGroup('appsettings').limit(_pageSize);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

      final snap = await q.get();

      setState(() {
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
        _hasMore = snap.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<DocumentSnapshot> get _filtered {
    if (widget.search.isEmpty) return _docs;
    final q = widget.search.toLowerCase();
    return _docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['corpEmail'] ?? '').toString().toLowerCase().contains(q) ||
          (data['email'] ?? '').toString().toLowerCase().contains(q) ||
          (data['operatorId'] ?? '').toString().toLowerCase().contains(q) ||
          (data['poiId'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Slutkunder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${_docs.length} inlästa${_hasMore ? '+' : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ])),
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Sök på företag, email, operatör...',
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
      Expanded(
        child: _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Fel: $_error', style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13))))
            : _docs.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _docs.isEmpty
                ? const Center(child: Text('Inga slutkunder ännu.', style: TextStyle(color: Color(0xFF888888))))
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                          child: Row(children: [
                            _th('Företag', flex: 3),
                            _th('Email', flex: 3),
                            _th('Operator ID', flex: 2),
                            _th('POI ID', flex: 2),
                            _th('Roll', flex: 2),
                            const SizedBox(width: 40),
                          ]),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8E8E8)),
                        ...docs.asMap().entries.map((entry) {
                          final i = entry.key;
                          final doc = entry.value;
                          final d = doc.data() as Map<String, dynamic>;
                          final isLast = i == docs.length - 1;
                          return Column(children: [
                            InkWell(
                              onTap: () => widget.onSelected(doc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(children: [
                                  Expanded(flex: 3, child: Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFE8F5E9),
                                      child: Text(
                                        (d['corpEmail'] ?? '?').toString().isNotEmpty ? (d['corpEmail'] as String)[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(child: Text(d['corpEmail'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  ])),
                                  Expanded(flex: 3, child: Text(d['email'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
                                  Expanded(flex: 2, child: Text(d['operatorId']?.toString() ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                  Expanded(flex: 2, child: Text(d['poiId'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                  Expanded(flex: 2, child: Text(d['role'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
                                ]),
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                          ]);
                        }),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        if (!_hasMore && _docs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Alla ${_docs.length} slutkunder inladdade', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ),
                      ]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4)),
  );
}

// ─── End Customer Detail ──────────────────────────────────────
class _EndCustomerDetail extends StatefulWidget {
  final DocumentSnapshot doc;
  final VoidCallback onBack;
  const _EndCustomerDetail({required this.doc, required this.onBack});

  @override
  State<_EndCustomerDetail> createState() => _EndCustomerDetailState();
}

class _EndCustomerDetailState extends State<_EndCustomerDetail> {
  bool _updatingRootState = false;
  bool _updatingPoiId = false;
  TextEditingController? _poiIdCtrl;

  String get _uid => widget.doc.reference.parent.parent!.id;

  DocumentReference get _appSettingsRef => invoiceCustomerDb!
      .collection('users')
      .doc(_uid)
      .collection('appsettings')
      .doc('appsettings');

  DocumentReference get _rootStateRef => invoiceCustomerDb!
      .collection('users')
      .doc(_uid)
      .collection('rootstate')
      .doc('rootstate');

  @override
  void initState() {
    super.initState();
    final d = widget.doc.data() as Map<String, dynamic>;
    _poiIdCtrl = TextEditingController(text: (widget.doc.data() as Map<String, dynamic>)['poiId'] ?? '');
  }

  @override
  void dispose() {
    _poiIdCtrl?.dispose();
    super.dispose();
  }

  Future<void> _setPoiId() async {
    setState(() => _updatingPoiId = true);
    try {
      await _appSettingsRef.update({'poiId': _poiIdCtrl?.text.trim()});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fel: $e')));
    } finally {
      if (mounted) setState(() => _updatingPoiId = false);
    }
  }

  Future<void> _setRootState(String value) async {
    setState(() => _updatingRootState = true);
    try {
      await _rootStateRef.set({'status': value}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fel: $e')));
    } finally {
      if (mounted) setState(() => _updatingRootState = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Tillbaka till slutkundlistan'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF185FA5), padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Text(
              (d['corpEmail'] ?? '?').toString().isNotEmpty ? (d['corpEmail'] as String)[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['corpEmail'] ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(d['email'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ]),
        ]),
        const SizedBox(height: 24),

        // Rootstate card
        StreamBuilder<DocumentSnapshot>(
          stream: _rootStateRef.snapshots(),
          builder: (context, snapshot) {
            final status = (snapshot.data?.data() as Map<String, dynamic>?)?['status'] ?? '—';
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('App-läge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Styr vilken vy som visas i appen', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ])),
                if (_updatingRootState)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Row(children: [
                    _modeButton('POS', 'pos', status),
                    const SizedBox(width: 8),
                    _modeButton('VOP', 'vop', status),
                  ]),
              ]),
            );
          },
        ),
        const SizedBox(height: 16),

        // POI ID card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Terminal (POI ID)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Byt terminal genom att ändra POI ID', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _poiIdCtrl!,
                  decoration: InputDecoration(
                    hintText: 't.ex. 713-624-211',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _updatingPoiId ? null : _setPoiId,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _updatingPoiId
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Spara'),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _infoCard('Kontaktuppgifter', [
            _infoRow('Corp Email', d['corpEmail']),
            _infoRow('Email', d['email']),
            _infoRow('Roll', d['role']),
            _infoRow('Inloggad', d['isLoggedIn']),
            _infoRow('Senast inloggad', d['lastLoggedInDate']),
          ])),
          const SizedBox(width: 16),
          Expanded(child: _infoCard('Terminal', [
            _infoRow('Operator ID', d['operatorId']),
            _infoRow('POI ID', d['poiId']),
            _infoRow('Sale ID', d['saleId']),
            _infoRow('Service ID', d['serviceId']?.toString()),
            _infoRow('Valuta', d['currency']),
          ])),
        ]),
      ]),
    );
  }

  Widget _modeButton(String label, String value, String current) {
    final isActive = current == value;
    return FilledButton(
      onPressed: isActive ? null : () => _setRootState(value),
      style: FilledButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF185FA5) : const Color(0xFFEEEEEE),
        foregroundColor: isActive ? Colors.white : const Color(0xFF555555),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
}

// ─── Prepare Order List ───────────────────────────────────────
class _PrepareOrderList extends StatefulWidget {
  final String search;
  final Function(String) onSearchChanged;
  final Function(DocumentSnapshot) onSelected;

  const _PrepareOrderList({required this.search, required this.onSearchChanged, required this.onSelected});

  @override
  State<_PrepareOrderList> createState() => _PrepareOrderListState();
}

class _PrepareOrderListState extends State<_PrepareOrderList> {
  static const int _pageSize = 25;
  final List<DocumentSnapshot> _docs = [];
  final Set<String> _seenSerials = {};
  // cache: kund_ref -> null=loading, true=over limit, false=ok, 'none'=no invoice
  final Map<String, dynamic> _invoiceStatus = {};
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });

    try {
      Query q = FirebaseFirestore.instance.collection('prepare_order_ro').limit(_pageSize);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

      final snap = await q.get();
      final newDocs = <DocumentSnapshot>[];
      setState(() {
        for (final doc in snap.docs) {
          final serial = ((doc.data() as Map<String, dynamic>)['serial_nr'] ?? doc.id).toString();
          if (_seenSerials.add(serial)) { _docs.add(doc); newDocs.add(doc); }
        }
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
        _hasMore = snap.docs.length == _pageSize;
        _loading = false;
      });
      for (final doc in newDocs) _checkInvoice(doc);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _checkInvoice(DocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    final maxRaw = d['inv_max_amount'];
    if (maxRaw == null) return;
    final max = (maxRaw is num) ? maxRaw.toDouble() : double.tryParse(maxRaw.toString());
    if (max == null) return;
    final kundRef = (d['kund_ref'] ?? '').toString();
    if (kundRef.isEmpty || _invoiceStatus.containsKey(kundRef)) return;
    _invoiceStatus[kundRef] = null; // loading
    try {
      final snap = await FirebaseFirestore.instance
          .collection('invoices1')
          .where('kundref', isEqualTo: kundRef)
          .orderBy('period', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) { if (mounted) setState(() => _invoiceStatus[kundRef] = 'none'); return; }
      final inv = snap.docs.first.data() as Map<String, dynamic>;
      final totalStr = (inv['totalsumma'] ?? '').toString().replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      final total = double.tryParse(totalStr) ?? 0;
      if (mounted) setState(() => _invoiceStatus[kundRef] = total > max);
    } catch (_) {
      if (mounted) setState(() => _invoiceStatus[kundRef] = 'none');
    }
  }

  List<DocumentSnapshot> get _filtered {
    final sorted = List<DocumentSnapshot>.from(_docs)..sort((a, b) {
      final ka = ((a.data() as Map<String, dynamic>)['kund_ref'] ?? '').toString();
      final kb = ((b.data() as Map<String, dynamic>)['kund_ref'] ?? '').toString();
      return ka.compareTo(kb);
    });
    if (widget.search.isEmpty) return sorted;
    final q = widget.search.toLowerCase();
    return sorted.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['merchant_site'] ?? '').toString().toLowerCase().contains(q) ||
          (data['merchant_company'] ?? '').toString().toLowerCase().contains(q) ||
          (data['orgnr'] ?? '').toString().toLowerCase().contains(q) ||
          (data['serial_nr'] ?? '').toString().toLowerCase().contains(q) ||
          (data['acquirer'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Terminaler-köp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${_docs.length} inlästa${_hasMore ? '+' : ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ])),
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Sök på butik, företag, orgnr...',
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
      Expanded(
        child: _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Fel: $_error', style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13))))
            : _docs.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _docs.isEmpty
                ? const Center(child: Text('Inga beställningar ännu.', style: TextStyle(color: Color(0xFF888888))))
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8F8F8), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                          child: Row(children: [
                            _th('Butik', flex: 3),
                            _th('Företag', flex: 3),
                            _th('Friendly name', flex: 2),
                            _th('Serienr', flex: 2),
                            _th('Inlösare', flex: 2),
                            _th('Max kr', flex: 2),
                            const SizedBox(width: 40),
                          ]),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8E8E8)),
                        ...() {
                          final rows = <Widget>[];
                          String? lastKundRef;
                          for (int i = 0; i < docs.length; i++) {
                            final doc = docs[i];
                            final d = doc.data() as Map<String, dynamic>;
                            final kundRef = (d['kund_ref'] ?? '').toString();
                            if (kundRef != lastKundRef) {
                              lastKundRef = kundRef;
                              rows.add(Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                color: const Color(0xFFF0F4FF),
                                child: Text(
                                  kundRef.isEmpty ? '— ingen kund ref —' : 'Kund ref: $kundRef',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF185FA5), letterSpacing: 0.3),
                                ),
                              ));
                            }
                            final isLast = i == docs.length - 1;
                            rows.add(Column(children: [
                              InkWell(
                                onTap: () => widget.onSelected(doc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(children: [
                                    Expanded(flex: 3, child: Row(children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFFFFF3E0),
                                        child: Text(
                                          (d['merchant_site'] ?? '?').toString().isNotEmpty ? (d['merchant_site'] as String)[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE65100)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(child: Text(d['merchant_site'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                    ])),
                                    Expanded(flex: 3, child: Text(d['merchant_company'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)), overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(d['friendly_name'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                    Expanded(flex: 2, child: Text(d['serial_nr'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                    Expanded(flex: 2, child: Text(d['acquirer'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                                    Expanded(flex: 2, child: Row(children: [
                                      () {
                                        final max = d['inv_max_amount'];
                                        if (max == null) return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF888888)));
                                        final kundRef = (d['kund_ref'] ?? '').toString();
                                        final status = _invoiceStatus[kundRef];
                                        Widget dot;
                                        if (status == null) dot = const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5));
                                        else if (status == true) dot = const Icon(Icons.circle, size: 10, color: Color(0xFFD32F2F));
                                        else if (status == false) dot = const Icon(Icons.circle, size: 10, color: Color(0xFF388E3C));
                                        else dot = const SizedBox(width: 10);
                                        return Row(children: [
                                          dot,
                                          const SizedBox(width: 6),
                                          Text('$max kr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF185FA5))),
                                        ]);
                                      }(),
                                    ])),
                                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
                                  ]),
                                ),
                              ),
                              if (!isLast) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                            ]));
                          }
                          return rows;
                        }(),
                        if (_loading)
                          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        if (!_hasMore && _docs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Alla ${_docs.length} beställningar inladdade', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          ),
                      ]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4)),
  );
}

// ─── Prepare Order Detail ─────────────────────────────────────
class _PrepareOrderDetail extends StatefulWidget {
  final DocumentSnapshot doc;
  final VoidCallback onBack;
  const _PrepareOrderDetail({required this.doc, required this.onBack});
  @override
  State<_PrepareOrderDetail> createState() => _PrepareOrderDetailState();
}

class _PrepareOrderDetailState extends State<_PrepareOrderDetail> {
  late TextEditingController _maxAmountCtrl;
  bool _savingMax = false;

  @override
  void initState() {
    super.initState();
    final d = widget.doc.data() as Map<String, dynamic>;
    _maxAmountCtrl = TextEditingController(text: d['inv_max_amount']?.toString() ?? '');
  }

  @override
  void dispose() {
    _maxAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMaxAmount() async {
    final val = int.tryParse(_maxAmountCtrl.text.trim());
    if (val == null) return;
    setState(() => _savingMax = true);
    await widget.doc.reference.update({'inv_max_amount': val});
    if (mounted) setState(() => _savingMax = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Tillbaka till beställningar'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF185FA5), padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFF3E0),
            child: Text(
              (d['merchant_site'] ?? '?').toString().isNotEmpty ? (d['merchant_site'] as String)[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFFE65100)),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['merchant_site'] ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${d['merchant_company'] ?? '—'} · ${d['orgnr'] ?? '—'}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ]),
        ]),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _infoCard('Butiksinformation', [
            _infoRow('Butik', d['merchant_site']),
            _infoRow('Adress', d['merchant_site_adress']),
            _infoRow('Ort', d['merchant_site_ort']),
            _infoRow('Postnr', d['merchant_site_post_adress']),
            _infoRow('Telefon', d['merchant_site_phone']),
            _infoRow('Email', d['merchant_site_email']),
          ])),
          const SizedBox(width: 16),
          Expanded(child: _infoCard('Företagsinformation', [
            _infoRow('Företag', d['merchant_company']),
            _infoRow('Adress', d['merchant_company_adress']),
            _infoRow('Ort', d['merchant_company_ort']),
            _infoRow('Postnr', d['merchant_company_post_adress']),
            _infoRow('Org.nr', d['orgnr']),
            _infoRow('Merchant ID', d['merchant_id']),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _infoCard('Terminal', [
            _infoRow('Serienr', d['serial_nr']),
            _infoRow('DID', d['did']),
            _infoRow('Inlösare', d['acquirer']),
            _infoRow('Refset', d['refset']),
            _infoRow('Nets Baxi ID', d['Nets Baxi id']),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 110, child: Text('Max belopp', style: TextStyle(fontSize: 13, color: Color(0xFF888888)))),
              Expanded(child: SizedBox(height: 36, child: TextField(
                controller: _maxAmountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  suffixText: 'kr',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ))),
              const SizedBox(width: 8),
              SizedBox(height: 36, child: ElevatedButton(
                onPressed: _savingMax ? null : _saveMaxAmount,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF185FA5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14)),
                child: _savingMax ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Spara', style: TextStyle(fontSize: 13)),
              )),
            ]),
          ])),
          const SizedBox(width: 16),
          Expanded(child: _infoCard('Övrigt', [
            _infoRow('No', d['No']),
            _infoRow('Butiksnr', d['store_num']),
            _infoRow('Inkops nr', d['inkops_nr']),
            _infoRow('Kund ref', d['kund_ref']),
            _infoRow('Orderflag', d['orderflag']),
            _infoRow('Friendly name', d['friendly_name']),
          ])),
        ]),
        const SizedBox(height: 16),
        _PrepareOrderInvoicesSection(kundRef: d['kund_ref']?.toString() ?? ''),
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
}

// ─── Prepare Order Invoices Section ──────────────────────────
class _PrepareOrderInvoicesSection extends StatelessWidget {
  final String kundRef;
  const _PrepareOrderInvoicesSection({required this.kundRef});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fakturor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (kundRef.isEmpty)
          const Text('Ingen kund ref.', style: TextStyle(fontSize: 13, color: Color(0xFF888888)))
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('invoices1')
                .where('kundref', isEqualTo: kundRef)
                .orderBy('period', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Fel: ${snapshot.error}', style: const TextStyle(fontSize: 13, color: Color(0xFFA32D2D)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('Inga fakturor hittades.', style: TextStyle(fontSize: 13, color: Color(0xFF888888)));
              }
              return Column(children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text('FAKTURA', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4))),
                    Expanded(flex: 2, child: Text('PERIOD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4))),
                    Expanded(flex: 2, child: Text('SERIE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4))),
                    Expanded(flex: 2, child: Text('TOTALSUMMA', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.4))),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(d['faktura'] ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Expanded(flex: 2, child: Text(d['period'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                      Expanded(flex: 2, child: Text(d['serienr'] ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                      Expanded(flex: 2, child: Text('${d['totalsumma'] ?? '—'} ${d['valutakod'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF185FA5)))),
                    ]),
                  );
                }),
              ]);
            },
          ),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────
Widget _label(String text) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888), letterSpacing: 0.5));