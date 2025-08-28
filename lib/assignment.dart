import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 과제 설정 화면
class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => AssignmentPageState();
}

enum OpenPanel { none, date, due, time, repeat, importance }

class AssignmentPageState extends State<AssignmentPage> {
  // controllers
  final TextEditingController subject = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController note = TextEditingController();
  final List<String> _subjects = [];

  static const List<Color> _palette = [
    Color.fromARGB(255, 255, 52, 45), // Bright Red
    Color.fromARGB(255, 52, 200, 90), // Fresh Green
    Color.fromARGB(255, 52, 173, 200), // Aqua Blue
    Color.fromARGB(255, 251, 84, 84), // Coral Red
    Color.fromARGB(255, 202, 131, 201), // Lavender Purple
    Color.fromARGB(255, 251, 126, 84), // Soft Orange
    Color.fromARGB(255, 137, 84, 251), // Violet
  ];
  final Map<String, Color> _subjectColors = {};
  int _nextColorIndex = 0;

  String? _selectedSubject;

  //과목입력
  Future<void> _openSubjectDialog() async {
    final tmp = TextEditingController(text: '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('과목 입력'),
        content: TextField(
          controller: tmp,
          autofocus: true,
          decoration: const InputDecoration(hintText: '과목명을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, tmp.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _subjects.insert(0, result); // [핵심] 새 칩을 가장 왼쪽(가장 먼저)으로
        final color = _palette[_nextColorIndex % _palette.length];
        _nextColorIndex++;
        _subjectColors[result] = color;
        subject.text = result; // 저장 로직과의 연결(기존 saveAssignment 그대로 사용)
      });
    }
  }

  // To Do 날짜
  bool dateOn = false;
  DateTime pickedDate = DateTime.now();

  // 마감일
  bool dueOn = false;
  DateTime pickedDue = DateTime.now();

  // 시간
  bool timeOn = false;
  TimeOfDay pickedTime = const TimeOfDay(hour: 14, minute: 0);

  // 반복
  bool repeatOn = false;
  int repeatIndex = 0;

  // 중요도
  bool importanceOn = false;
  int importance = 0; // 1–5

  // 현재 펼친 편집 패널
  OpenPanel openPanel = OpenPanel.none;

  // 반복 옵션 (초보자 친화적으로 Map)
  final List<Map<String, String>> repeatOptions = [
    {'code': 'none', 'label': '없음'},
    {'code': 'daily', 'label': '매일'},
    {'code': 'weekdays', 'label': '평일'},
    {'code': 'weekends', 'label': '주말'},
    {'code': 'weekly', 'label': '매주'},
    {'code': 'biweekly', 'label': '격주'},
    {'code': 'monthly', 'label': '매월'},
    {'code': 'yearly', 'label': '매년'},
  ];

  // 토글: 상태는 각각 유지 / 패널 표시만 전환
  void togglePanel(OpenPanel panel, bool on) {
    setState(() {
      if (panel == OpenPanel.date) {
        dateOn = on;
      } else if (panel == OpenPanel.due) {
        dueOn = on;
      } else if (panel == OpenPanel.time) {
        timeOn = on;
      } else if (panel == OpenPanel.repeat) {
        repeatOn = on;
      } else if (panel == OpenPanel.importance) {
        importanceOn = on;
      }

      if (on == true) {
        openPanel = panel;
      } else {
        if (openPanel == panel) {
          openPanel = OpenPanel.none;
        }
      }
    });
  }

