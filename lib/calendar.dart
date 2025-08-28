import 'dart:math';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assignment.dart';

class TaskItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color listcolor;
  final bool done;
  final String subject;

  TaskItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.listcolor,
    required this.done,
    required this.subject,
  });
}

class DaySegment {
  final TaskItem task;
  final bool isStart;
  final bool isEnd;
  DaySegment(this.task, {required this.isStart, required this.isEnd});
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  final DateTime _kToday = DateTime.now();
  late DateTime _focusedDay;
  final DateFormat _enMonth = DateFormat('MMMM yyyy', 'en_US');

  DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _focusedDay = _kToday;
  }

  //체크박스
  Future<void> _toggleDone(String docId, bool value) async {
    await FirebaseFirestore.instance
        .collection('assignments')
        .doc(docId)
        .update({'done': value});
  }

  //디데이
  String _dday(DateTime end) {
    final today = _d(DateTime.now());
    final diff = _d(end).difference(today).inDays;
    if (diff == 0) return 'D-day';
    return diff > 0 ? 'D-$diff' : 'D+${-diff}';
  }

  //Firestore에서 가져오기
  TaskItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();

    final String title = (m['todoTitle'] as String?)?.trim().isNotEmpty == true
        ? m['todoTitle'].trim()
        : '(제목 없음)';

    final bool dateOn = (m['dateOn'] as bool?) ?? false;
    final DateTime start = (dateOn && m['date'] != null)
        ? DateTime.parse(m['date'])
        : _d(_kToday);

    final bool dueOn = (m['dueOn'] as bool?) ?? false;
    final DateTime end = (dueOn && m['due'] != null)
        ? DateTime.parse(m['due'])
        : start;

    final String subjectName =
        (m['subtitle'] as String?)?.trim().isNotEmpty == true
        ? (m['subtitle'] as String).trim()
        : ((m['subject'] as String?) ?? '').trim();

    //색깔
    final int colorInt =
        (m['subjectColor'] as int?) ??
        (m['subtitleColor'] as int?) ??
        (m['listcolor'] as int?) ??
        0xFF34C85A;

    return TaskItem(
      id: doc.id,
      title: title,
      start: _d(start),
      end: _d(end),
      listcolor: Color(colorInt),
      done: (m['done'] as bool?) ?? false,
      subject: subjectName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F0F0),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('불러오는 중 오류가 발생했습니다.'));
          }

          final docs = snap.data?.docs ?? [];
          final List<TaskItem> tasks = docs.map(_fromDoc).toList();
          final Map<int, List<TaskItem>> byColor = {};
          for (final t in tasks) {
            (byColor[t.listcolor.value] ??= []).add(t);
          }

          final sections = byColor.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          String labelFor(List<TaskItem> items) =>
              items.isNotEmpty ? items.first.subject : '';

          //dateOn에 불 들어오면 표시
          final Map<DateTime, List<DaySegment>> segmentsByDay = {};
          for (final t in tasks) {
            final bool hasRealDate =
                (docs.firstWhere((d) => d.id == t.id).data()['dateOn'] == true);
            if (!hasRealDate) continue;

            for (
              DateTime d = _d(t.start);
              !d.isAfter(_d(t.end));
              d = d.add(const Duration(days: 1))
            ) {
              final isStart = d.isAtSameMomentAs(_d(t.start));
              final isEnd = d.isAtSameMomentAs(_d(t.end));
              (segmentsByDay[d] ??= []).add(
                DaySegment(t, isStart: isStart, isEnd: isEnd),
              );
            }
          }

          //색깔
          List<TaskItem> itemsByColor(int colorInt) =>
              tasks.where((t) => t.listcolor.value == colorInt).toList();

          //(달력에 표시하기 위하여 설정)
          List<DaySegment> eventLoader(DateTime day) =>
              segmentsByDay[_d(day)] ?? [];

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 9, left: 9, top: 11),
                child: Card(
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 15, right: 10, left: 10),
                        child: TableCalendar<DaySegment>(
                          locale: 'en_US',
                          firstDay: DateTime.utc(2025, 1, 1),
                          lastDay: DateTime.utc(2025, 12, 31),
                          focusedDay: _focusedDay,
                          startingDayOfWeek: StartingDayOfWeek.sunday,
                          eventLoader: eventLoader,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: false,
                            leftChevronPadding: const EdgeInsets.only(right: 3),
                            rightChevronPadding: const EdgeInsets.only(
                              right: 140,
                            ),
                            headerPadding: const EdgeInsets.only(
                              top: 10,
                              bottom: 21,
                            ),
                            titleTextFormatter: (date, locale) =>
                                _enMonth.format(date),
                            titleTextStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          rowHeight: 66.0,
                          calendarBuilders: CalendarBuilders<DaySegment>(
                            todayBuilder: (context, day, _) => Center(
                              child: Text(
                                '${day.day}',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                            markerBuilder: (context, day, segs) {
                              final dueSegs = segs
                                  .where((s) => s.isEnd)
                                  .toList();
                              if (dueSegs.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                // alignment: const Alignment(0, 1.5),
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dueSegs.map((seg) {
                                    return Container(
                                      height: 21,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: seg.task.listcolor,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(2),
                                        ),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          child: Text(
                                            seg.task.title,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          onPageChanged: (fd) => _focusedDay = fd,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 383,
                        height: 90,
                        child: ClipRRect(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset('assets/qwer.png', fit: BoxFit.cover),
                              Positioned(
                                left: 134,
                                bottom: 15,
                                child: Text(
                                  '과제마감까지 10:00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              //과제card
              Padding(
                padding: const EdgeInsets.only(
                  right: 9,
                  left: 9,
                  top: 11,
                  bottom: 20,
                ),
                child: Card(
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Text(
                                '과제',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  '완료된 항목 보기',
                                  style: TextStyle(color: Color(0xff676767)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...[
                          for (final e in sections)
                            List1(
                              listcolor: e.key, // ← 이 섹션의 색상
                              listtitle: labelFor(e.value), // ← 과목명 표시
                              items: e.value, // ← 이 색상의 과제들
                              onToggleDone: (t, v) => _toggleDone(t.id, v),
                              ddayText: _dday,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class List1 extends StatelessWidget {
  const List1({
    super.key,
    required this.listcolor,
    required this.listtitle,
    required this.items,
    required this.onToggleDone,
    required this.ddayText,
  });

  final int listcolor;
  final String listtitle;
  final List<TaskItem> items;
  final void Function(TaskItem, bool) onToggleDone;
  final String Function(DateTime) ddayText;

  Future<void> _addItem(BuildContext context) async {
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AssignmentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(listcolor: listcolor, listtitle: listtitle),
        for (final t in items)
          ListCollection(
            title: t.title,
            ddayLabel: ddayText(t.end),
            checked: t.done,
            onChanged: (v) => onToggleDone(t, v ?? false),
          ),
        Padding(
          padding: EdgeInsets.only(left: 15),
          child: TextButton(
            onPressed: () => _addItem(context),
            child: const Text(
              '+ 새 과제',
              style: TextStyle(color: Color(0xffC4C4C4)),
            ),
          ),
        ),
        Divider(indent: 17, endIndent: 20),
        SizedBox(height: 10),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.listcolor, required this.listtitle});
  final int listcolor;
  final String listtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
      child: SizedBox(
        width: 45,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(listcolor),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: Center(
            child: Text(
              listtitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.94,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ListCollection extends StatelessWidget {
  const ListCollection({
    super.key,
    required this.title,
    required this.ddayLabel,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String ddayLabel;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 26),
      child: Row(
        children: [
          Checkbox(value: checked, onChanged: onChanged),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const Spacer(),
          Text(
            ddayLabel,
            style: const TextStyle(
              color: Color(0xffE8302A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
