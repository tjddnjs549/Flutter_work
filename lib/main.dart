//import 'dart:ffi';

//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'todolist_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
//import 'package:geolocator/geolocator.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
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
  FlutterLocalNotificationsPlugin localNotification =
      FlutterLocalNotificationsPlugin();
  Future<void> _initLocalNotification() async {
    FlutterLocalNotificationsPlugin localNotification =
        FlutterLocalNotificationsPlugin();
    AndroidInitializationSettings initSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initSettingsIOS =
        const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await localNotification.initialize(
      initSettings,
    );
  }

  final NotificationDetails _details = const NotificationDetails(
    android: AndroidNotificationDetails('alarm 1', '1번 푸시'),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  Future<void> showPushAlarm() async {
    FlutterLocalNotificationsPlugin localNotification =
        FlutterLocalNotificationsPlugin();
    await localNotification.show(0, '단일 푸시 알림', '누르자마자 알림이 옵니다.', _details,
        payload: 'deepLink');
  }

  tz.TZDateTime _timeZoneSetting({required int seconds, required selectDate}) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime diff = tz.TZDateTime(
      tz.local,
      selectDate.year,
      selectDate.month,
      selectDate.day,
      now.hour,
      now.minute,
      now.second,
    );
    Duration difference = diff.difference(now);
    int diffDays = difference.inDays + 1;
    tz.TZDateTime scheduledDate = now.add(Duration(days: 0, seconds: seconds));
    //위 Duration에 diffdays를 넣으면 해당 날짜에 알림이 감
    return scheduledDate;
  }

  Future<void> selectedDatePushAlarm(selectDate) async {
    FlutterLocalNotificationsPlugin localNotification =
        FlutterLocalNotificationsPlugin();
    await localNotification.zonedSchedule(
      1,
      '로컬 푸시 알림 2',
      '특정 날짜 / 시간대 전송 알림',
      _timeZoneSetting(seconds: 2, selectDate: selectDate),
      _details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      //matchDateTimeComponents: DateTimeComponents.time, 이 코드를 추가하면 매일 정해진시간대에 울려줌
    );
  }

  @override
  void initState() {
    _initLocalNotification();
    localNotification
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoService>(
      builder: (context, memoService, child) {
        // memoService로 부터 memoList 가져오기
        List<Memo> memoList = memoService.memoList;
// 앱바에 아이콘 만들기 -> 아이콘 누르면 들어가지는 페이지 만들기 -> 페이지 꾸미기 -> 페이지 api받아오기. -> 데이터 구성.
        return Scaffold(
          appBar: AppBar(
            title: Text("To_Do_List"),
            actions: [
              IconButton(
                icon: Icon(Icons.sunny_snowing),
                onPressed: () {
                  print("날씨 클릭");
                },
              ),
            ],
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
                                memoService.updateCheck(index: index);
                              });
                            },
                          ),
                          // 메모 내용 (최대 3줄까지만 보여주도록)
                          title: Text(
                            memo.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: memoList[index].checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
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
                                  selectedDatePushAlarm(selectedDate);
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
                          onTap: () async {
                            // 아이템 클릭시
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(
                                  index: index,
                                ),
                              ),
                            );
                            if (memo.content.isEmpty) {
                              memoService.deleteMemo(index: index);
                            }
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
            onPressed: () async {
              // + 버튼 클릭시 메모 생성 및 수정 페이지로 이동
              memoService.createMemo(content: '');
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    index: memoService.memoList.length - 1,
                  ),
                ),
              );
              if (memoList[memoService.memoList.length - 1].content.isEmpty) {
                memoService.deleteMemo(index: memoList.length - 1);
              }
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
