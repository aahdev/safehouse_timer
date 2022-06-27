import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:vibration/vibration.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:safehouse_timer/user_preferences.dart';
import 'package:safehouse_timer/bottom_sheet_switch.dart';
import 'package:safehouse_timer/colors.dart';

void main() async {
  // Settings
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sebastian Fitzek Safehouse | Timer',
      theme: ThemeData.dark(
          // primarySwatch: Colors.yellow,
          // visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
      home: Timer(title: 'Sebastian Fitzek Safehouse | Timer'),
    );
  }
}

class Timer extends StatefulWidget {
  Timer({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _TimerState createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  /// ****************************************
  /// VARIABLES
  /// ****************************************

  // Settings
  bool setNotifications;
  bool setStayAwake;
  bool setVibration;
  bool setBlack;

  Color bgColor; // Default = Grey

  bool isVibrating = false;

  // Asset Audio Player
  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  final Audio _audio = Audio(
    "assets/audios/safehouse-game.mp3",
    metas: Metas(
        title: "Safehouse",
        artist: "Sebastian Fitzek",
        image: MetasImage.asset('assets/images/safehouse.jpg')
        // image: MetasImage.asset("assets/images/safehouse.jpg"),
        ),
  );
  final Duration audioDelay = new Duration(seconds: 1);

  /// ****************************************
  /// INIT
  /// ****************************************
  @override
  void initState() {
    // Load UserPreferences
    setNotifications = UserPreferences().notifications;
    setStayAwake = UserPreferences().stayAwake;
    setVibration = UserPreferences().vibration;
    setBlack = UserPreferences().blackScreen;

    bgColor = setBlack ? aBlack : aGrey;

    super.initState();

    // Load Audio File
    _open();
  }

  void _open() async {
    await _assetsAudioPlayer.open(
      _audio,
      showNotification: setNotifications,
      // notificationSettings: NotificationSettings(
      //   prevEnabled: false, //disable the previous button
      //   nextEnabled: false,
      //   seekBarEnabled: false,
      // ),
      autoStart: false,
    );
  }

  void _playPause() async {
    _assetsAudioPlayer.playOrPause();
  }

  void _stop() async {
    _assetsAudioPlayer.stop();
  }

  void _settings() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        backgroundColor: bgColor,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 4.0),
                child: Text(
                  "EINSTELLUNGEN",
                  style: TextStyle(
                    fontFamily: 'DCCash',
                    color: aYellow,
                    fontSize: 32,
                  ),
                ),
              ),
              BottomSheetSwitch(
                labelText: "Bildschirm aktiv lassen",
                icon: Icon(Icons.screen_lock_portrait),
                switchValue: setStayAwake,
                valueChanged: (value) {
                  setStayAwake = value;
                  UserPreferences().stayAwake = value;
                },
              ),
              BottomSheetSwitch(
                labelText: "Vibration",
                icon: Icon(Icons.vibration),
                switchValue: setVibration,
                valueChanged: (value) {
                  setVibration = value;
                  UserPreferences().vibration = value;
                },
              ),
              BottomSheetSwitch(
                labelText: "Benachrichtigung",
                icon: Icon(Icons.notifications),
                switchValue: setNotifications,
                valueChanged: (value) {
                  setNotifications = value;
                  UserPreferences().notifications = value;
                },
              ),
              BottomSheetSwitch(
                labelText: "Schwarzer Hintergrund",
                icon: Icon(Icons.lightbulb_outline),
                switchValue: setBlack,
                valueChanged: (value) {
                  setBlack = value;
                  UserPreferences().blackScreen = value;
                  setState(() {
                    bgColor = value ? aBlack : aGrey;
                  });
                },
              ),
              Container(
                height: 20,
              ),
            ],
          );
        });
  }

  void _setWakeLock(bool isPlaying) {
    if (setStayAwake && isPlaying) {
      Wakelock.enable();
      print("Wakelock enabled");
    } else if (setStayAwake && !isPlaying) {
      Wakelock.disable();
      print("Wakelock disabled");
    }
  }

  double _getPercent(Duration timePassed) {
    Duration fixedDuration = new Duration(minutes: 30);

    if (timePassed.inSeconds <= 0) {
      return 1;
    }

    double percent = 1.0 - (timePassed.inSeconds / fixedDuration.inSeconds);

    return percent >= 0 ? percent : 0;
  }

  double _getInnerPercent(Duration timePassed) {
    if (timePassed.inSeconds <= 0) {
      return 1;
    }

    if (timePassed.inSeconds >= 1800) {
      return 0;
    }

    double percent = 1.0 -
        ((timePassed.inSeconds - (timePassed.inSeconds ~/ 120 * 120)) / 120);
    return percent;
  }

  String _printDuration(Duration timePassed) {
    Duration fixedDuration = new Duration(minutes: 30);

    if (timePassed.inSeconds >= 1) {
      fixedDuration = fixedDuration - timePassed + audioDelay;
    }

    if (timePassed.inSeconds >= 1801) {
      return "GAME OVER";
    }

    // Convert in MM:SS
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(fixedDuration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(fixedDuration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _vibrate(Duration elapsedTime) async {
    if (elapsedTime.inSeconds % 120 == 0 &&
        elapsedTime.inMinutes > 0 &&
        setVibration) {
      if (await Vibration.hasVibrator() && !isVibrating) {
        isVibrating = true;
        if (await Vibration.hasCustomVibrationsSupport()) {
          Vibration.vibrate(duration: 2000, amplitude: 255);
        } else {
          Vibration.vibrate();
          await Future.delayed(Duration(milliseconds: 500));
          Vibration.vibrate();
          await Future.delayed(Duration(milliseconds: 500));
          Vibration.vibrate();
          await Future.delayed(Duration(milliseconds: 500));
          Vibration.vibrate();
        }
      }
    } else {
      isVibrating = false;
    }
  }

  @override
  void dispose() {
    _assetsAudioPlayer.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      _settings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Flex(
            direction: orientation == Orientation.portrait
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _assetsAudioPlayer.builderRealtimePlayingInfos(
                builder: (context, infos) {
                  if (infos == null) {
                    return SizedBox();
                  }
                  _vibrate(infos.currentPosition);
                  return Container(
                    child: new CircularPercentIndicator(
                      radius: orientation == Orientation.portrait
                          ? MediaQuery.of(context).size.width - 32
                          : MediaQuery.of(context).size.height - 42,
                      lineWidth: 8.0,
                      animation: true,
                      animateFromLastPercent: true,
                      percent: _getPercent(infos.currentPosition),
                      center: new CircularPercentIndicator(
                        radius: orientation == Orientation.portrait
                            ? MediaQuery.of(context).size.width - 54
                            : MediaQuery.of(context).size.height - 64,
                        lineWidth: 12.0,
                        animation: true,
                        animateFromLastPercent: true,
                        percent: _getInnerPercent(infos.currentPosition),
                        center: new Text(
                          '${_printDuration(infos.currentPosition)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DCCash',
                            color: infos.currentPosition.inSeconds < 1801
                                ? aYellow
                                : Colors.red,
                            fontSize: orientation == Orientation.portrait
                                ? MediaQuery.of(context).size.width / 2.5
                                : MediaQuery.of(context).size.height / 2.75,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ], // Currently not working. Schrift braucht vermutlich die Option Monospace
                          ),
                        ),
                        circularStrokeCap: CircularStrokeCap.butt,
                        progressColor: aYellow,
                        backgroundColor: Colors.blueGrey[900],
                      ),
                      circularStrokeCap: CircularStrokeCap.butt,
                      progressColor: aYellow,
                      backgroundColor: Colors.blueGrey[900],
                    ),
                  );
                },
              ),
              StreamBuilder(
                stream: _assetsAudioPlayer.isPlaying,
                initialData: false,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  _setWakeLock(snapshot.data);
                  return Flex(
                    direction: orientation == Orientation.portrait
                        ? Axis.horizontal
                        : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _playPause,
                        color: aYellow,
                        iconSize: 80,
                        icon: Icon(snapshot.data
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill),
                      ),
                      snapshot.data
                          ? Container()
                          : Container(
                              margin: orientation == Orientation.portrait
                                  ? EdgeInsets.fromLTRB(32, 0, 32, 0)
                                  : EdgeInsets.fromLTRB(0, 32, 0, 32),
                              child: IconButton(
                                icon: Icon(Icons.restore),
                                color: aYellow,
                                iconSize: 50,
                                onPressed: _stop,
                              ),
                            ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.timer,
            ),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Regeln',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Einstellungen',
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.white54,
        selectedItemColor: aYellow,
        onTap: _onItemTapped,
        backgroundColor: bgColor,
      ),
    );
  }
}
