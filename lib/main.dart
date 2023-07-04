//import 'dart:ffi';

//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'todolist_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoService>(
      builder: (context, memoService, child) {
        // memoService로 부터 memoList 가져오기
        List<Memo> memoList = memoService.memoList;

        return Scaffold(
          appBar: AppBar(
            title: Text("To_Do_List"),
          ),
          body: memoList.isEmpty
              ? Center(child: Text("할 일을 작성해 주세요."))
              : ListView.builder(
                  itemCount: memoList.length, // memoList 개수 만큼 보여주기
                  itemBuilder: (context, index) {
                    Memo memo = memoList[index]; // index에 해당하는 memo 가져오기
                    return Column(
                      children: [
                        ListTile(
                          // 메모 고정 아이콘
                          leading: Checkbox(
                            value: memo.checked ?? false,
                            onChanged: (bool? newValue) {
                              setState(() {
                                memo.checked = newValue ?? false;
                              });
                            },
                          ),
                          // 메모 내용 (최대 3줄까지만 보여주도록)
                          title: Text(
                            memo.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: InkWell(
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: memo.date ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  memo.date = selectedDate;
                                  //date = selectedDate;
                                });
                              }
                            },
                            child: Text(
                              memo.date != null
                                  ? "${memo.date!.year.toString()}-${memo.date!.month.toString().padLeft(2, '0')}-${memo.date!.day.toString().padLeft(2, '0')}"
                                  : "Select Date",
                            ),
                          ),
                          onTap: () {
                            // 아이템 클릭시
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(
                                  index: index,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          height: 1,
                          color: const Color.fromARGB(255, 220, 220, 220),
                        )
                      ],
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              // + 버튼 클릭시 메모 생성 및 수정 페이지로 이동
              memoService.createMemo(content: '');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    index: memoService.memoList.length - 1,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// 메모 생성 및 수정 페이지
class DetailPage extends StatelessWidget {
  DetailPage({super.key, required this.index});

  final int index;

  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MemoService memoService = context.read<MemoService>();
    Memo memo = memoService.memoList[index];

    contentController.text = memo.content;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // 삭제 버튼 클릭시
              showDeleteDialog(context, memoService);
            },
            icon: Icon(Icons.delete),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: contentController,
          decoration: InputDecoration(
            hintText: "오늘의 할 일을 적어보세요.",
            border: InputBorder.none,
          ),
          autofocus: true,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            // 텍스트필드 안의 값이 변할 때
            memoService.updateMemo(index: index, content: value);
          },
        ),
      ),
    );
  }

  void showDeleteDialog(BuildContext context, MemoService memoService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("정말로 삭제하시겠습니까?"),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소"),
            ),
            // 확인 버튼
            TextButton(
              onPressed: () {
                memoService.deleteMemo(index: index);
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // HomePage 로 가기
              },
              child: Text(
                "확인",
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }
}
