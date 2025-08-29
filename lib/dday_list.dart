import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assignment.dart'; // AssignmentPage (수정 화면)

// D-day 리스트 메인 페이지: 0=마감일순, 1=중요도순, 2=과목별 보기(이제 같은 화면 안에서 탭 전환)
class DdayListPage extends StatefulWidget {
  const DdayListPage({super.key});
  @override
  State<DdayListPage> createState() => DdayListPageState();
}

class DdayListPageState extends State<DdayListPage> {
  int currentTab = 0; // 0=마감일순, 1=중요도순, 2=과목별 보기

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ---------------- 상단 버튼 3개 ----------------
          // 말 그대로 "탭 버튼" 역할. 누르면 currentTab 값만 바꿔서 같은 화면에서 뷰 전환.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 75, 0, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => currentTab = 0),
                  child: _chip('마감일순', selected: currentTab == 0),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => currentTab = 1),
                  child: _chip('중요도순', selected: currentTab == 1),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => currentTab = 2),
                  child: _chip('과목별 보기', selected: currentTab == 2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ---------------- 본문 영역 ----------------
          // Firestore를 한 번만 구독하고, 탭에 따라 다른 위젯을 그린다.
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

                // 완료(done==true) 항목은 목록에서 제외 (일관성 유지)
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

                // 탭 2(과목별 보기)는 카드/그리드 기반이라 별도 렌더링
                if (currentTab == 2) {
                  return _buildSubjectView(context, docs);
                }

                // 나머지 탭(마감일/중요도)은 기존 리스트 스타일 유지
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
                } else {
                  // 중요도: 별 있는 항목 우선, 별 개수 내림차순
                  docs.sort((a, b) {
                    final aiOn = a['importanceOn'] == true;
                    final biOn = b['importanceOn'] == true;
                    final ai = aiOn ? (a['importance'] ?? 0) as int : 0;
                    final bi = biOn ? (b['importance'] ?? 0) as int : 0;
                    final aHas = ai > 0;
                    final bHas = bi > 0;
                    if (aHas != bHas) return bHas ? 1 : -1;
                    return bi.compareTo(ai);
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

                    // D-day 계산 (중요도순에서는 표시하지 않음)
                    String ddayText = '';
                    if (currentTab == 0) {
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

                    final stars = (data['importanceOn'] == true)
                        ? (data['importance'] ?? 0) as int
                        : 0;

                    // 개별 카드 (스와이프 삭제/완료 포함) - 탭 0,1 에서만 사용
                    return Dismissible(
                      key: ValueKey(doc.id),

                      // 오른쪽 스와이프 → 삭제
                      background: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      // 왼쪽 스와이프 → 완료
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // 완료 처리
                          await FirebaseFirestore.instance
                              .collection('assignments')
                              .doc(doc.id)
                              .update({
                                'done': true,
                                'doneAt': FieldValue.serverTimestamp(),
                              });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('완료로 이동했습니다')),
                          );
                          return true;
                        } else {
                          // 삭제 + 과목 정리
                          await _deleteAssignmentAndPruneSubject(
                            assignmentDocId: doc.id,
                            subjectName: (data['subject'] ?? '').toString(),
                          );
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

                        // 중요도순은 3줄(별/제목/내용)이기 때문에 최소 높이를 약간 여유 있게
                        constraints: currentTab == 1
                            ? const BoxConstraints(minHeight: 110)
                            : const BoxConstraints(minHeight: 100),

                        // 카드 안쪽 여백
                        padding: const EdgeInsets.all(16),

                        // 탭별 카드 레이아웃 분기
                        child: currentTab == 1
                            ? _importanceLayout(
                                context: context,
                                stars: stars,
                                title: title,
                                content: content,
                                onEdit: () => _openEdit(context, doc.id, data),
                              )
                            : _dueLayout(
                                ddayText: ddayText,
                                title: title,
                                content: content,
                                onEdit: () => _openEdit(context, doc.id, data),
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

  // ---------------- 중요도순 카드 레이아웃 ----------------
  // 별(1줄) + 제목(1줄) + 내용(1줄) = 총 3줄. 오버플로우 방지를 위해 글자/별 크기 약간 줄임.
  Widget _importanceLayout({
    required BuildContext context,
    required int stars,
    required String title,
    required String content,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // [LINE 1] 별 표시
              Row(
                children: List.generate(5, (i) {
                  final filled = i < stars;
                  return Padding(
                    padding: const EdgeInsets.only(right: 2), // 별 간격
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 22, // 살짝 줄여서 높이 여유 확보
                      color: filled ? Colors.amber : Colors.black26,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),

              // [LINE 2] 제목 (1줄)
              Text(
                title.isEmpty ? '(제목 없음)' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),

              // [LINE 3] 내용 (1줄)
              Text(
                content.isEmpty ? '내용 없음' : content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // 우측 점3개 아이콘 → 수정 화면으로 이동
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onPressed: onEdit,
          tooltip: '수정',
        ),
      ],
    );
  }

  // ---------------- 마감일순 카드 레이아웃 ----------------
  // 왼쪽에 D-day 고정폭 칼럼, 오른쪽에 제목/내용 2줄.
  Widget _dueLayout({
    required String ddayText,
    required String title,
    required String content,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100, // D-day 칼럼 폭(숫자 폭이 일정해 보이도록 고정)
          child: Center(
            child: Text(
              ddayText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
                fontFeatures: [FontFeature.tabularFigures()], // 탭형 숫자
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

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
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                content.isEmpty ? '내용 없음' : content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onPressed: onEdit,
          tooltip: '수정',
        ),
      ],
    );
  }

  // ---------------- 과목별 보기 ----------------
  // 같은 화면 안에서 섹션(과목 이름) + 2열 그리드 카드로 보여준다.
  Widget _buildSubjectView(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) {
    // 1) 도큐먼트를 간단한 모델로 변환 (필요한 필드만 뽑음)
    final items = docs
        .map((d) {
          final m = d.data() as Map<String, dynamic>;
          return _AssignmentLite(
            id: d.id,
            subject: (m['subject'] ?? '') as String,
            time24: (m['time24'] ?? '') as String,
            timeOn: (m['timeOn'] == true),
            subjectColor: m['subjectColor'] is int
                ? m['subjectColor'] as int
                : null,
          );
        })
        .where((a) => a.subject.trim().isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return const Center(child: Text('과목이 있는 항목이 없습니다.'));
    }

    // 2) 과목별로 그룹핑
    final Map<String, List<_AssignmentLite>> grouped = {};
    for (final a in items) {
      (grouped[a.subject] ??= <_AssignmentLite>[]).add(a);
    }

    // 3) 과목명 알파벳/가나다 순 정렬(대소문자 무시)
    final subjects = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // 4) 섹션 위젯 만들기
    final sectionWidgets = <Widget>[];
    for (final subject in subjects) {
      final list = grouped[subject]!;
      final color = (list.first.subjectColor != null)
          ? Color(list.first.subjectColor!)
          : const Color(0xffFF7638);

      sectionWidgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: _CollapsibleSection(
            label: subject,
            chipColor: color,
            child: _SubjectGrid(
              items: list,
              onEdit: (id) => _openEdit(context, id, null), // id만으로 수정 페이지 오픈
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: sectionWidgets,
    );
  }

  // 수정 화면으로 이동하는 헬퍼
  void _openEdit(
    BuildContext context,
    String docId,
    Map<String, dynamic>? data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AssignmentPage(),
        settings: RouteSettings(
          arguments: {'docId': docId, if (data != null) 'data': data},
        ),
      ),
    );
  }

  // 칩(탭 버튼) 공통 UI
  Widget _chip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color.fromARGB(255, 255, 52, 45) : Colors.white,
        border: Border.all(
          color: selected ? Colors.white : const Color(0xFFE0E0E0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // 삭제 후 해당 과목이 더 이상 쓰이지 않으면 subjects 컬렉션 정리
  Future<void> _deleteAssignmentAndPruneSubject({
    required String assignmentDocId,
    required String subjectName,
  }) async {
    final assignments = FirebaseFirestore.instance.collection('assignments');
    final subjects = FirebaseFirestore.instance.collection('subjects');

    await assignments.doc(assignmentDocId).delete();

    if (subjectName.isEmpty) return;

    final stillUsed = await assignments
        .where('subject', isEqualTo: subjectName)
        .limit(1)
        .get();
    if (stillUsed.docs.isNotEmpty) return;

    final dupSubjects = await subjects
        .where('name', isEqualTo: subjectName)
        .get();
    for (final doc in dupSubjects.docs) {
      await doc.reference.delete();
    }
  }
}

// 과목별 보기에서 쓰는 간단 모델 (필요한 필드만)
class _AssignmentLite {
  final String id;
  final String subject;
  final String time24;
  final bool timeOn;
  final int? subjectColor;

  _AssignmentLite({
    required this.id,
    required this.subject,
    required this.time24,
    required this.timeOn,
    required this.subjectColor,
  });
}

// 과목별 섹션(접기/펼치기)
class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.label,
    required this.child,
    this.chipColor,
  });

  final String label;
  final Widget child;
  final Color? chipColor;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = widget.chipColor ?? const Color(0xffFF7638);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 줄: 화살표 + 과목 칩
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          style: TextButton.styleFrom(
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Row(
            children: [
              Text(
                _expanded ? '▼' : '▶',
                style: TextStyle(fontSize: 20, color: color),
              ),
              const SizedBox(width: 6),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 펼쳐져 있을 때만 그리드 표시
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: widget.child,
          ),
      ],
    );
  }
}

// 과목별 보기 그리드(2열) + 카드
class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.items, required this.onEdit});

  final List<_AssignmentLite> items;
  final void Function(String id) onEdit;

  String _formatKoreanTime(String? time24) {
    if (time24 == null || time24.trim().isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (m == 0) ? '$h시' : '$h시 ${m}분';
    // ex) "17:00" -> "17시", "17:30" -> "17시 30분"
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    const columns = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final itemWidth = (maxW - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((a) {
            final hasTime = a.timeOn && a.time24.trim().isNotEmpty;
            final timeLabel = hasTime
                ? '과제 마감 ${_formatKoreanTime(a.time24)}까지'
                : '시간 미설정';

            return SizedBox(
              width: itemWidth,
              child: _RoutineCard(
                subject: a.subject,
                timeText: timeLabel,
                onEdit: () => onEdit(a.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.subject,
    required this.timeText,
    required this.onEdit,
  });

  final String subject;
  final String timeText;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      child: Padding(
        // 카드 안쪽 여백: left=14, top=22, right=8, bottom=22
        padding: const EdgeInsets.fromLTRB(14, 22, 8, 22),
        child: Row(
          children: [
            // 왼쪽: 텍스트 (과목 + 시간)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // 오른쪽: 점 3개 아이콘 → 수정 이동
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              onPressed: onEdit,
              tooltip: '수정',
            ),
          ],
        ),
      ),
    );
  }
}
