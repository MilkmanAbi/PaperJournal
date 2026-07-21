import 'package:flutter/material.dart';
import '../global.dart';
import '../services/firebase_service.dart';

// LoginPage - industrial flat UI, no gradients, no soft bubbles.
// tight grid, small icons, monospace-ish labels, harsh not cozy.
// Two tabs: SIGN IN and CREATE ACCOUNT
// "remember me" skips login on next cold start by extending session to 30 days
// firebase auth does the real check now
// admin@example.com logs in through firebase auth like everyone else now
// DO NOT FUCKING TOUCH THE HARDCODED ADMIN SHORTCUT BELOW - it got removed because
// bypassing FB.signIn() means firestore never gets an auth token and everything
// permission-denies. i fucked something up, it's complicated, leave it pls ; AAS
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecor(String label, IconData icon, {bool isDark = false}) {
    final inkMuted = isDark ? const Color(0xFF6C7387) : const Color(0xFF98A0AF);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, letterSpacing: 0.8, color: inkMuted),
      prefixIcon: Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        borderSide: BorderSide(width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        borderSide: BorderSide(color: Color(0xFF3D6FE0), width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        borderSide: BorderSide(color: Color(0xFFD9564F), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF10131C) : const Color(0xFFF4F5F7);
    final surface = isDark ? const Color(0xFF1A1F2C) : const Color(0xFFFFFFFF);
    final ink = isDark ? const Color(0xFFEDEFF5) : const Color(0xFF141924);
    final inkMuted = isDark ? const Color(0xFF6C7387) : const Color(0xFF98A0AF);
    const accent = Color(0xFF3D6FE0);
    final borderColor = isDark ? const Color(0xFF2A3040) : const Color(0xFFDDE0E8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // wordmark
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.book, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('PAPERJOURNAL', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      letterSpacing: 2.5, color: ink,
                    )),
                  ],
                ),

                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      // tab bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5),
                          indicatorColor: accent,
                          labelColor: accent,
                          unselectedLabelColor: inkMuted,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'SIGN IN'),
                            Tab(text: 'CREATE ACCOUNT'),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 380,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _SignInForm(fieldDecor: _fieldDecor, isDark: isDark),
                            _SignUpForm(fieldDecor: _fieldDecor, isDark: isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text('MAD Assessment, Filler; AAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: inkMuted.withValues(alpha: 0.5), letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('ET0529 Mobile Applications Development  /  SP EEE  /  2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: inkMuted.withValues(alpha: 0.4), letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SIGN IN FORM ─────────────────────────────────────────────────────────────

class _SignInForm extends StatefulWidget {
  final InputDecoration Function(String, IconData, {bool isDark}) fieldDecor;
  final bool isDark;
  const _SignInForm({required this.fieldDecor, required this.isDark});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // EVERYTHING goes through FB.signIn() now - no more hardcoded bypass.
    // the old shortcut skipped firebase auth entirely which meant firestore
    // never got a token and permission-denied'd every admin query. ; AAS
    Global.rememberMe = _rememberMe;
    final err = await FB.signIn(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final ink = isDark ? const Color(0xFFEDEFF5) : const Color(0xFF141924);
    final inkMuted = isDark ? const Color(0xFF6C7387) : const Color(0xFF98A0AF);
    const accent = Color(0xFF3D6FE0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('EMAIL ADDRESS', Icons.alternate_email, isDark: isDark),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('PASSWORD', Icons.lock_outline, isDark: isDark).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),

            const SizedBox(height: 14),

            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
                      side: BorderSide(color: inkMuted, width: 1),
                      activeColor: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember me', style: TextStyle(fontSize: 12, color: inkMuted)),
                  const SizedBox(width: 4),
                  Text('(30 days)', style: TextStyle(fontSize: 11, color: inkMuted.withValues(alpha: 0.5))),
                ],
              ),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9E1DF),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFD9564F).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Color(0xFFD9564F)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B241E)))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('SIGN IN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIGN UP FORM ─────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  final InputDecoration Function(String, IconData, {bool isDark}) fieldDecor;
  final bool isDark;
  const _SignUpForm({required this.fieldDecor, required this.isDark});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final err = await FB.signUp(email, password, name);

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final ink = isDark ? const Color(0xFFEDEFF5) : const Color(0xFF141924);
    const accent = Color(0xFF3D6FE0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              keyboardType: TextInputType.name,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('DISPLAY NAME', Icons.badge_outlined, isDark: isDark),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('EMAIL ADDRESS', Icons.alternate_email, isDark: isDark),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('PASSWORD', Icons.lock_outline, isDark: isDark).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              style: TextStyle(fontSize: 13, color: ink),
              decoration: widget.fieldDecor('CONFIRM PASSWORD', Icons.lock_outline, isDark: isDark).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9E1DF),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFD9564F).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Color(0xFFD9564F)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B241E)))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CREATE ACCOUNT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
