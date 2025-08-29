import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'assignment.dart'; // for editing

// ---------- Data Model ----------
class AssignmentModel {
  final String? id;
  final String? subject;
  final String? time24;
  final bool timeOn;
  final Timestamp? createdAt;
  final int? subjectColor;

  AssignmentModel({
    required this.id,
    required this.subject,
    required this.time24,
    required this.timeOn,
    required this.createdAt,
    required this.subjectColor,
  });

  factory AssignmentModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return AssignmentModel(
      id: doc.id,
      subject: data['subject'] as String?,
      time24: data['time24'] as String?,
      timeOn: (data['timeOn'] as bool?) ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      subjectColor: data['subjectColor'] as int?,
    );
  }
}

// ---------- Subject View Page ----------
class New extends StatelessWidget {
  const New({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F0F0),

      // AppBar 제거하고, DdayListPage의 “상단 버튼 3개”를 그대로 사용
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ---------------- 상단 버튼 3개 ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 75, 0, 10),
            child: Row(
              children: [
                // 마감일순 -> 이전 페이지로 돌아가기
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: _chip('마감일순', selected: false),
                ),
                const SizedBox(width: 8),

                // 중요도순 -> 이전 페이지로 돌아가기
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: _chip('중요도순', selected: false),
                ),
                const SizedBox(width: 8),

                // 과목별 보기(현재 페이지) - 선택 상태 표시
                _chip('과목별 보기', selected: true),
              ],
            ),
          ),

          // ---------------- 본문 ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs
                    .map((d) => AssignmentModel.fromDoc(d))
                    .where((a) => (a.subject ?? '').trim().isNotEmpty)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('과목이 있는 항목이 없습니다.'));
                }

                // subject별 그룹핑
                final Map<String, List<AssignmentModel>> groupedBySubject = {};
                for (final a in docs) {
                  final key = a.subject!.trim();
                  (groupedBySubject[key] ??= <AssignmentModel>[]).add(a);
                }

                // 과목명 정렬
                final subjects = groupedBySubject.keys.toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                // 섹션 생성
                final List<Widget> sections = [];
                for (final subjectName in subjects) {
                  final list = groupedBySubject[subjectName]!;
                  if (list.isEmpty) continue;

                  final Color chipColor = (list.first.subjectColor != null)
                      ? Color(list.first.subjectColor!)
                      : const Color(0xffFF7638);

                  sections.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: CollapsibleSection(
                        key: ValueKey('sub:$subjectName'),
                        label: subjectName,
                        items: list,
                        chipColor: chipColor,
                        // 수정 이동 콜백
                        onEdit: (assignmentId) {
                          if (assignmentId == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssignmentPage(),
                              settings: RouteSettings(
                                arguments: {'docId': assignmentId},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: sections,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // DdayListPage에서 쓰던 칩 UI 그대로
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
}

// ---------- Grid ----------
class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.items, required this.onEdit});

  final List<AssignmentModel> items;
  final void Function(String? assignmentId) onEdit;

  String _formatKoreanTime(String? time24) {
    if (time24 == null || time24.trim().isEmpty) return '';
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (m == 0) ? '$h시' : '$h시 ${m}분';
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
            final hasTime =
                a.timeOn && (a.time24 != null && a.time24!.trim().isNotEmpty);
            final timeLabel = hasTime
                ? '과제 마감 ${_formatKoreanTime(a.time24)}까지'
                : '시간 미설정';

            return SizedBox(
              width: itemWidth,
              child: RoutineCard(
                subject: a.subject ?? '제목 없음',
                timeText: timeLabel,
                // 수정 버튼 콜백
                onEdit: () => onEdit(a.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------- Card ----------
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.subject,
    required this.timeText,
    required this.onEdit,
  });

  final String subject; // 과목 이름
  final String timeText; // 시간 표시 (예: "과제 마감 5시까지")
  final VoidCallback onEdit; // 수정 버튼 눌렀을 때 실행할 함수

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // 카드 배경은 흰색
      elevation: 0, // 그림자 없음
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19), // 모서리를 둥글게
      ),

      // Padding은 '카드 안쪽 여백'을 지정하는 위젯
      child: Padding(
        // left=14, top=22, right=8, bottom=22만큼 안쪽으로 띄워줌
        padding: const EdgeInsets.fromLTRB(14, 22, 8, 22),

        // 안쪽에 Row를 넣어서 → [텍스트들 | 수정버튼] 이런 레이아웃을 만듦
        child: Row(
          children: [
            // 왼쪽은 텍스트 영역 (과목 + 시간)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                children: [
                  // 과목명
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1, // 한 줄만 표시
                    overflow: TextOverflow.ellipsis, // 길면 ... 처리
                  ),

                  const SizedBox(height: 2), // 과목과 시간 사이 간격
                  // 시간 텍스트
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

            const SizedBox(width: 6), // 오른쪽 아이콘과 간격
            // 오른쪽 점 3개 아이콘 (수정 버튼)
            IconButton(
              icon: const Icon(
                Icons.more_vert, // 점 3개 아이콘
                color: Color(0xffD9D9D9),
                size: 20,
              ),
              onPressed: onEdit, // 눌렀을 때 실행할 콜백
              tooltip: '수정', // 길게 누르면 뜨는 설명
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Collapsible Section ----------
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.label,
    required this.items,
    required this.onEdit,
    this.chipColor,
  });

  final String label;
  final List<AssignmentModel> items;
  final void Function(String? assignmentId) onEdit;
  final Color? chipColor;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final Color chipColor = widget.chipColor ?? const Color(0xffFF7638);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text('▼', style: TextStyle(fontSize: 20, color: chipColor)),
              const SizedBox(width: 6),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
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
        _expanded
            ? Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _SectionGrid(
                  items: widget.items,
                  onEdit: widget.onEdit, // 전달
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
