import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assignment.dart';
import 'dday_list.dart';

class DoneListPage extends StatefulWidget {
  const DoneListPage({super.key});
  @override
  State<DoneListPage> createState() => DoneListPageState();
}

class DoneListPageState extends State<DoneListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          255,
          235,
          235,
          235,
        ), // background color
        elevation: 0, // remove shadow
        leading: IconButton(
          // back arrow
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "완료한 알림",
          style: TextStyle(
            fontSize: 18, // 🔹 font size (adjust here)
            fontWeight: FontWeight.w600, // 🔹 font weight (medium-bold)
            color: Colors.black, // 🔹 text color
          ),
        ),
        centerTitle: false, // left-align the title (since design shows that)
      ),

      body: Column(
        children: [
          const SizedBox(height: 12), // 상단 여백 (탭 없어서 살짝 띄움)
          // ---------------- 목록 (탭 없음, 디자인 동일) ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(child: Text('불러오기 실패'));
                }

                final raw = snap.data?.docs ?? [];
                // done == true 만 표시
                final docs = raw
                    .where((d) {
                      final m = d.data() as Map<String, dynamic>;
                      return m['done'] == true;
                    })
                    .map((e) => e as QueryDocumentSnapshot)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('완료된 과제가 없어요'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = (data['todoTitle'] ?? '') as String;
                    final content = (data['note'] ?? '') as String;

                    // D-day (완료 목록에서도 동일하게 표시)
                    String ddayText = '';
                    DateTime dueDate;
                    try {
                      final s = (data['due'] ?? '') as String;
                      final p = DateTime.parse(s);
                      dueDate = DateTime(p.year, p.month, p.day);
                    } catch (_) {
                      dueDate = DateTime(9999);
                    }
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final d = dueDate.difference(today).inDays;
                    if (d == 0) {
                      ddayText = 'D-day';
                    } else if (d > 0) {
                      ddayText = 'D-$d';
                    } else {
                      ddayText = 'D+${d.abs()}';
                    }

                    return Dismissible(
                      key: ValueKey(doc.id),

                      // 오른쪽으로 스와이프 -> 삭제 (dday_list와 동일)
                      background: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 왼쪽으로 스와이프 -> 되돌리기(파란색 + refresh)
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF), // iOS 파란색 느낌
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(width: 8),
                            Icon(Icons.refresh, color: Colors.white, size: 28),
                          ],
                        ),
                      ),

                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // 되돌리기 -> done: false
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .doc(doc.id)
                              .update({'done': false, 'doneAt': null});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('할 일 목록으로 이동했습니다')),
                          );
                          return true; // 애니메이션으로 사라지고, 스트림 갱신 시 목록에서 빠짐
                        } else {
                          // 삭제
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .doc(doc.id)
                              .delete();
                          return true;
                        }
                      },

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),

                        // dday_list의 기본(마감일/과목별) 카드 레이아웃을 그대로
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 96,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: Text(
                                  ddayText,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? '(제목 없음)' : title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  Text(
                                    content.isEmpty ? '내용 없음' : content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF5F5F5F),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AssignmentPage(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'docId': doc.id,
                                        'data': data,
                                      },
                                    ),
                                  ),
                                );
                              },
                              tooltip: '수정',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
