import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // 오늘 기준
  final DateTime _kToday = DateTime.now();
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  final Map<DateTime, List<String>> _events = {
    _dateOnly(DateTime(2025, 8, 25)): ['미적분', '심리학'],
    _dateOnly(DateTime(2025, 8, 26)): ['물리학'],
  };

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[_dateOnly(day)] ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = _kToday;
    _selectedDay = _kToday; // 시작 시 오늘 선택 (원치 않으면 null)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('달력'),
        actions: [
          IconButton(
            tooltip: '오늘로 이동',
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR', // TableCalendar에 한국어 적용
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // 월 전환 시 기준일 유지
              });
            },
            onPageChanged: (focusedDay) {
              // 월을 넘길 때 내부 포커스 갱신 (setState 불필요)
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: null, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _selectedDay == null
                      ? '-'
                      : '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _kToday)
                  .map((e) => ListTile(
                        title: Text(e.toString()),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
