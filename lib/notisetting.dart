import 'package:flutter/material.dart';

const kBg = Color(0xFFF0F0F0); // single source of truth for bg
const kAccent = Color(0xFFFF6F66); // your coral
const kPillUnselected = Color(0xFFB9B9B9);

class Notisetting extends StatefulWidget {
  const Notisetting({super.key});
  @override
  State<Notisetting> createState() => _NotisettingState();
}

class _NotisettingState extends State<Notisetting> {
  int _value = 0; // 0 = on, 1 = off

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, // appbar == body
        elevation: 0, // flat like your design
        centerTitle: true,
        title: const Text(
          '알림 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // top image
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 64),
                child: Image.asset('assets/screen.png'),
              ),

              // on/off dots — evenly spaced without magic numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DotOption(
                    selected: _value == 0,
                    onTap: () => setState(() => _value = 0),
                  ),
                  _DotOption(
                    selected: _value == 1,
                    onTap: () => setState(() => _value = 1),
                  ),
                ],
              ),

              const SizedBox(height: 42),

              // next button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Notisetting2()),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 44),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('다음으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _DotOption({required this.selected, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    // the outer ring
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFFE6E6E6) : Colors.transparent,
        ),
        child: Center(
          // inner filled circle
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? kAccent : const Color(0xFFD9D9D9),
            ),
          ),
        ),
      ),
    );
  }
}

class Notisetting2 extends StatefulWidget {
  const Notisetting2({super.key});
  @override
  State<Notisetting2> createState() => _Notisetting2State();
}

class _Notisetting2State extends State<Notisetting2> {
  int _selected1 = 10;
  static const _options1 = [5, 10, 15, 30, 60];

  int _selected2 = 10;
  static const _options2 = [2, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, // appbar == body
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '알림 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // main content scrolls
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                children: [
                  _PickerCard(
                    titleImage: 'assets/noti/1.png',
                    children: _options1
                        .map(
                          (m) => _MinutePill(
                            label: '$m',
                            selected: _selected1 == m,
                            onTap: () => setState(() => _selected1 = m),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _PickerCard(
                    titleImage: 'assets/noti/2.png',
                    children: _options2
                        .map(
                          (n) => _MinutePill(
                            label: '$n',
                            selected: _selected2 == n,
                            onTap: () => setState(() => _selected2 = n),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF949494),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(92, 44),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('완료'),
                  ),
                ],
              ),
            ),

            // bottom decoration stays anchored bottom-right
            // Positioned(
            //   right: 0,
            //   bottom: 0,
            //   child: SizedBox(
            //     width: 220, // adjust if you want it bigger/smaller
            //     height: 220,
            //     child: Image.asset('assets/alarm.png', fit: BoxFit.contain),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/// Shared card for each question
class _PickerCard extends StatelessWidget {
  final String titleImage;
  final List<Widget> children;
  const _PickerCard({
    required this.titleImage,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          children: [
            Image.asset(titleImage, height: 20),
            const SizedBox(height: 22),
            Wrap(spacing: 10, runSpacing: 10, children: children),
          ],
        ),
      ),
    );
  }
}

/// Reusable “pill” (the number buttons)
class _MinutePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MinutePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(39),
      onTap: onTap,
      child: Container(
        width: 53,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? Colors.black : kPillUnselected,
          borderRadius: BorderRadius.circular(39),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
