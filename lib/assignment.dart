import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => AssignmentPageState();
}

// 어떤 패널이 열려 있는지 구분용
enum OpenPanel { none, date, due, time, repeat, importance }

class AssignmentPageState extends State<AssignmentPage> {
  // 1텍스트 컨트롤러: 과목/제목/내용
  final TextEditingController subject = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController note = TextEditingController();

  // 2과목 색 관리: Firestore에 저장된 과목색 + 새로 추가한 로컬 과목
  final Map<String, Color> _subjectColors = {};
  final Set<String> _localNewSubjects = {}; // 아직 Firestore에 없는 임시 과목
  String? _selectedSubject;

  // 새 과목 색상 팔레트
  static const List<Color> _palette = [
    Color.fromARGB(255, 255, 52, 45),
    Color.fromARGB(255, 52, 200, 90),
    Color.fromARGB(255, 52, 173, 200),
    Color.fromARGB(255, 251, 84, 84),
    Color.fromARGB(255, 202, 131, 201),
    Color.fromARGB(255, 251, 126, 84),
    Color.fromARGB(255, 137, 84, 251),
  ];
  final Random _random = Random();

  // 3패널/스위치 상태 + 날짜/시간 값
  //  (편집 모드에서 기존 값으로 미리 채움)
  bool dateOn = false;
  DateTime pickedDate = DateTime.now();

  bool dueOn = false;
  DateTime pickedDue = DateTime.now();

  bool timeOn = false;
  TimeOfDay pickedTime = const TimeOfDay(hour: 14, minute: 0);

  bool repeatOn = false;
  int repeatIndex = 0; // repeatOptions 인덱스
  bool importanceOn = false;
  int importance = 0; // 0~5

  OpenPanel openPanel = OpenPanel.none;

  final List<Map<String, String>> repeatOptions = const [
    {'code': 'none', 'label': '없음'},
    {'code': 'daily', 'label': '매일'},
    {'code': 'weekdays', 'label': '평일'},
    {'code': 'weekends', 'label': '주말'},
    {'code': 'weekly', 'label': '매주'},
    {'code': 'biweekly', 'label': '격주'},
    {'code': 'monthly', 'label': '매월'},
    {'code': 'yearly', 'label': '매년'},
  ];

  // 4편집 모드 제어용
  //_docId: 수정할 문서 ID
  //_isEditing: 편집인지(=update) 신규인지(=add)
  //_initialData: 라우트에서 넘어온 캐시 데이터(있으면 바로 사용)
  String? _docId;
  bool _isEditing = false;
  Map<String, dynamic>? _initialData;
  bool _loading = true;

  // 페이지가 뜨고 난 뒤 라우트 인자 읽기 → 폼 채우기
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      // 목록에서 반드시 docId를 넘겨주도록 했으므로, 없으면 신규로 간주
      _docId = args != null ? args['docId'] as String? : null;
      _initialData = args != null
          ? args['data'] as Map<String, dynamic>?
          : null;
      _isEditing = _docId != null; // docId 있으면 편집 모드