  Future<void> saveAssignment() async {
    String s = subject.text.trim();
    String t = titleController.text.trim();
    final String key = _selectedSubject ?? s;
    final Map<String, dynamic> map = {};

    map['subjectColor'] = _subjectColors[key]?.value;

    if (s.isEmpty || t.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('과목과 할일은 필수입니다.')));
      return;
    }

    map['subject'] = s;
    map['todoTitle'] = t;
    map['note'] = note.text.trim();
    map['subtitle'] = _selectedSubject;

    // 날짜
    map['dateOn'] = dateOn;
    if (dateOn == true) {
      map['date'] = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      ).toIso8601String();
    } else {
      map['date'] = null;
    }

    // 마감일
    map['dueOn'] = dueOn;
    if (dueOn == true) {
      map['due'] = DateTime(
        pickedDue.year,
        pickedDue.month,
        pickedDue.day,
      ).toIso8601String();
    } else {
      map['due'] = null;
    }

    // 시간
    map['timeOn'] = timeOn;
    if (timeOn == true) {
      String hh = pickedTime.hour.toString().padLeft(2, '0');
      String mm = pickedTime.minute.toString().padLeft(2, '0');
      map['time24'] = '$hh:$mm';
    } else {
      map['time24'] = null;
    }

    // 반복
    map['repeatOn'] = repeatOn;
    if (repeatOn == true) {
      map['repeatCode'] = repeatOptions[repeatIndex]['code'];
    } else {
      map['repeatCode'] = null;
    }

    // 중요도
    map['importanceOn'] = importanceOn;
    if (importanceOn == true) {
      map['importance'] = importance;
    } else {
      map['importance'] = 0;
    }

    map['createdAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance.collection('assignments').add(map);
    if (!mounted) return;
    Navigator.pop(context, map);
  }

  @override
  void dispose() {
    subject.dispose();
    titleController.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // To-Do 날짜 패널
    Widget datePanel;
    if (openPanel == OpenPanel.date) {
      datePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.black, // 선택 색
                onPrimary: Colors.white,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: pickedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (d) {
                setState(() {
                  pickedDate = d;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 20),
        ],
      );
    } else {
      datePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          SizedBox(height: 20),
        ],
      );
    }

    // 마감일 패널
    Widget duePanel;
    if (openPanel == OpenPanel.due) {
      duePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFFF6E51), // FF6E51
                onPrimary: Colors.white,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: pickedDue,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (d) {
                setState(() {
                  pickedDue = d;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 20),
        ],
      );
    } else {
      duePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          SizedBox(height: 20),
        ],
      );
    }

    // 마감일 안내 문구 (토글 OFF 때 보이기)
    Widget dueTip;
    if (dueOn == false) {
      dueTip = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 6),
          Text(
            '! 마감일은 달력에 특별하게 표시돼요!',
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      dueTip = const SizedBox.shrink();
    }

    // 시간 패널
    Widget timePanel;
    if (openPanel == OpenPanel.time) {
      timePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              minuteInterval: 5,
              use24hFormat: false,
              initialDateTime: DateTime(
                0,
                1,
                1,
                pickedTime.hour,
                pickedTime.minute,
              ),
              onDateTimeChanged: (dt) {
                setState(() {
                  pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 20),
        ],
      );
    } else {
      timePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          SizedBox(height: 20),
        ],
      );
    }

    // 반복 패널
    List<Widget> repeatChildren = [];
    for (int i = 0; i < repeatOptions.length; i++) {
      String label;
      if (repeatOptions[i]['label'] == null) {
        label = '';
      } else {
        label = repeatOptions[i]['label']!;
      }
      repeatChildren.add(
        Center(child: Text(label, style: const TextStyle(fontSize: 18))),
      );
    }

    Widget repeatPanel;
    if (openPanel == OpenPanel.repeat) {
      repeatPanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: repeatIndex,
              ),
              onSelectedItemChanged: (i) {
                setState(() {
                  repeatIndex = i;
                });
              },
              children: repeatChildren,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 20),
        ],
      );
    } else {
      repeatPanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          SizedBox(height: 20),
        ],
      );
    }

    // 중요도 패널
    Widget importancePanel;
    if (openPanel == OpenPanel.importance) {
      importancePanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              bool filled = i < importance;
              return IconButton(
                onPressed: () {
                  setState(() {
                    importance = i + 1;
                  });
                },
                iconSize: 32,
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? Colors.amber : Colors.black26,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
        ],
      );
    } else {
      importancePanel = const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE5E5EA),
      );
    }

    // --------------------------- Scaffold ---------------------------
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar 흰색
        foregroundColor: Colors.black,
        elevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // 상태바 아이콘 어둡게
        title: const Text('과제 설정하기', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: saveAssignment),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(50, 30, 50, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    '과목',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      //생성된 과목
                      ..._subjects.map((s) {
                        final selected = _selectedSubject == s;
                        final bg = _subjectColors[s] ?? const Color(0xFFF3F3F3);
                        return TextButton(
                          onPressed: () {
                            setState(() {
                              // [추가] 1개만 선택되도록 토글
                              _selectedSubject = selected ? null : s;
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: bg,
                            minimumSize: Size(10, 33),
                            padding: EdgeInsets.symmetric(horizontal: 13),
                            shape: StadiumBorder(),
                            side: selected
                                ? const BorderSide(
                                    color: Colors.black54,
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: _openSubjectDialog,
                        icon: const Icon(
                          Icons.add,
                          size: 24,
                          color: Colors.black26,
                        ),
                        label: const Text(
                          '과목 추가',
                          style: TextStyle(fontSize: 16, color: Colors.black38),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F3F3),
                          minimumSize: Size(100, 33),
                          padding: EdgeInsets.symmetric(horizontal: 13),
                          shape: StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LabeledField(label: '할일', controller: titleController),
            const SizedBox(height: 10),
            LabeledField(label: '내용', controller: note),
            const SizedBox(height: 20),

            // To Do 날짜
            SwitchRow(
              label: 'To Do 날짜',
              value: dateOn,
              onChanged: (v) {
                togglePanel(OpenPanel.date, v);
              },
              activeColor: const Color(0xFF34C759),
              offTrackColor: const Color(0xFFE9E9EB),
            ),
            const SizedBox(height: 10),
            datePanel,

            // 마감일
            SwitchRow(
              label: '마감일',
              value: dueOn,
              onChanged: (v) {
                togglePanel(OpenPanel.due, v);
              },
              activeColor: const Color(0xFF34C759),
              offTrackColor: const Color(0xFFE9E9EB),
            ),
            dueTip, // 토글 OFF일 때 안내 문구
            const SizedBox(height: 10),
            duePanel,

            // 시간
            SwitchRow(
              label: '시간',
              value: timeOn,
              onChanged: (v) {
                togglePanel(OpenPanel.time, v);
              },
              activeColor: const Color(0xFF34C759),
              offTrackColor: const Color(0xFFE9E9EB),
            ),
            const SizedBox(height: 10),
            timePanel,

            // 반복
            SwitchRow(
              label: '반복',
              value: repeatOn,
              onChanged: (v) {
                togglePanel(OpenPanel.repeat, v);
              },
              activeColor: const Color(0xFF34C759),
              offTrackColor: const Color(0xFFE9E9EB),
            ),
            const SizedBox(height: 10),
            repeatPanel,

            // 중요도
            SwitchRow(
              label: '중요도',
              value: importanceOn,
              onChanged: (v) {
                togglePanel(OpenPanel.importance, v);
              },
              activeColor: const Color(0xFF34C759),
              offTrackColor: const Color(0xFFE9E9EB),
            ),
            const SizedBox(height: 10),
            importancePanel,
          ],
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.offTrackColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color offTrackColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeColor,
          inactiveTrackColor: offTrackColor,
        ),
      ],
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: controller,
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: Colors.black, fontSize: 14), // 입력 텍스트
              decoration: InputDecoration(
                isCollapsed: true,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF4F4F4), // 입력 영역 배경 회색
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AssignmentPage extends StatefulWidget {
//   const AssignmentPage({super.key});

//   @override
//   State<AssignmentPage> createState() => AssignmentPageState();
// }

// enum OpenPanel { none, date, due, time, repeat, importance }

// class AssignmentPageState extends State<AssignmentPage> {
//   // ---------- controllers ----------
//   final TextEditingController subject = TextEditingController();
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController note = TextEditingController();

//   // ---------- edit/create mode ----------
//   String? _docId; // set when editing
//   bool get isEdit => _docId != null;

//   // ---------- To Do 날짜 ----------
//   bool dateOn = false;
//   DateTime pickedDate = DateTime.now();

//   // ---------- 마감일 ----------
//   bool dueOn = false;
//   DateTime pickedDue = DateTime.now();

//   // ---------- 시간 ----------
//   bool timeOn = false;
//   TimeOfDay pickedTime = const TimeOfDay(hour: 14, minute: 0);

//   // ---------- 반복 ----------
//   bool repeatOn = false;
//   int repeatIndex = 0;

//   // ---------- 중요도 ----------
//   bool importanceOn = false;
//   int importance = 0; // 1–5

//   // ---------- 현재 펼친 패널 ----------
//   OpenPanel openPanel = OpenPanel.none;

//   // 반복 옵션
//   final List<Map<String, String>> repeatOptions = const [
//     {'code': 'none', 'label': '없음'},
//     {'code': 'daily', 'label': '매일'},
//     {'code': 'weekdays', 'label': '평일'},
//     {'code': 'weekends', 'label': '주말'},
//     {'code': 'weekly', 'label': '매주'},
//     {'code': 'biweekly', 'label': '격주'},
//     {'code': 'monthly', 'label': '매월'},
//     {'code': 'yearly', 'label': '매년'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // arguments는 build 이후 접근
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args is Map) {
//         final String? docId = args['docId'] as String?;
//         final Map<String, dynamic>? data = (args['data'] as Map?)
//             ?.cast<String, dynamic>();

//         if (docId != null && data != null) {
//           _docId = docId;
//           _prefillFromData(data);
//           setState(() {}); // UI 갱신
//         }
//       }
//     });
//   }

//   // Firestore Timestamp / ISO String 모두 처리
//   DateTime? _toDate(dynamic v) {
//     if (v == null) return null;
//     if (v is Timestamp) return v.toDate();
//     if (v is String && v.isNotEmpty) {
//       try {
//         return DateTime.parse(v);
//       } catch (_) {}
//     }
//     return null;
//   }

//   void _prefillFromData(Map<String, dynamic> data) {
//     // 텍스트
//     subject.text = (data['subject'] ?? '') as String;
//     titleController.text = (data['todoTitle'] ?? '') as String;
//     note.text = (data['note'] ?? '') as String;

//     // 날짜
//     dateOn = data['dateOn'] == true || data['date'] != null;
//     final d = _toDate(data['date']);
//     if (dateOn && d != null) {
//       pickedDate = DateTime(d.year, d.month, d.day);
//     }

//     // 마감일
//     dueOn = data['dueOn'] == true || data['due'] != null;
//     final due = _toDate(data['due']);
//     if (dueOn && due != null) {
//       pickedDue = DateTime(due.year, due.month, due.day);
//     }

//     // 시간
//     timeOn = data['timeOn'] == true || data['time24'] != null;
//     final t24 = data['time24'];
//     if (timeOn && t24 is String && RegExp(r'^\d{2}:\d{2}$').hasMatch(t24)) {
//       final parts = t24.split(':');
//       pickedTime = TimeOfDay(
//         hour: int.tryParse(parts[0]) ?? 14,
//         minute: int.tryParse(parts[1]) ?? 0,
//       );
//     } else if (timeOn && data['hour'] is int && data['minute'] is int) {
//       pickedTime = TimeOfDay(
//         hour: data['hour'] as int,
//         minute: data['minute'] as int,
//       );
//     }

//     // 반복
//     repeatOn = data['repeatOn'] == true || data['repeatCode'] != null;
//     final repCode = data['repeatCode'] as String?;
//     if (repeatOn && repCode != null) {
//       final idx = repeatOptions.indexWhere((m) => m['code'] == repCode);
//       if (idx >= 0) repeatIndex = idx;
//     }

//     // 중요도
//     importanceOn =
//         data['importanceOn'] == true || (data['importance'] ?? 0) > 0;
//     importance = (data['importance'] is int) ? (data['importance'] as int) : 0;
//     if (!importanceOn) importance = 0;
//   }

//   // 헤더 탭: 패널 열고/닫기만, 스위치 상태는 변경하지 않음
//   void _toggleOpen(OpenPanel panel) {
//     setState(() {
//       openPanel = (openPanel == panel) ? OpenPanel.none : panel;
//     });
//   }

//   // 스위치 제어: ON이면 해당 패널을 열고, OFF면 닫는다.
//   void _setSwitch(OpenPanel panel, bool on) {
//     setState(() {
//       switch (panel) {
//         case OpenPanel.date:
//           dateOn = on;
//           break;
//         case OpenPanel.due:
//           dueOn = on;
//           break;
//         case OpenPanel.time:
//           timeOn = on;
//           break;
//         case OpenPanel.repeat:
//           repeatOn = on;
//           break;
//         case OpenPanel.importance:
//           importanceOn = on;
//           if (!importanceOn) importance = 0;
//           break;
//         case OpenPanel.none:
//           break;
//       }
//       if (on) {
//         // switch ON → open details
//         openPanel = panel;
//       } else {
//         // switch OFF → close details if this panel was open
//         if (openPanel == panel) openPanel = OpenPanel.none;
//       }
//     });
//   }

//   Future<void> saveAssignment() async {
//     final s = subject.text.trim();
//     final t = titleController.text.trim();

//     if (s.isEmpty || t.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('과목과 할일은 필수입니다.')));
//       return;
//     }

//     final Map<String, dynamic> map = {};
//     map['subject'] = s;
//     map['todoTitle'] = t;
//     map['note'] = note.text.trim();

//     // 날짜
//     map['dateOn'] = dateOn;
//     map['date'] = dateOn
//         ? DateTime(
//             pickedDate.year,
//             pickedDate.month,
//             pickedDate.day,
//           ).toIso8601String()
//         : null;

//     // 마감일
//     map['dueOn'] = dueOn;
//     map['due'] = dueOn
//         ? DateTime(
//             pickedDue.year,
//             pickedDue.month,
//             pickedDue.day,
//           ).toIso8601String()
//         : null;

//     // 시간
//     map['timeOn'] = timeOn;
//     map['time24'] = timeOn
//         ? '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'
//         : null;

//     // 반복
//     map['repeatOn'] = repeatOn;
//     map['repeatCode'] = repeatOn ? repeatOptions[repeatIndex]['code'] : null;

//     // 중요도
//     map['importanceOn'] = importanceOn;
//     map['importance'] = importanceOn ? importance : 0;

//     if (isEdit) {
//       map['updatedAt'] = FieldValue.serverTimestamp();
//       await FirebaseFirestore.instance
//           .collection('assignments')
//           .doc(_docId)
//           .update(map);
//     } else {
//       map['done'] = false; // 신규는 기본 미완료
//       map['createdAt'] = FieldValue.serverTimestamp();
//       await FirebaseFirestore.instance.collection('assignments').add(map);
//     }

//     if (!mounted) return;
//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     subject.dispose();
//     titleController.dispose();
//     note.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // --------------------------- Scaffold ---------------------------
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white, // AppBar 흰색
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//         systemOverlayStyle: SystemUiOverlayStyle.dark, // 상태바 아이콘 어둡게
//         title: Text(
//           isEdit ? '과제 수정하기' : '과제 설정하기',
//           style: const TextStyle(color: Colors.black),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(icon: const Icon(Icons.check), onPressed: saveAssignment),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(50, 30, 50, 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             LabeledField(label: '과목', controller: subject),
//             const SizedBox(height: 10),
//             LabeledField(label: '할일', controller: titleController),
//             const SizedBox(height: 10),
//             LabeledField(label: '내용', controller: note),
//             const SizedBox(height: 20),

//             // ===== 날짜 =====
//             SectionHeader(
//               label: 'To Do 날짜',
//               value: dateOn,
//               onHeaderTap: () => _toggleOpen(OpenPanel.date),
//               onSwitchChanged: (v) => _setSwitch(OpenPanel.date, v),
//             ),
//             _SectionBody(
//               // CHANGED: only show lines when panel is actually open
//               showLines: openPanel == OpenPanel.date,
//               isOpen: openPanel == OpenPanel.date,
//               child: (openPanel == OpenPanel.date)
//                   ? Theme(
//                       data: Theme.of(context).copyWith(
//                         colorScheme: Theme.of(context).colorScheme.copyWith(
//                           primary: Colors.black,
//                           onPrimary: Colors.white,
//                         ),
//                       ),
//                       child: CalendarDatePicker(
//                         initialDate: pickedDate,
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                         onDateChanged: (d) => setState(() => pickedDate = d),
//                       ),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//             const SizedBox(height: 20),

//             // ===== 마감일 =====
//             SectionHeader(
//               label: '마감일',
//               value: dueOn,
//               onHeaderTap: () => _toggleOpen(OpenPanel.due),
//               onSwitchChanged: (v) => _setSwitch(OpenPanel.due, v),
//             ),
//             if (!dueOn)
//               const Padding(
//                 padding: EdgeInsets.only(top: 6, bottom: 8),
//                 child: Text(
//                   '! 마감일은 달력에 특별하게 표시돼요!',
//                   style: TextStyle(
//                     color: Colors.black54,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ),
//             _SectionBody(
//               // CHANGED: only show lines when panel is actually open
//               showLines: openPanel == OpenPanel.due,
//               isOpen: openPanel == OpenPanel.due,
//               child: (openPanel == OpenPanel.due)
//                   ? Theme(
//                       data: Theme.of(context).copyWith(
//                         colorScheme: Theme.of(context).colorScheme.copyWith(
//                           primary: const Color(0xFFFF6E51),
//                           onPrimary: Colors.white,
//                         ),
//                       ),
//                       child: CalendarDatePicker(
//                         initialDate: pickedDue,
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                         onDateChanged: (d) => setState(() => pickedDue = d),
//                       ),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//             const SizedBox(height: 20),

//             // ===== 시간 =====
//             SectionHeader(
//               label: '시간',
//               value: timeOn,
//               onHeaderTap: () => _toggleOpen(OpenPanel.time),
//               onSwitchChanged: (v) => _setSwitch(OpenPanel.time, v),
//             ),
//             _SectionBody(
//               // CHANGED: only show lines when panel is actually open
//               showLines: openPanel == OpenPanel.time,
//               isOpen: openPanel == OpenPanel.time,
//               child: (openPanel == OpenPanel.time)
//                   ? SizedBox(
//                       height: 180,
//                       child: CupertinoDatePicker(
//                         mode: CupertinoDatePickerMode.time,
//                         minuteInterval: 5,
//                         use24hFormat: false,
//                         initialDateTime: DateTime(
//                           0,
//                           1,
//                           1,
//                           pickedTime.hour,
//                           pickedTime.minute,
//                         ),
//                         onDateTimeChanged: (dt) => setState(
//                           () => pickedTime = TimeOfDay(
//                             hour: dt.hour,
//                             minute: dt.minute,
//                           ),
//                         ),
//                       ),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//             const SizedBox(height: 20),

//             // ===== 반복 =====
//             SectionHeader(
//               label: '반복',
//               value: repeatOn,
//               onHeaderTap: () => _toggleOpen(OpenPanel.repeat),
//               onSwitchChanged: (v) => _setSwitch(OpenPanel.repeat, v),
//             ),
//             _SectionBody(
//               // CHANGED: only show lines when panel is actually open
//               showLines: openPanel == OpenPanel.repeat,
//               isOpen: openPanel == OpenPanel.repeat,
//               child: (openPanel == OpenPanel.repeat)
//                   ? SizedBox(
//                       height: 160,
//                       child: CupertinoPicker(
//                         itemExtent: 40,
//                         scrollController: FixedExtentScrollController(
//                           initialItem: repeatIndex,
//                         ),
//                         onSelectedItemChanged: (i) =>
//                             setState(() => repeatIndex = i),
//                         children: List.generate(
//                           repeatOptions.length,
//                           (i) => Center(
//                             child: Text(
//                               repeatOptions[i]['label'] ?? '',
//                               style: const TextStyle(fontSize: 18),
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//             const SizedBox(height: 20),

//             // ===== 중요도 =====
//             SectionHeader(
//               label: '중요도',
//               value: importanceOn,
//               onHeaderTap: () => _toggleOpen(OpenPanel.importance),
//               onSwitchChanged: (v) => _setSwitch(OpenPanel.importance, v),
//             ),
//             _SectionBody(
//               // CHANGED: only show lines when panel is actually open
//               showLines: openPanel == OpenPanel.importance,
//               isOpen: openPanel == OpenPanel.importance,
//               child: (openPanel == OpenPanel.importance)
//                   ? Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: List.generate(5, (i) {
//                         final filled = i < importance;
//                         return IconButton(
//                           onPressed: () => setState(() => importance = i + 1),
//                           iconSize: 32,
//                           icon: Icon(
//                             filled
//                                 ? Icons.star_rounded
//                                 : Icons.star_border_rounded,
//                             color: filled ? Colors.amber : Colors.black26,
//                           ),
//                         );
//                       }),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Header row for each section:
// /// - Tapping the **label area** expands/collapses (does NOT change the switch)
// /// - Tapping the Switch changes the boolean; ON opens the panel, OFF closes it.
// /// Styling tweak points:
// ///   - label font: TextStyle in the Text below
// ///   - row height / padding: EdgeInsets.symmetric(...) in the Container below
// class SectionHeader extends StatelessWidget {
//   const SectionHeader({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.onHeaderTap,
//     required this.onSwitchChanged,
//   });

//   final String label;
//   final bool value;
//   final VoidCallback onHeaderTap;
//   final ValueChanged<bool> onSwitchChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 44, // header row height
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Row(
//         children: [
//           // Tappable label area
//           Expanded(
//             child: InkWell(
//               onTap: onHeaderTap, // open/close only
//               borderRadius: BorderRadius.circular(8),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // Switch (interactive)
//           CupertinoSwitch(
//             value: value,
//             onChanged: onSwitchChanged,
//             activeTrackColor: const Color(0xFF34C759),
//             inactiveTrackColor: const Color(0xFFE9E9EB),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Section body with the show/hide gray lines.
// /// - showLines: when true, show the top/bottom dividers
// /// - isOpen: when true, show the actual `child` (picker, calendar, etc.)
// ///   If not open but showLines==true (e.g., switch is ON), we keep a small spacer.
// class _SectionBody extends StatelessWidget {
//   const _SectionBody({
//     required this.showLines,
//     required this.isOpen,
//     required this.child,
//   });

//   final bool showLines; // ← controls gray lines
//   final bool isOpen; // ← controls details (calendar/picker)
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     if (!showLines) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
//         const SizedBox(height: 10),
//         if (isOpen) child else const SizedBox(height: 10),
//         const SizedBox(height: 10),
//         const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
//       ],
//     );
//   }
// }

// class LabeledField extends StatelessWidget {
//   const LabeledField({
//     super.key,
//     required this.label,
//     required this.controller,
//   });

//   final String label;
//   final TextEditingController controller;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         SizedBox(
//           width: 50,
//           child: Text(
//             label,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black,
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: SizedBox(
//             height: 34,
//             child: TextField(
//               controller: controller,
//               cursorColor: Colors.black,
//               textAlignVertical: TextAlignVertical.center,
//               style: const TextStyle(color: Colors.black, fontSize: 14),
//               decoration: InputDecoration(
//                 isCollapsed: true,
//                 isDense: true,
//                 filled: true,
//                 fillColor: const Color(0xFFE5E5E5), // 입력 영역 배경 회색
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
