import 'dart:convert';

import 'package:flutter/material.dart';

import 'main.dart';

// Memo 데이터의 형식을 정해줍니다. 추후 isPinned, updatedAt 등의 정보도 저장할 수 있습니다.
class Memo {
  Memo({
    required this.content,
    this.checked = false,
    this.date,
  });

  String content;
  bool checked;
  DateTime? date;

  Map toJson() {
    return {
      'content': content,
      'checked': checked,
      'date': date?.toIso8601String(),
    };
  }

  factory Memo.fromJson(json) {
    return Memo(
      content: json['content'],
      checked: json['checked'] ?? false,
      date: json['date'] == null ? null : DateTime.parse(json['date']),
    );
  }
}

// Memo 데이터는 모두 여기서 관리
class MemoService extends ChangeNotifier {
  MemoService() {
    loadMemoList();
  }

  List<Memo> memoList = []; //dummy

  createMemo({required String content}) {
    Memo memo = Memo(content: content);
    memoList.add(memo);
    notifyListeners(); // Consumer<MemoService>의 builder 부분을 호출해서 화면 새로고침
    saveMemoList();
  }

  updateMemo({required int index, required String content}) {
    Memo memo = memoList[index];
    memo.content = content;
    notifyListeners();
    saveMemoList();
  }

  updateCheck({required int index}) {
    Memo memo = memoList[index];
    memo.checked = !memo.checked;
    memoList = [
      ...memoList.where(
          (element) => element.checked), // ... : memoList배열에 값들을 추가해주게 해준다.
      ...memoList.where((element) => !element.checked)
    ];
    notifyListeners();
    saveMemoList();
  }

  deleteMemo({required int index}) {
    memoList.removeAt(index);
    notifyListeners();
    saveMemoList();
  }

  saveMemoList() {
    List memoJsonList = memoList.map((memo) => memo.toJson()).toList();

    String jsonString = jsonEncode(memoJsonList);

    prefs.setString('memoList', jsonString);
  }

  loadMemoList() {
    String? jsonString = prefs.getString('memoList');

    if (jsonString == null) return;

    List memoJsonList = jsonDecode(jsonString);

    memoList = memoJsonList.map((json) => Memo.fromJson(json)).toList();

    saveMemoList();
  }
}