      if (_isEditing) {
        if (_initialData != null) {
          // data가 함께 넘어왔으면 바로 세팅 (빠름)
          _fillFromMap(_initialData!);
          setState(() => _loading = false);
        } else {
          // data가 없으면 Firestore에서 불러오기
          await _fetchAndFill();
        }
      } else {
        // 신규 작성 모드
        setState(() => _loading = false);
      }
    });
  }

  // Firestore에서 문서 읽어와서 채우기(편집 모드)
  Future<void> _fetchAndFill() async {
    if (_docId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('assignments')
        .doc(_docId!)
        .get();
    if (!snap.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문서를 찾을 수 없습니다.')));
      Navigator.pop(context);
      return;
    }
    final data = snap.data() as Map<String, dynamic>;
    _fillFromMap(data);
    if (mounted) setState(() => _loading = false);
  }

  // 맵 폼/스위치/패널 상태로 주입
  void _fillFromMap(Map<String, dynamic> m) {
    // 텍스트들
    titleController.text = (m['todoTitle'] ?? '') as String;
    note.text = (m['note'] ?? '') as String;

    final subj = (m['subject'] ?? '') as String;
    subject.text = subj;
    _selectedSubject = subj.isEmpty ? null : subj;

    // 과목 색도 같이 들고 온다면 로컬 맵에 저장
    if (m['subjectColor'] is int) {
      _subjectColors[subj] = Color(m['subjectColor'] as int);
    }

    // 날짜/마감일: 저장 포맷이 ISO 문자열이므로 파싱해서 컨트롤에 반영
    dateOn = m['dateOn'] == true;
    if (m['date'] is String && (m['date'] as String).isNotEmpty) {
      try {
        final d = DateTime.parse(m['date'] as String);
        pickedDate = DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }

    dueOn =
        m['dueOn'] == true ||
        (m['due'] is String && (m['due'] as String).isNotEmpty);
    if (m['due'] is String && (m['due'] as String).isNotEmpty) {
      try {
        final d = DateTime.parse(m['due'] as String);
        pickedDue = DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }

    // 시간
    timeOn = m['timeOn'] == true;
    final time24 = (m['time24'] ?? '') as String;
    if (timeOn && time24.contains(':')) {
      final parts = time24.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      pickedTime = TimeOfDay(hour: h, minute: mm);
    }

    // 반복
    repeatOn = m['repeatOn'] == true;
    final repeatCode = (m['repeatCode'] ?? 'none') as String;
    repeatIndex = repeatOptions.indexWhere((e) => e['code'] == repeatCode);
    if (repeatIndex < 0) repeatIndex = 0;

    // 중요도
    importanceOn = m['importanceOn'] == true;
    importance = (m['importance'] ?? 0) is int ? m['importance'] as int : 0;
    importance = importance.clamp(0, 5);

    // UX: 켜져있는 패널이 있으면 그 패널이 보이도록 openPanel 잡아주기
    if (importanceOn) {
      openPanel = OpenPanel.importance;
    } else if (repeatOn) {
      openPanel = OpenPanel.repeat;
    } else if (timeOn) {
      openPanel = OpenPanel.time;
    } else if (dueOn) {
      openPanel = OpenPanel.due;
    } else if (dateOn) {
      openPanel = OpenPanel.date;
    } else {
      openPanel = OpenPanel.none;
    }
  }

  // 패널 헤더 토글
  void _toggleHeader(OpenPanel panel) {
    setState(() {
      openPanel = (openPanel == panel) ? OpenPanel.none : panel;
    });
  }

  // 스위치 패널 동기화
  void _onSwitchChanged(OpenPanel panel, bool value) {
    setState(() {
      switch (panel) {
        case OpenPanel.date:
          dateOn = value;
          break;
        case OpenPanel.due:
          dueOn = value;
          break;
        case OpenPanel.time:
          timeOn = value;
          break;
        case OpenPanel.repeat:
          repeatOn = value;
          break;
        case OpenPanel.importance:
          importanceOn = value;
          break;
        case OpenPanel.none:
          break;
      }
      if (value) {
        openPanel = panel; // 스위치 켜면 해당 패널 펼침
      } else if (openPanel == panel) {
        openPanel = OpenPanel.none;
      }
    });
  }

  // 과목 추가 다이얼로그 로컬 chip 생성(저장은 save 시)
  Future<void> _openSubjectDialog() async {
    final tmp = TextEditingController();
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
    if (result == null || result.isEmpty) return;

    setState(() {
      _localNewSubjects.add(result);
      _subjectColors[result] = _palette[_random.nextInt(_palette.length)];
      _selectedSubject = result;
      subject.text = result;
    });
  }

  // 저장: 편집이면 update, 신규면 add
  Future<void> saveAssignment() async {
    final s = (_selectedSubject ?? subject.text).trim();
    final t = titleController.text.trim();
    if (s.isEmpty || t.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('과목과 할일은 필수입니다.')));
      return;
    }

    // 과목 색상 보장
    Color chosen =
        _subjectColors[s] ?? _palette[_random.nextInt(_palette.length)];
    _subjectColors[s] = chosen;

    // 새 과목이면 subjects 컬렉션에 먼저 등록
    if (_localNewSubjects.contains(s)) {
      await FirebaseFirestore.instance.collection('subjects').add({
        'name': s,
        'color': chosen.value,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _localNewSubjects.remove(s);
    }

    // 저장 데이터 구성
    final map = <String, dynamic>{
      'subject': s,
      'subjectColor': chosen.value, // null 방지: 항상 값 쓰기
      'todoTitle': t,
      'note': note.text.trim(),

      'dateOn': dateOn,
      'date': dateOn
          ? DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
            ).toIso8601String()
          : null,

      'dueOn': dueOn,
      'due': dueOn
          ? DateTime(
              pickedDue.year,
              pickedDue.month,
              pickedDue.day,
            ).toIso8601String()
          : null,

      'timeOn': timeOn,
      'time24': timeOn
          ? '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}'
          : null,

      'repeatOn': repeatOn,
      'repeatCode': repeatOn ? repeatOptions[repeatIndex]['code'] : null,

      'importanceOn': importanceOn,
      'importance': importanceOn ? importance : 0,

      // 서버 시간
      if (_isEditing) 'updatedAt': FieldValue.serverTimestamp(),
      if (!_isEditing) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (_isEditing && _docId != null) {
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(_docId!)
          .update(map);
    } else {
      await FirebaseFirestore.instance.collection('assignments').add(map);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
    Navigator.pop(context, map);
  }

  @override
  void dispose() {
    subject.dispose();
    titleController.dispose();
    note.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          _isEditing ? '과제 수정하기' : '과제 설정하기',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: saveAssignment),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(50, 30, 50, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 라벨 "과목"
                  Row(
                    children: const [
                      SizedBox(
                        width: 50,
                        height: 20,
                        child: Text(
                          '과목',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 과목 칩: Firestore + 로컬 새 과목
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('subjects')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snap) {
                      final children = <Widget>[];
                      final Set<String> seen = {};

                      if (snap.hasData) {
                        for (final doc in snap.data!.docs) {
                          final data = doc.data();
                          final name = (data['name'] ?? '').toString();
                          if (name.isEmpty || seen.contains(name)) continue;
                          seen.add(name);

                          final colorInt = data['color'];
                          Color subjectColor;
                          if (colorInt is int) {
                            subjectColor = Color(colorInt);
                            _subjectColors[name] = subjectColor;
                          } else {
                            subjectColor =
                                _subjectColors[name] ??
                                _palette[_random.nextInt(_palette.length)];
                            _subjectColors[name] = subjectColor;
                            // DB에 색이 없으면 기록해둔다(베스트 에포트)
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              try {
                                doc.reference.update({
                                  'color': subjectColor.value,
                                });
                              } catch (_) {}
                            });
                          }

                          final selected = _selectedSubject == name;
                          children.add(
                            _buildSubjectChip(name, subjectColor, selected),
                          );
                        }
                      }

                      // 로컬 임시 과목
                      for (final name in _localNewSubjects) {
                        if (seen.contains(name)) continue;
                        seen.add(name);
                        final color =
                            _subjectColors[name] ?? const Color(0xFF888888);
                        _subjectColors[name] = color;
                        final selected = _selectedSubject == name;
                        children.add(_buildSubjectChip(name, color, selected));
                      }

                      // 과목 추가 버튼
                      children.add(
                        TextButton.icon(
                          onPressed: _openSubjectDialog,
                          icon: const Icon(
                            Icons.add,
                            size: 24,
                            color: Colors.black26,
                          ),
                          label: const Text(
                            '과목 추가',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black38,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F3F3),
                            minimumSize: const Size(100, 35),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      );

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: children,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  LabeledField(label: '할일', controller: titleController),
                  const SizedBox(height: 20),
                  LabeledField(label: '내용', controller: note),
                  const SizedBox(height: 20),

                  // ===== 패널들 =====
                  _SectionHeader(
                    label: 'To Do 날짜',
                    value: dateOn,
                    onHeaderTap: () => _toggleHeader(OpenPanel.date),
                    onSwitchChanged: (v) => _onSwitchChanged(OpenPanel.date, v),
                  ),
                  if (openPanel == OpenPanel.date)
                    _panelShell(_buildDatePicker()),
                  const SizedBox(height: 10),

                  _SectionHeader(
                    label: '마감일',
                    value: dueOn,
                    onHeaderTap: () => _toggleHeader(OpenPanel.due),
                    onSwitchChanged: (v) => _onSwitchChanged(OpenPanel.due, v),
                  ),
                  if (openPanel == OpenPanel.due)
                    _panelShell(_buildDuePicker()),
                  const SizedBox(height: 10),

                  _SectionHeader(
                    label: '시간',
                    value: timeOn,
                    onHeaderTap: () => _toggleHeader(OpenPanel.time),
                    onSwitchChanged: (v) => _onSwitchChanged(OpenPanel.time, v),
                  ),
                  if (openPanel == OpenPanel.time)
                    _panelShell(_buildTimePicker()),
                  const SizedBox(height: 10),

                  _SectionHeader(
                    label: '반복',
                    value: repeatOn,
                    onHeaderTap: () => _toggleHeader(OpenPanel.repeat),
                    onSwitchChanged: (v) =>
                        _onSwitchChanged(OpenPanel.repeat, v),
                  ),
                  if (openPanel == OpenPanel.repeat)
                    _panelShell(_buildRepeatPicker()),
                  const SizedBox(height: 10),

                  _SectionHeader(
                    label: '중요도',
                    value: importanceOn,
                    onHeaderTap: () => _toggleHeader(OpenPanel.importance),
                    onSwitchChanged: (v) =>
                        _onSwitchChanged(OpenPanel.importance, v),
                  ),
                  if (openPanel == OpenPanel.importance)
                    _panelShell(_buildImportancePicker()),
                ],
              ),
            ),
    );
  }

  // 과목 칩 1개
  Widget _buildSubjectChip(String name, Color color, bool selected) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedSubject = selected ? null : name;
          subject.text = selected ? '' : name;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(10, 33),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        shape: const StadiumBorder(),
        side: selected
            ? const BorderSide(color: Colors.black54, width: 1)
            : BorderSide.none,
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  // 패널 공통 테두리
  Widget _panelShell(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA)),
        // child 자리 const가 아니므로 아래에서 감싸지 않음
      ],
    ).copyWithChild(child);
  }

  // 날짜 선택기(오늘-2100년)
  Widget _buildDatePicker() => CalendarDatePicker(
    initialDate: pickedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    onDateChanged: (d) => setState(() => pickedDate = d),
  );

  // 마감일 선택기
  Widget _buildDuePicker() => CalendarDatePicker(
    initialDate: pickedDue,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    onDateChanged: (d) => setState(() => pickedDue = d),
  );

  // 시간 선택기(쿠퍼티노 스타일)
  Widget _buildTimePicker() => SizedBox(
    height: 180,
    child: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      minuteInterval: 5,
      initialDateTime: DateTime(0, 1, 1, pickedTime.hour, pickedTime.minute),
      onDateTimeChanged: (dt) => setState(
        () => pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute),
      ),
    ),
  );

  // 반복 선택기(코드/라벨 매핑)
  Widget _buildRepeatPicker() => SizedBox(
    height: 160,
    child: CupertinoPicker(
      itemExtent: 40,
      scrollController: FixedExtentScrollController(initialItem: repeatIndex),
      onSelectedItemChanged: (i) => setState(() => repeatIndex = i),
      children: repeatOptions
          .map((m) => Center(child: Text(m['label'] ?? '')))
          .toList(),
    ),
  );

  // 중요도(별 1~5)
  Widget _buildImportancePicker() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(5, (i) {
      final filled = i < importance;
      return IconButton(
        onPressed: () => setState(() => importance = i + 1),
        icon: Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: filled ? Colors.amber : Colors.black26,
        ),
      );
    }),
  );
}

// 패널 감싸는 Column에 child를 끼워 넣기 위한 작은 헬퍼 (가독성용)
extension _ColumnChild on Column {
  Column copyWithChild(Widget middleChild) {
    final children = List<Widget>.from(this.children);
    children.insert(1, middleChild);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.value,
    required this.onHeaderTap,
    required this.onSwitchChanged,
  });

  final String label;
  final bool value;
  final VoidCallback onHeaderTap;
  final ValueChanged<bool> onSwitchChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onHeaderTap, // 라벨 줄을 눌러도 패널 열고 닫기
      child: Row(
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
            onChanged: onSwitchChanged, // 스위치와 패널 상태 동기화
            activeTrackColor: const Color(0xFF34C759),
            inactiveTrackColor: const Color(0xFFE9E9EB),
          ),
        ],
      ),
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
          child: TextField(
            controller: controller,
            cursorColor: Colors.black,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
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
      ],
    );
  }
}
