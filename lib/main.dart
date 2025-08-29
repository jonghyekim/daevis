import 'assignment.dart';
import 'calendar.dart';
import 'mypage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'dday_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // 0: LeftPage, 1: CalendarPage, 2: MyPage
  final _calendarKey = GlobalKey<CalendarPageState>();

  String _providerLabel(String? id) {
    switch (id) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'password':
        return 'Email';
      default:
        return id ?? 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final useNotch = _index == 1;

    // FirebaseAuth 현재 사용자 정보 읽기
    final u = FirebaseAuth.instance.currentUser;

    final String name = (u?.displayName != null && u!.displayName!.isNotEmpty)
        ? u.displayName!
        : ((u?.providerData.isNotEmpty ?? false) &&
              u!.providerData.first.displayName != null &&
              u.providerData.first.displayName!.isNotEmpty)
        ? u.providerData.first.displayName!
        : (u?.email?.split('@').first ?? '이름 없음');

    final String email = u?.email ?? '';

    final String account = _providerLabel(
      (u?.providerData.isNotEmpty ?? false)
          ? u!.providerData.first.providerId
          : 'unknown',
    );

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const DdayListPage(),
          CalendarPage(key: _calendarKey),
          // 프로필 탭에 로그인 사용자 정보 전달
          MyPage(name: name, email: email, account: account),
        ],
      ),
      floatingActionButton: useNotch
          ? FloatingActionButton(
              onPressed: () async {
                final res = await Navigator.of(context)
                    .push<Map<String, dynamic>>(
                      MaterialPageRoute(builder: (_) => const AssignmentPage()),
                    );
                if (res != null) {
                  setState(() => _index = 1);
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Image.asset(
                'assets/bottom/plus.png',
                width: 60,
                height: 60,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomAppBar(
          shape: null,
          color: Colors.white,
          child: SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _index = 0),
                  child: Image.asset(
                    _index == 0
                        ? 'assets/bottom/bell_f.png'
                        : 'assets/bottom/bell_e.png',
                    width: 22,
                    height: 22,
                  ),
                ),
                useNotch
                    ? const SizedBox(width: 50)
                    : Padding(
                        padding: const EdgeInsets.only(right: 17, left: 17),
                        child: GestureDetector(
                          onTap: () => setState(() => _index = 1),
                          child: Image.asset(
                            'assets/bottom/home.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                GestureDetector(
                  onTap: () => setState(() => _index = 2),
                  child: Image.asset(
                    _index == 2
                        ? 'assets/bottom/profile_f.png'
                        : 'assets/bottom/profile_e.png',
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
