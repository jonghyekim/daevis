// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화
// import 'package:firebase_auth/firebase_auth.dart'; // Firebase 인증
// import 'package:flutter/services.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Google 로그인 SDK

// import 'assignment.dart';
// import 'dday_list.dart';
// import 'done_list.dart';

// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   ); // Firebase 연결
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HomeScreen(),
//     );
//   }
// }

// // 첫 화면 (로그인 전 화면)
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // 1초 후 로그인 화면으로 이동
//     Future.delayed(const Duration(seconds: 1), () {
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F7F6),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,

//             // 그라데이션
//             colors: [Color(0xFFF8F7F6), Color(0xD7FFF2EE), Color(0x24FF6F4F)],
//             stops: [0.0, 0.85, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: const [
//               // 문구
//               Positioned(left: 24, top: 80, right: 24, child: _TitleBlock()),

//               // 알람 로고
//               Positioned(
//                 right: -30,
//                 bottom: 200,
//                 child: Image(
//                   image: AssetImage('assets/images/alarm.png'),
//                   width: 300,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // 첫화면 + 로그인 화면 문구 함수
// class _TitleBlock extends StatelessWidget {
//   const _TitleBlock();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: const [
//         Wrap(
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             Text(
//               '매번 까먹는 ',
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.black,
//                 height: 1.2,
//               ),
//             ),

//             // '과제' 텍스트에 그라데이션 함수 적용
//             GradientText('과제', fontSize: 32, fontWeight: FontWeight.w800),
//           ],
//         ),
//         SizedBox(height: 12),
//         Text(
//           '과제 알리미로 해결하세요',
//           textAlign: TextAlign.left,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w500,
//             height: 1.4,
//             color: Color(0xFF292929),
//           ),
//         ),
//       ],
//     );
//   }
// }

// /// 그라데이션 텍스트 함수
// class GradientText extends StatelessWidget {
//   const GradientText(
//     this.text, {
//     super.key,
//     this.fontSize = 32,
//     this.fontWeight = FontWeight.w800,
//   });

//   final String text;
//   final double fontSize;
//   final FontWeight fontWeight;

//   @override
//   Widget build(BuildContext context) {
//     const gradient = LinearGradient(
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//       colors: [Color(0xFFFF6969), Color(0xFFFF6432), Color(0xFFFFEA02)],
//       stops: [0.0, 0.58, 1.0],
//     );

//     return ShaderMask(
//       shaderCallback: (rect) => gradient.createShader(rect),
//       blendMode: BlendMode.srcIn,
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: fontSize,
//           fontWeight: fontWeight,
//           color: Colors.white,
//           height: 1.2,
//         ),
//       ),
//     );
//   }
// }

// // ---------------- 로그인 화면 ----------------
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   bool _busy = false;
//   String? _error;

//   Future<void> _signInGoogle() async {
//     setState(() {
//       _busy = true;
//       _error = null;
//     });
//     try {
//       final res = await Auth.signInWithGoogle();
//       if (res == null) {
//       } else if (mounted) {
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       setState(() => _error = '로그인 실패: $e');
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;

//     return Scaffold(
//       //------------------------------------------------------------------------------
//       floatingActionButton: Row(
//         mainAxisAlignment: MainAxisAlignment.end, // keep them on the right side
//         children: [
//           FloatingActionButton(
//             heroTag: "btn1", // must be unique
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const AssignmentPage()),
//               );
//             },
//             child: const Icon(Icons.add), // "+" icon
//           ),
//           const SizedBox(width: 16), // space between buttons
//           FloatingActionButton(
//             heroTag: "btn2", // must be unique
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const DdayListPage()),
//               );
//             },
//             child: const Icon(Icons.list),
//           ),
//           const SizedBox(width: 16), // space between buttons
//           FloatingActionButton(
//             heroTag: "btn3", // must be unique
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const DoneListPage()),
//               );
//             },
//             child: const Icon(Icons.check),
//           ),
//         ],
//       ),
//       //------------------------------------------------------------------------------
//       backgroundColor: const Color(0xFFF8F7F6),
//       body: Container(
//         constraints: const BoxConstraints.expand(),
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF8F7F6), Color(0xD7FFF2EE), Color(0x24FF6F4F)],
//             stops: [0.0, 0.85, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               const Positioned(
//                 left: 24,
//                 top: 80,
//                 right: 24,
//                 child: _TitleBlock(),
//               ),

//               Positioned(
//                 right: 30,
//                 bottom: 260,
//                 child: Image.asset(
//                   'assets/images/iphone_login.png',
//                   width: 350,
//                   fit: BoxFit.contain,
//                 ),
//               ),

