import 'myprofile.dart';
import 'new.dart';
import 'notimanage.dart';
import 'notisetting.dart';
import 'package:flutter/material.dart';
import 'done_list.dart';

class MyPage extends StatelessWidget {
  const MyPage({
    super.key,
    required this.name,
    required this.account,
    required this.email,
  });

  final String name;
  final String account;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F0F0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 80, left: 32, bottom: 7),
            child: Row(
              children: [
                Image.asset('assets/nice.png', width: 116, height: 36),
                Text(
                  '$name님',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12, left: 32),
            child: Image.asset('assets/cheerup.png', width: 208, height: 24),
          ),
          Padding(
            padding: EdgeInsets.only(top: 14, left: 32, right: 32),
            child: Row(
              children: [
                Expanded(
                  child: MyPageCard(
                    image: 'assets/myprofile/account.png',
                    text1: '내 정보',
                    text2: '계정 연동 안내',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyProfile(
                            name: name,
                            account: account,
                            email: email,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: MyPageCard(
                    image: 'assets/myprofile/alarm1.png',
                    text1: '완료한 알림',
                    text2: '완료한 알림 보기',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DoneListPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 14, left: 32, right: 32),
            child: MyPageCard(
              image: 'assets/myprofile/alarm2.png',
              text1: '알림 설정',
              text2: '표시 방식 / 알림 관리',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Notisetting()),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 14, left: 32, right: 32),
            child: MyPageCard(
              image: 'assets/myprofile/alarm3.png',
              text1: '반복 알림 관리',
              text2: '반복 설정된 알림 보기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Notimanage()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 18),
            child: SizedBox(
              height: 330,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Image.asset(
                    'assets/alarm.png',
                    width: 383,
                    height: 383,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyPageCard extends StatelessWidget {
  const MyPageCard({
    super.key,
    required this.text1,
    required this.text2,
    required this.image,
    this.onPressed,
  });

  final String text1;
  final String text2;
  final String image;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 7, right: 14),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(top: 18, left: 18, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(image, width: 20, height: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text1,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Text(text2),
            ],
          ),
        ),
      ),
    );
  }
}
