import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Assignment input page
class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

enum _OpenPanel { none, date, time, repeat, importance }

class _AssignmentPageState extends State<AssignmentPage> {
  // text controllers
  final _subject = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();

  // switches
  bool _dateOn = false;
  DateTime _pickedDate = DateTime.now();

  bool _timeOn = false;
  TimeOfDay _pickedTime = const TimeOfDay(hour: 14, minute: 0);

  bool _repeatOn = false;
  int _repeatIndex = 0;

  bool _importanceOn = false;
  int _importance = 3; // 1–5

  _OpenPanel _open = _OpenPanel.none;

  static const _repeatOptions = <(String code, String label)>[
    ('none', '없음'),
    ('daily', '매일'),
    ('weekdays', '평일'),
    ('weekends', '주말'),
    ('weekly', '매주'),
    ('biweekly', '격주'),
    ('monthly', '매월'),
    ('yearly', '매년'),
  ];

  void _toggle(_OpenPanel panel, bool on) {
    setState(() {
      if (on) {
        _open = panel;
        _dateOn = panel == _OpenPanel.date;
        _timeOn = panel == _OpenPanel.time;
        _repeatOn = panel == _OpenPanel.repeat;
        _importanceOn = panel == _OpenPanel.importance;
      } else {
        if (_open == panel) _open = _OpenPanel.none;
        switch (panel) {
          case _OpenPanel.date:
            _dateOn = false;
            break;
          case _OpenPanel.time:
            _timeOn = false;
            break;
          case _OpenPanel.repeat:
            _repeatOn = false;
            break;
          case _OpenPanel.importance:
            _importanceOn = false;
            break;
          case _OpenPanel.none:
            break;
        }
      }
    });
  }

  Future<void> _save() async {
    if (_subject.text.trim().isEmpty || _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('과목과 할일은 필수입니다.')),
      );
      return;
    }

    final map = <String, dynamic>{
      'subject': _subject.text.trim(),
      'todoTitle': _title.text.trim(),
      'note': _note.text.trim(),
      'dateOn': _dateOn,
      'date': _dateOn
          ? DateTime(_pickedDate.year, _pickedDate.month, _pickedDate.day)
          .toIso8601String()
          : null,
      'timeOn': _timeOn,
      'time24': _timeOn
          ? '${_pickedTime.hour.toString().padLeft(2, '0')}:${_pickedTime.minute.toString().padLeft(2, '0')}'
          : null,
      'repeatOn': _repeatOn,
      'repeatCode': _repeatOn ? _repeatOptions[_repeatIndex].$1 : null,
      'importanceOn': _importanceOn,
      'importance': _importanceOn ? _importance : 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('assignments').add(map);

    if (!mounted) return;
    Navigator.pop(context); // close page after saving
  }

  @override
  void dispose() {
    _subject.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider =
    Divider(height: 24, thickness: 1, color: Theme.of(context).dividerColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 설정하기'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _SimpleField(label: '과목', controller: _subject),
            const SizedBox(height: 10),
            _SimpleField(label: '할일', controller: _title),
            const SizedBox(height: 10),
            _SimpleField(label: '내용', controller: _note),
            const SizedBox(height: 20),

            _SwitchRow(
                label: '날짜',
                value: _dateOn,
                onChanged: (v) => _toggle(_OpenPanel.date, v)),
            if (_open == _OpenPanel.date) ...[
              divider,
              CalendarDatePicker(
                initialDate: _pickedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (d) => setState(() => _pickedDate = d),
              ),
              divider,
            ],

            _SwitchRow(
                label: '시간',
                value: _timeOn,
                onChanged: (v) => _toggle(_OpenPanel.time, v)),
            if (_open == _OpenPanel.time) ...[
              divider,
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 5,
                  use24hFormat: false,
                  initialDateTime: DateTime(
                      0, 1, 1, _pickedTime.hour, _pickedTime.minute),
                  onDateTimeChanged: (dt) => setState(() =>
                  _pickedTime =
                      TimeOfDay(hour: dt.hour, minute: dt.minute)),
                ),
              ),
              divider,
            ],

            _SwitchRow(
                label: '반복',
                value: _repeatOn,
                onChanged: (v) => _toggle(_OpenPanel.repeat, v)),
            if (_open == _OpenPanel.repeat) ...[
              divider,
              SizedBox(
                height: 160,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController:
                  FixedExtentScrollController(initialItem: _repeatIndex),
                  onSelectedItemChanged: (i) =>
                      setState(() => _repeatIndex = i),
                  children: _repeatOptions
                      .map((e) =>
                      Center(child: Text(e.$2, style: const TextStyle(fontSize: 18))))
                      .toList(),
                ),
              ),
              divider,
            ],

            _SwitchRow(
                label: '중요도',
                value: _importanceOn,
                onChanged: (v) => _toggle(_OpenPanel.importance, v)),
            if (_open == _OpenPanel.importance) ...[
              divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final filled = i < _importance;
                  return IconButton(
                    onPressed: () => setState(() => _importance = i + 1),
                    iconSize: 32,
                    icon: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: filled ? Colors.amber : null,
                    ),
                  );
                }),
              ),
              divider,
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600))),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SimpleField extends StatelessWidget {
  const _SimpleField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
