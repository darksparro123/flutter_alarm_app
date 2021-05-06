import 'package:clock_app/alarm_helper.dart';
import 'package:clock_app/constants/theme_data.dart';

import 'package:clock_app/models/alarm_info.dart';
import 'package:clock_app/services/notificationPlugin.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  DateTime _alarmTime;
  String _alarmTimeString;
  AlarmHelper _alarmHelper = AlarmHelper();
  Future<List<AlarmInfo>> _alarms;
  List<AlarmInfo> _currentAlarms;
  final _formKey = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  var date;
  @override
  void initState() {
    _alarmTime = DateTime.now();
    _alarmHelper.initializeDatabase().then((value) {
      print('------database intialized');
      loadAlarms();
    });
    notificationPlugin
        .setListenerForLowerVersions(onNotificationInLowerVersions);
    notificationPlugin.setOnNotificationClick(onNotificationClick);
    super.initState();
  }

  void loadAlarms() {
    _alarms = _alarmHelper.getAlarms();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Alarm',
            style: TextStyle(
                fontFamily: 'avenir',
                fontWeight: FontWeight.w700,
                color: CustomColors.primaryTextColor,
                fontSize: 24),
          ),
          Expanded(
            child: FutureBuilder<List<AlarmInfo>>(
              future: _alarms,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _currentAlarms = snapshot.data;
                  return ListView(
                    children: snapshot.data.map<Widget>((alarm) {
                      var alarmTime =
                          DateFormat('hh:mm aa').format(alarm.alarmDateTime);
                      var gradientColor = GradientTemplate
                          .gradientTemplate[alarm.gradientColorIndex].colors;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColor,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColor.last.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: Offset(4, 4),
                            ),
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.label,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      alarm.title,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'avenir'),
                                    ),
                                  ],
                                ),
                                Switch(
                                  onChanged: (bool value) {},
                                  value: true,
                                  activeColor: Colors.white,
                                ),
                              ],
                            ),
                            Text(
                              '${alarm.description}',
                              style: TextStyle(
                                  color: Colors.white, fontFamily: 'avenir'),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  alarmTime,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'avenir',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700),
                                ),
                                IconButton(
                                    icon: Icon(Icons.delete),
                                    color: Colors.white,
                                    onPressed: () {
                                      deleteAlarm(alarm.id);
                                      notificationPlugin
                                          .cancelNotification(alarm.id);
                                    }),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).followedBy([
                      if (_currentAlarms.length < 5)
                        DottedBorder(
                          strokeWidth: 2,
                          color: CustomColors.clockOutline,
                          borderType: BorderType.RRect,
                          radius: Radius.circular(24),
                          dashPattern: [5, 4],
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: CustomColors.clockBG,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(24)),
                            ),
                            child: MaterialButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              onPressed: () {
                                // scheduleAlarm();
                                setAlarmSheet();
                              },
                              child: Column(
                                children: <Widget>[
                                  Image.asset(
                                    'assets/add_alarm.png',
                                    scale: 1.5,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Alarm',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'avenir'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                            child: Text(
                          'Only 5 alarms allowed!',
                          style: TextStyle(color: Colors.white),
                        )),
                    ]).toList(),
                  );
                }
                return Center(
                  child: Text(
                    'Loading..',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // saving alarm to data base and add alarm details to notifications
  void onSaveAlarm(int hour, int minute, String alarmName,
      String alarmDescription, bool isAlarm, DateTime t) {
    DateTime scheduleAlarmDateTime;
    if (_alarmTime.isAfter(DateTime.now()))
      scheduleAlarmDateTime = _alarmTime;
    else
      scheduleAlarmDateTime = _alarmTime.add(Duration(days: 1));

    var alarmInfo = AlarmInfo(
      alarmDateTime: scheduleAlarmDateTime,
      description: alarmDescription,
      gradientColorIndex: _currentAlarms.length,
      title: '$alarmName',
    );
    _alarmHelper.insertAlarm(alarmInfo);
    _alarmHelper.getAlarms().then((value) {
      for (int i = 0; i < value.length; i++) {
        if (alarmInfo.alarmDateTime == value[i].alarmDateTime) {
          if (isAlarm) {
            notificationPlugin.setAlarm(
              hour,
              minute,
              alarmName,
              alarmDescription,
              value[i].id,
            );
          } else {
            notificationPlugin.setRemainder(
              hour,
              minute,
              alarmName,
              alarmDescription,
              value[i].id,
              t,
            );
          }
        }
      }
    });
    //scheduleAlarm(scheduleAlarmDateTime, alarmInfo);
    Navigator.pop(context);
    loadAlarms();
  }

  void deleteAlarm(int id) {
    _alarmHelper.delete(id);
    //unsubscribe the notification
    //flutterLocalNotificationsPlugin.cancel(id);
    loadAlarms();
  }

  onNotificationInLowerVersions(RecievedNotification receivedNotification) {
    print('Notification Received ${receivedNotification.id}');
  }

  onNotificationClick(String payload) {
    print('Payload $payload');
  }

  void setAlarmSheet() {
    _alarmTimeString = "Okay";
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialButton(
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: GradientColors.sunset,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    GradientColors.sunset.last.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: Offset(4, 4),
                              ),
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          child: Text(
                            "Set an alarm",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.0,
                            ),
                          )),
                      onPressed: () {
                        Get.dialog(Dialog(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 1.3,
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: name,
                                      decoration: InputDecoration(
                                        labelText: "Alarm name",
                                      ),
                                      validator: (val) => val.isEmpty
                                          ? "Please set an name to alarm"
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: description,
                                      decoration: InputDecoration(
                                        labelText: "Alarm description",
                                      ),
                                    ),
                                  ),
                                  MaterialButton(
                                    onPressed: () async {
                                      /*showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(Duration(
                                            days: 365,
                                          )));*/
                                      if (_formKey.currentState.validate()) {
                                        var selectedTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                            confirmText: "SetAlarm");

                                        if (selectedTime != null) {
                                          final now = DateTime.now();
                                          var selectedDateTime = DateTime(
                                              now.year,
                                              now.month,
                                              now.day,
                                              selectedTime.hour,
                                              selectedTime.minute);
                                          _alarmTime = selectedDateTime;
                                          setModalState(() {
                                            _alarmTimeString =
                                                DateFormat('HH:mm')
                                                    .format(selectedDateTime);
                                            print(
                                                "Alarm time is $_alarmTimeString");
                                          });
                                          onSaveAlarm(
                                            int.parse(
                                                _alarmTimeString.split(":")[0]),
                                            int.parse(
                                                _alarmTimeString.split(":")[1]),
                                            name.text,
                                            (description.text == null)
                                                ? "${description.text}"
                                                : "",
                                            true,
                                            DateTime.now(),
                                          );
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 32),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: GradientColors.sky,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        child: Text("Pick Time",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22.0,
                                            ))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      }),
                  MaterialButton(
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: GradientColors.mango,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    GradientColors.mango.last.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: Offset(4, 4),
                              ),
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          child: Text(
                            "Set an remainder",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28.0,
                            ),
                          )),
                      onPressed: () {
                        Get.dialog(Dialog(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 1.3,
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: name,
                                      decoration: InputDecoration(
                                        labelText: "Alarm name",
                                      ),
                                      validator: (val) => val.isEmpty
                                          ? "Please set an name to alarm"
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: TextFormField(
                                      controller: description,
                                      decoration: InputDecoration(
                                        labelText: "Alarm description",
                                      ),
                                    ),
                                  ),
                                  MaterialButton(
                                    onPressed: () async {
                                      DateTime d = await datePicker();
                                      setState(() {
                                        date = d;
                                      });
                                    },
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 32),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: GradientColors.sky,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        child: Text("Pick Date",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22.0,
                                            ))),
                                  ),
                                  MaterialButton(
                                    onPressed: () async {
                                      if (_formKey.currentState.validate()) {
                                        var selectedTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                            confirmText: "SetAlarm");

                                        if (selectedTime != null) {
                                          if (date == null) {
                                            return Get.dialog(
                                              AlertDialog(
                                                  title: Text(" Pick a  time")),
                                            );
                                          } else {
                                            final now = DateTime.now();
                                            DateTime selectedDateTime =
                                                DateTime(
                                                    now.year,
                                                    now.month,
                                                    now.day,
                                                    selectedTime.hour,
                                                    selectedTime.minute);
                                            _alarmTime = selectedDateTime;
                                            setModalState(() {
                                              _alarmTimeString =
                                                  DateFormat('HH:mm')
                                                      .format(selectedDateTime);
                                            });
                                            onSaveAlarm(
                                              int.parse(_alarmTimeString
                                                  .split(":")[0]),
                                              int.parse(_alarmTimeString
                                                  .split(":")[1]),
                                              name.text,
                                              (description.text == null)
                                                  ? "${description.text}"
                                                  : "",
                                              false,
                                              selectedDateTime,
                                            );
                                            Navigator.pop(context);
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 32),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: GradientColors.sky,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        child: Text("Pick Time",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22.0,
                                            ))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      })
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime> datePicker() async {
    var date = await showDatePicker(
      lastDate: DateTime.now().add(
        Duration(days: 365),
      ),
      firstDate: DateTime.now(),
      initialDate: DateTime.now(),
      context: context,
    );
    print("date is $date");
    return date;
  }
}
