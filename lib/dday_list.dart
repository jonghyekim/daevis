import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assignment.dart'; // AssignmentPage

class DdayListPage extends StatefulWidget {
  const DdayListPage({super.key});
  @override
  State<DdayListPage> createState() => DdayListPageState();
}

class DdayListPageState extends State<DdayListPage> {
  // 0=마감일순, 1=중요도순, 2=과목별 보기
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),

      body: Column(
        children: [
          const SizedBox(height: 12),

          // ---------------- 상단 버튼 3개 ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 100, 0, 10),
            child: Row(
              children: [
                // 마감일순
                GestureDetector(
                  onTap: () => setState(() => currentTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentTab == 0
                          ? const Color.fromARGB(255, 255, 52, 45)
                          : Colors.white,
                      border: Border.all(
                        color: currentTab == 0
                            ? Colors.white
                            : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '마감일순',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: currentTab == 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 중요도순
                GestureDetector(
                  onTap: () => setState(() => currentTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentTab == 1
                          ? const Color.fromARGB(255, 255, 52, 45)
                          : Colors.white,
                      border: Border.all(
                        color: currentTab == 1
                            ? Colors.white
                            : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '중요도순',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: currentTab == 1 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 과목별 보기
                GestureDetector(
                  onTap: () => setState(() => currentTab = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentTab == 2
                          ? const Color.fromARGB(255, 255, 52, 45)
                          : Colors.white,
                      border: Border.all(
                        color: currentTab == 2
                            ? Colors.white
                            : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '과목별 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: currentTab == 2 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ---------------- 목록 ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  // 전체를 가져오되, 화면에서 done==true는 제외(기본값 null/없음도 미완료로 간주)
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
                // 화면에서 done == true 는 제외
                final docs = raw
                    .where((d) {
                      final m = d.data() as Map<String, dynamic>;
                      return m['done'] != true;
                    })
                    .map((e) => e as QueryDocumentSnapshot)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('등록된 과제가 없어요'));
                }

                // 정렬
                if (currentTab == 0) {
                  // 마감일 오름차순
                  docs.sort((a, b) {
                    DateTime ad, bd;
                    try {
                      ad = DateTime.parse((a['due'] ?? '') as String);
                    } catch (_) {
                      ad = DateTime(9999);
                    }
                    try {
                      bd = DateTime.parse((b['due'] ?? '') as String);
                    } catch (_) {
                      bd = DateTime(9999);
                    }
                    return ad.compareTo(bd);
                  });
                } else if (currentTab == 1) {
                  // 중요도: 별 있는 항목 먼저, 별 개수 내림차순 (0개는 맨 뒤)
                  docs.sort((a, b) {
                    final aiOn = a['importanceOn'] == true;
                    final biOn = b['importanceOn'] == true;
                    final ai = aiOn ? (a['importance'] ?? 0) as int : 0;
                    final bi = biOn ? (b['importance'] ?? 0) as int : 0;
                    final aHas = ai > 0;
                    final bHas = bi > 0;
                    if (aHas != bHas) return bHas ? 1 : -1; // 별 있는 게 먼저
                    return bi.compareTo(ai);
                  });
                } else {
                  // 과목명 오름차순
                  docs.sort((a, b) {
                    final asub = (a['subject'] ?? '') as String;
                    final bsub = (b['subject'] ?? '') as String;
                    return asub.toLowerCase().compareTo(bsub.toLowerCase());
                  });
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

                    // D-day 계산 (마감일 기준) — 탭 0/2에서만 사용
                    String ddayText = '';
                    if (currentTab != 1) {
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
                    }

                    // 중요도 (별 개수)
                    final stars = (data['importanceOn'] == true)
                        ? (data['importance'] ?? 0) as int
                        : 0;

                    return Dismissible(
                      key: ValueKey(doc.id),

                      // 오른쪽으로 스와이프 -> 삭제
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

                      // 왼쪽으로 스와이프 -> 완료(초록)
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '완료',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check, color: Colors.white, size: 28),
                          ],
                        ),
                      ),

                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // 완료 처리 -> done: true
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .doc(doc.id)
                              .update({
                                'done': true,
                                'doneAt': FieldValue.serverTimestamp(),
                              });

                          // true를 반환하면 애니메이션으로 사라지고,
                          // 스트림 갱신 시 목록에서 빠집니다.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('완료로 이동했습니다')),
                          );
                          return true;
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

                        // 별 탭에 따라 레이아웃 분기
                        child: currentTab == 1
                            // 중요도순: D-day 없음
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(5, (i) {
                                            final filled = i < stars;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 2,
                                              ),
                                              child: Icon(
                                                filled
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                size: 18,
                                                color: filled
                                                    ? Colors.amber
                                                    : Colors.black26,
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 6),
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
                                          builder: (_) =>
                                              const AssignmentPage(),
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
                              )
                            // 마감일순/과목별 보기: 왼쪽 D-day + 가운데 텍스트
                            : Row(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          builder: (_) =>
                                              const AssignmentPage(),
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

      // 하단 FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignmentPage()),
              );
            },
            backgroundColor: const Color(0xFFFF6E51),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: () {
              // 자신 페이지로 이동은 유지(디자인 동일)
              // 보통은 여길 Done 화면으로 바꾸지만 원본 유지
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DdayListPage()),
              );
            },
            backgroundColor: Colors.black87,
            child: const Icon(Icons.list, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