//               Align(
//                 alignment: Alignment(0, 0.8),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints.tightFor(
//                     width: w > 420 ? 420 : w * 0.9,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (_error != null)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 12),
//                           child: Text(
//                             _error!,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       _LoginButton(
//                         label: '카카오로 시작하기',
//                         bg: const Color(0xFFFEE500),
//                         fg: const Color(0xFF191919),
//                         imagePath: "assets/images/kakaotalk_logo.png",
//                         widthImage: 24,
//                         heightImage: 24,
//                         onTap: () => ScaffoldMessenger.of(context),
//                       ),
//                       const SizedBox(height: 12),
//                       _LoginButton(
//                         label: '구글로 시작하기',
//                         bg: Colors.white,
//                         fg: Colors.black87,
//                         imagePath: "assets/images/google_logo.png",
//                         widthImage: 24,
//                         heightImage: 24,
//                         onTap: _busy ? null : _signInGoogle,
//                       ),
//                       const SizedBox(height: 12),
//                       _LoginButton(
//                         label: 'Apple로 시작하기',
//                         bg: Colors.black,
//                         fg: Colors.white,
//                         imagePath: "assets/images/apple_logo.png",
//                         widthImage: 24,
//                         heightImage: 24,
//                         onTap: () => ScaffoldMessenger.of(context),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LoginButton extends StatelessWidget {
//   const _LoginButton({
//     required this.label,
//     required this.bg,
//     required this.fg,
//     required this.imagePath,
//     required this.widthImage,
//     required this.heightImage,
//     this.onTap,
//   });

//   final String label;
//   final Color bg;
//   final Color fg;
//   final String imagePath;
//   final double widthImage;
//   final double heightImage;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 50,
//       width: 320,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Image.asset(imagePath, width: widthImage, height: heightImage),
//         label: Text(
//           label,
//           style: TextStyle(
//             color: fg,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: bg,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(22),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------------- Auth helper (Google) ----------------
// class Auth {
//   static Future<UserCredential?> signInWithGoogle() async {
//     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//     if (googleUser == null) return null;

//     final googleAuth = await googleUser.authentication;

//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     return FirebaseAuth.instance.signInWithCredential(credential);
//   }

//   static Future<void> signOut() async {
//     await GoogleSignIn().signOut();
//     await FirebaseAuth.instance.signOut();
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 인증만 필요
import 'package:google_sign_in/google_sign_in.dart'; // 구글 로그인

// ---------------- 스플래시(첫 화면) ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F7F6), Color(0xD7FFF2EE), Color(0x24FF6F4F)],
            stops: [0.0, 0.85, 1.0],
          ),
        ),
        child: const SafeArea(
          child: Stack(
            children: [
              Positioned(left: 24, top: 80, right: 24, child: _TitleBlock()),
              Positioned(
                right: -30,
                bottom: 200,
                child: Image(
                  image: AssetImage('assets/images/alarm.png'),
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 공통 타이틀 블럭 ----------------
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

// ---------------- 그라데이션 텍스트 ----------------
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
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}

// ---------------- 로그인 화면 ----------------
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
      if (res != null && mounted) {
        // ✅ 로그인 성공 → 홈으로 (스택 비우기)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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
      backgroundColor: const Color(0xFFF8F7F6),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F7F6), Color(0xD7FFF2EE), Color(0x24FF6F4F)],
            stops: [0.0, 0.85, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                left: 24,
                top: 80,
                right: 24,
                child: _TitleBlock(),
              ),
              Positioned(
                right: 30,
                bottom: 260,
                child: Image.asset(
                  'assets/images/iphone_login.png',
                  width: 350,
                  fit: BoxFit.contain,
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.8),
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: w > 420 ? 420 : w * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      _LoginButton(
                        label: '카카오로 시작하기',
                        bg: const Color(0xFFFEE500),
                        fg: const Color(0xFF191919),
                        imagePath: "assets/images/kakaotalk_logo.png",
                        widthImage: 24,
                        heightImage: 24,
                        onTap: () => ScaffoldMessenger.of(context),
                      ),
                      const SizedBox(height: 12),
                      _LoginButton(
                        label: '구글로 시작하기',
                        bg: Colors.white,
                        fg: Colors.black87,
                        imagePath: "assets/images/google_logo.png",
                        widthImage: 24,
                        heightImage: 24,
                        onTap: _busy ? null : _signInGoogle,
                      ),
                      const SizedBox(height: 12),
                      _LoginButton(
                        label: 'Apple로 시작하기',
                        bg: Colors.black,
                        fg: Colors.white,
                        imagePath: "assets/images/apple_logo.png",
                        widthImage: 24,
                        heightImage: 24,
                        onTap: () => ScaffoldMessenger.of(context),
                      ),
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
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.imagePath,
    required this.widthImage,
    required this.heightImage,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final String imagePath;
  final double widthImage;
  final double heightImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 320,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Image.asset(imagePath, width: widthImage, height: heightImage),
        label: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
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
