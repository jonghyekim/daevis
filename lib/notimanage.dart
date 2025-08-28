import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignmentModel {
  final String? id;
  final String? subject;
  final String? time24;
  final bool timeOn;
  final String? repeatCode;
  final bool repeatOn;
  final Timestamp? createdAt;

  AssignmentModel({
    required this.id,
    required this.subject,
    required this.time24,
    required this.timeOn,
    required this.repeatCode,
    required this.repeatOn,
    required this.createdAt,
  });

  factory AssignmentModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return AssignmentModel(
      id: doc.id,
      subject: data['subject'] as String?,
      time24: data['time24'] as String?,
      timeOn: (data['timeOn'] as bool?) ?? false,
      repeatCode: data['repeatCode'] as String?,
      repeatOn: (data['repeatOn'] as bool?) ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }
}

class Notimanage extends StatelessWidget {
  const Notimanage({super.key});

  static const Map<String, String> kRepeatLabelByCode = {
    'daily': '매일',
    'weekdays': '평일',
    'weekends': '주말',
    'weekly': '매주',
    'biweekly': '격주',
    'monthly': '매월',
    'yearly': '매년',
  };

  static const List<String> kRepeatOrder = [
    'daily',
    'weekdays',
    'weekends',
    'weekly',
    'biweekly',
    'monthly',
    'yearly',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xffF0F0F0),
        title: Text(
          '반복 알림 관리',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // repeatOn == true 인 항목만
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('repeatOn', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs
              .map((d) => AssignmentModel.fromDoc(d))
              .where(
                (a) =>
                    a.repeatCode != null &&
                    kRepeatLabelByCode.containsKey(a.repeatCode!),
              )
              .toList();

          // repeatCode별 그룹핑
          final Map<String, List<AssignmentModel>> grouped = {
            for (final code in kRepeatOrder) code: <AssignmentModel>[],
          };
          for (final a in docs) {
            grouped[a.repeatCode!]!.add(a);
          }

          final hasAny = grouped.values.any((list) => list.isNotEmpty);
          if (!hasAny) {
            return const Center(child: Text('설정된 반복 알림이 없습니다.'));
          }

          // 섹션 UI 생성
          final List<Widget> sections = [];
          for (final code in kRepeatOrder) {
            final list = grouped[code]!;
            if (list.isEmpty) continue;

            sections.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: RoutineHeader(label: kRepeatLabelByCode[code]!),
              ),
            );

            sections.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: _SectionGrid(items: list),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: sections,
          );
        },
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.items});
  final List<AssignmentModel> items;

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
    const spacing = 12.0; // 카드 간격
    const columns = 2; // 2열
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
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class RoutineHeader extends StatelessWidget {
  const RoutineHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/tri.png', width: 14, height: 14),
        const SizedBox(width: 7),
        Container(
          height: 21,
          width: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Color(0xffFF7638),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: FittedBox(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RoutineCard extends StatelessWidget {
  const RoutineCard({super.key, required this.subject, required this.timeText});

  final String subject;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 8, 22),
        child: Row(
          children: [
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
            const Icon(Icons.more_vert, color: Color(0xffD9D9D9), size: 20),
          ],
        ),
      ),
    );
  }
}
