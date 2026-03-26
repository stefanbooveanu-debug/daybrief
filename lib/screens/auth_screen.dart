import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isSignUp) {
      success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _surnameController.text.trim(),
      );
    } else {
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      // Auth provider will handle navigation via Consumer in main.dart
    } else if (!success && mounted) {
      // Show error from provider
      final error = authProvider.error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: isWide ? _buildWideLayout(isDark) : _buildNarrowLayout(isDark),
    );
  }

  Widget _buildWideLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildLeftPanel(isDark),
        ),
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildFormPanel(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildCompactHeader(isDark),
            _buildFormPanel(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'DayBrief',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(bool isDark) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(48),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Text('DayBrief', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
              ],
            ),
            const SizedBox(height: 48),
            _buildIllustration(),
            const SizedBox(height: 40),
            const Text('Organize your life with ease', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Color(0xFF202124), height: 1.2)),
            const SizedBox(height: 14),
            const Text('Manage your schedule with voice commands, smart categories, and beautiful views.', style: TextStyle(fontSize: 16, color: Color(0xFF5F6368), height: 1.5)),
            const SizedBox(height: 36),
            _buildFeatureGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F'].map((d) => Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)))).toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEventBar(const Color(0xFF1A73E8), 0.6),
                      _buildEventBar(const Color(0xFF34A853), 0.8),
                      _buildEventBar(const Color(0xFFEA4335), 0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventBar(Color color, double height) {
    return Container(width: 24, height: 50 * height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)));
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.mic, 'title': 'Voice', 'desc': 'Add events by voice'},
      {'icon': Icons.view_week, 'title': 'Views', 'desc': 'Day, week, month'},
      {'icon': Icons.notifications, 'title': 'Reminders', 'desc': 'Never miss events'},
      {'icon': Icons.palette, 'title': 'Custom', 'desc': 'Your colors'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.4),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
                child: Icon(f['icon'] as IconData, color: const Color(0xFF1A73E8), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(f['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF202124))),
                    Text(f['desc'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormPanel(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isSignUp ? 'Create account' : 'Welcome back', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
              const SizedBox(height: 8),
              Text(_isSignUp ? 'Start organizing your day' : 'Sign in to continue', style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp)
                      Row(
                        children: [
                          Expanded(child: _buildField(_nameController, 'First name', Icons.person_outline)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildField(_surnameController, 'Last name', Icons.person_outline)),
                        ],
                      ),
                    if (_isSignUp) const SizedBox(height: 14),
                    _buildField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _buildField(_passwordController, 'Password', Icons.lock_outlined, obscure: _obscurePassword, suffix: _buildToggle(() => setState(() => _obscurePassword = !_obscurePassword), _obscurePassword)),
                    if (_isSignUp) ...[
                      const SizedBox(height: 14),
                      _buildField(_confirmPasswordController, 'Confirm password', Icons.lock_outlined, obscure: _obscureConfirmPassword, suffix: _buildToggle(() => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), _obscureConfirmPassword)),
                    ],
                    if (!_isSignUp) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: const Color(0xFF1A73E8),
                          ),
                          const Text('Remember me', style: TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot password?', style: TextStyle(fontSize: 13, color: Color(0xFF1A73E8))),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(_isSignUp ? 'Create account' : 'Sign in', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSignUp ? 'Already have an account?' : "Don't have an account?", style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                    TextButton(
                      onPressed: () { _animationController.reset(); _animationController.forward(); setState(() => _isSignUp = !_isSignUp); context.read<AuthProvider>().clearError(); },
                      child: Text(_isSignUp ? 'Sign in' : 'Sign up', style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(VoidCallback onTap, bool isVisible) {
    return GestureDetector(onTap: onTap, child: Icon(isVisible ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF5F6368), size: 20));
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF5F6368), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF5F6368), size: 19),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (label == 'Email' && !v.contains('@')) return 'Invalid email';
        if (label == 'Password' && v.length < 6) return 'At least 6 characters';
        if (label == 'Confirm password' && v != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }
}
