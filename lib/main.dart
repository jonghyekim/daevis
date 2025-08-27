import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'assignment.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),


      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssignmentPage()),
          );
        },
        child: const Icon(Icons.add), // the "+" icon
      ),


      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // smooth dissolve to the bottom
            colors: [Color(0xFFF8F7F6), Color(0xD7FFF2EE), Color(0x24FF6F4F)],
            stops: [0.0, 0.85, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // -------- Top-left text block (UNCHANGED) --------
              const Positioned(
                left: 24,
                top: 80,
                right: 24,
                child: _TitleBlock(),
              ),


              // -------- Bottom-right alarm PNG (tap → Login) --------
              Positioned(
                right: -30,
                bottom: 200,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Image.asset(
                    'assets/images/alarm.png',
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // --- Optional: show who is logged in (small pill) ---
              Positioned(
                left: 24,
                bottom: 24,
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snap) {
                    final user = snap.data;
                    if (user == null) return const SizedBox.shrink();
                    final label = user.displayName ?? user.email ?? '로그인됨';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Auth.signOut(),
                            child: const Text('로그아웃'),
                          ),

                        ],
                      ),

                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Title (kept exactly like your design) ----------------
class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '매번 까먹는 ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            GradientText('과제', fontSize: 32, fontWeight: FontWeight.w800),
          ],
        ),
        SizedBox(height: 12),
        Text(
          '과제 알리미로 해결하세요',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: Color(0xFF292929),
          ),
        ),
      ],
    );
  }
}

/// Gradient text widget used for "과제"  (UNCHANGED)
class GradientText extends StatelessWidget {
  const GradientText(
      this.text, {
        super.key,
        this.fontSize = 32,
        this.fontWeight = FontWeight.w800,
      });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6969), Color(0xFFFF6432), Color(0xFFFFEA02)],
      stops: [0.0, 0.58, 1.0],
    );

    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white, // replaced by gradient
          height: 1.2,
        ),
      ),
    );
  }
}

// ---------------- Login Screen ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signInGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await Auth.signInWithGoogle();
      if (res == null) {
        setState(() => _error = 'Google 로그인 취소됨');
      } else if (mounted) {
        Navigator.pop(context); // back to Home
      }
    } catch (e) {
      setState(() => _error = '로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      backgroundColor: const Color(0xFFF8F7F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: w > 420 ? 420 : w * 0.9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('로그인',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              _LoginButton(
                label: '카카오로 시작하기',
                bg: const Color(0xFFFEE500),
                fg: const Color(0xFF191919),
                icon: Icons.chat_bubble_outline,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kakao 로그인')),
                ),
              ),
              const SizedBox(height: 12),
              _LoginButton(
                label: '구글로 시작하기',
                bg: Colors.white,
                fg: Colors.black87,
                icon: Icons.g_mobiledata_rounded,
                onTap: _busy ? null : _signInGoogle,
              ),
              const SizedBox(height: 12),
              _LoginButton(
                label: 'Apple로 시작하기',
                bg: Colors.black,
                fg: Colors.white,
                icon: Icons.apple,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apple 로그인')),
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: fg),
        label: Text(label,
            style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ---------------- Auth helper (Google) ----------------
class Auth {
  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
