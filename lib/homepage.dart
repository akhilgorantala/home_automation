import 'dart:async';

import 'package:esptouch_flutter/esptouch_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:wifi_iot/wifi_iot.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<ESPTouchResult> stream;
  late final StreamSubscription<ESPTouchResult> streamSubscription;
  late final Timer timer;

  final List<ESPTouchResult> results = [];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController ssid = TextEditingController();
  final TextEditingController bssid = TextEditingController();
  final TextEditingController password = TextEditingController();
  ESPTouchPacket packet = ESPTouchPacket.broadcast;

  int? frequency;

  String? SSID;
  String? BSSID;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkPermission();
    getFrequency();
    getssid();
  }

  void getssid() async {
    final ssidvalue = await WiFiForIoTPlugin.getSSID();
    final bssidvalue = await WiFiForIoTPlugin.getBSSID();

    setState(() {
      SSID = ssidvalue;
      BSSID = bssidvalue;
      ssid.text = ssidvalue!;
      bssid.text = bssidvalue!;
    });
    print(SSID);
  }

  void getFrequency() async {
    var value = await WiFiForIoTPlugin.getFrequency();
    value = int.parse(value.toString()[0]);
    setState(() {
      frequency = value;
    });
  }

  @override
  void dispose() {
    ssid.dispose();
    bssid.dispose();
    password.dispose();
    super.dispose();
  }

  createTask() {
    Duration? durationTryParse(String milliseconds) {
      final parsed = int.tryParse(milliseconds);
      return parsed != null ? Duration(milliseconds: parsed) : null;
    }

    return ESPTouchTask(
      ssid: ssid.text,
      bssid: bssid.text,
      password: password.text,
      packet: packet,
    );
  }

  checkPermission() async {
    Location location = new Location();
    bool ison = await location.serviceEnabled();
    if (ison == true) {
      location.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  TextFormField(
                    controller: ssid,
                    decoration: const InputDecoration(
                      labelText: 'SSID',
                      // hintText: 'Tony\'s iPhone',
                      // helperText: helperSSID,
                    ),
                  ),
                  TextFormField(
                    controller: bssid,
                    decoration: const InputDecoration(
                      labelText: 'BSSID',
                      // hintText: '00:a0:c9:14:c8:29',
                      // helperText: helperBSSID,
                    ),
                  ),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      // hintText: r'V3Ry.S4F3-P@$$w0rD',
                      // helperText: helperPassword,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        if (frequency == 2) {
                          print('am here 2');

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TaskRoute(task: createTask())));
                        } else if (frequency == 5) {
                          print('am here 5');

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Connect to 2.4Ghz Network'),
                          ));
                        } else {
                          print('am here nothing');

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TaskRoute(task: createTask())));

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Something went wrong!'),
                          ));
                        }
                      },
                      child: Text('Done')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskRoute extends StatefulWidget {
  TaskRoute({required this.task});

  final ESPTouchTask task;

  @override
  State<StatefulWidget> createState() => TaskRouteState();
}

class TaskRouteState extends State<TaskRoute> {
  late final Stream<ESPTouchResult> stream;
  late final StreamSubscription<ESPTouchResult> streamSubscription;
  late final Timer timer;

  final List<ESPTouchResult> results = [];

  @override
  void initState() {
    stream = widget.task.execute();
    streamSubscription = stream.listen(results.add);
    final receiving = widget.task.taskParameter.waitUdpReceiving;
    final sending = widget.task.taskParameter.waitUdpSending;
    final cancelLatestAfter = receiving + sending;
    timer = Timer(
      cancelLatestAfter,
      () {
        streamSubscription.cancel();
        if (results.isEmpty && mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('No devices found'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context)
                      ..pop()
                      ..pop(),
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      },
    );
    super.initState();
    print(results.toString());
  }

  @override
  dispose() {
    timer.cancel();
    streamSubscription.cancel();
    super.dispose();
  }

  Widget waitingState(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),
          SizedBox(height: 16),
          Text('Waiting for results'),
        ],
      ),
    );
  }

  Widget error(BuildContext context, String s) {
    return Center(child: Text(s, style: TextStyle(color: Colors.red)));
  }

  copyValue(BuildContext context, String label, String v) {
    return () {
      Clipboard.setData(ClipboardData(text: v));
      final snackBar = SnackBar(content: Text('Copied $label to clipboard $v'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    };
  }

  Widget noneState(BuildContext context) {
    return Text('None');
  }

  //Done
  // Widget resultList(BuildContext context) {
  //   return ListView.builder(
  //     itemCount: results.length,
  //     itemBuilder: (_, index) {
  //       final result = results[index];
  //       final textTheme = Theme.of(context).textTheme;
  //       return Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: <Widget>[
  //             GestureDetector(
  //               onLongPress: copyValue(context, 'BSSID', result.bssid),
  //               child: Row(
  //                 children: <Widget>[
  //                   Text('BSSID: ', style: textTheme.bodyText1),
  //                   Text(result.bssid,
  //                       style: TextStyle(fontFamily: 'monospace')),
  //                 ],
  //               ),
  //             ),
  //             GestureDetector(
  //               onLongPress: copyValue(context, 'IP', result.ip),
  //               child: Row(
  //                 children: <Widget>[
  //                   Text('IP: ', style: textTheme.bodyText1),
  //                   Text(result.ip, style: TextStyle(fontFamily: 'monospace')),
  //                 ],
  //               ),
  //             )
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task'),
      ),
      body: Container(
        child: StreamBuilder<ESPTouchResult>(
          builder: (context, AsyncSnapshot<ESPTouchResult> snapshot) {
            if (snapshot.hasError) {
              return error(context, 'Error in StreamBuilder');
            }
            if (!snapshot.hasData) {
              // final primaryColor = Theme.of(context).primaryColor;
              return Center(
                child: Lottie.asset('assets/loading.json'),
              );
            }
            switch (snapshot.connectionState) {
              case ConnectionState.active:
                return Center(
                    child: Lottie.asset('assets/done.json', height: 150));
              case ConnectionState.none:
                return noneState(context);
              case ConnectionState.done:
                return Lottie.asset('assets/done.json');
              case ConnectionState.waiting:
                return waitingState(context);
            }
          },
          stream: stream,
        ),
      ),
    );
  }
}
