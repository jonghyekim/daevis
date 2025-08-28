import 'package:flutter/material.dart';

class Notisetting extends StatefulWidget {
  const Notisetting({super.key});

  @override
  State<Notisetting> createState() => _NotisettingState();
}

class _NotisettingState extends State<Notisetting> {
  int _value = 0; // 0=키는거, 1=끄는거

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF0F0F0),
      appBar: AppBar(
        backgroundColor: Color(0xffF0F0F0),
        title: const Text(
          '알림 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 38, left: 38, bottom: 24, top: 115),
            child: Image.asset('assets/screen.png'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _value = 0),
                child: Row(
                  children: [_dot(_value == 0), const SizedBox(width: 8)],
                ),
              ),
              SizedBox(width: 160),
              GestureDetector(
                onTap: () => setState(() => _value = 1),
                child: Row(
                  children: [_dot(_value == 1), const SizedBox(width: 8)],
                ),
              ),
            ],
          ),
          SizedBox(height: 42),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Notisetting2()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Color(0xffFF6F66),
              foregroundColor: Colors.white,
              minimumSize: Size(100, 33),
              padding: EdgeInsets.symmetric(horizontal: 20),
              shape: StadiumBorder(),
              textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            child: Text('다음으로'),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool selected) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFFE6E6E6) : Colors.transparent,
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? const Color(0xffFF6F66) : const Color(0xFFD9D9D9),
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
      backgroundColor: Color(0xffF0F0F0),
      appBar: AppBar(
        backgroundColor: Color(0xffF0F0F0),
        title: const Text(
          '알림 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 109),
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 32,
                  right: 29,
                  left: 29,
                  bottom: 38,
                ),
                child: Column(
                  children: [
                    Image.asset('assets/noti/1.png', width: 271, height: 20),
                    SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (final m in _options1)
                          InkWell(
                            onTap: () => setState(() => _selected1 = m),
                            child: Container(
                              width: 53,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _selected1 == m
                                    ? Colors.black
                                    : const Color(0xffB9B9B9),
                                borderRadius: BorderRadius.circular(39),
                              ),
                              child: Center(
                                child: Text(
                                  '$m',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 32,
                  right: 29,
                  left: 29,
                  bottom: 38,
                ),
                child: Column(
                  children: [
                    Image.asset('assets/noti/2.png', width: 200, height: 20),
                    SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (final n in _options2)
                          InkWell(
                            onTap: () => setState(() => _selected2 = n),
                            child: Container(
                              width: 53,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _selected2 == n
                                    ? Colors.black
                                    : const Color(0xffB9B9B9),
                                borderRadius: BorderRadius.circular(39),
                              ),
                              child: Center(
                                child: Text(
                                  '$n',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 38),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xff949494),
                foregroundColor: Colors.white,
                minimumSize: Size(65, 38),
                shape: StadiumBorder(),
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              child: Text('완료'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 160, top: 18),
              child: SizedBox(
                height: 300,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Image.asset(
                      'assets/alarm.png',
                      width: 301,
                      height: 301,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
