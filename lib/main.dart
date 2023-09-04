import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
//import 'package:get/get.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PermissionStatus btPerm = await Permission.bluetoothScan.request();
  PermissionStatus btPerma = await Permission.bluetooth.request();
  PermissionStatus btPermb = await Permission.location.request();
  PermissionStatus btPermc = await Permission.locationWhenInUse.request();
  PermissionStatus btPermd = await Permission.bluetoothAdvertise.request();

  print('${btPerm}'' - bluetooth');
  print('${btPerma}'' - bluetooth');
  print('${btPermb}'' - location');
  print('${btPermc}'' - location when in use');
  print('${btPermd}'' - advertise bluetooth');

  try {
    await flutterBeacon.initializeAndCheckScanning;
  } 
  on PlatformException catch(e) {
    print(e.message.toString());
  }

  if (btPermc == PermissionStatus.granted) {

    BluetoothEnable.enableBluetooth.then((result) async {
      if (result == "true") {
        await startScanUUID();
        await initializeService();
        runApp(const MyApp());
      } else if (result == "false") {
        print('Bluetooth not enabled');
        runApp(const MyApp());
      }
    });
    
  }

  if (btPermc == PermissionStatus.denied){
    print('permission denied...');
  }
  
}

//check initstate initplatformstate supported or not later, line58 bleedit
Future<void> startScanUUID() async {
  
  StreamSubscription<RangingResult>? _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  Future _scanDevices() async {
    final regions = <Region>[
      Region(
        identifier: 'Contact Trace',
        proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AE0',
      )
    ];

    if (_streamRanging != null) {
      if (_streamRanging!.isPaused) {
        _streamRanging?.resume();
        return;
      }
    }

    _streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) {
      print(result);

      if( result.beacons.isNotEmpty){
        print('Exposed to: ${result.beacons[0].major.toString()}, ${result.beacons[0].minor.toString()}');
      }
      
      _regionBeacons[result.region] = result.beacons;
      _beacons.clear();

      _regionBeacons.values.forEach((list) {
        _beacons.addAll(list);
      });
      
      _beacons.sort(_compareParameters);
    });

    if (_beacons.isNotEmpty){
      print('uuid: ${_beacons[0].proximityUUID.toString()}');
    } else {
      print('not detected');
    }

  }

  await _scanDevices();
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel (
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: IOSInitializationSettings(),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Contact Tracing',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print('iOS - im in background now');

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();
  
  //to uncomment later
  // StreamSubscription<RangingResult>? _streamRanging;
  // final _regionBeacons = <Region, List<Beacon>>{};
  // final _beacons = <Beacon>[];

  // int _compareParameters(Beacon a, Beacon b) {
  //   int compare = a.proximityUUID.compareTo(b.proximityUUID);
  //   print('meow4');
  //   if (compare == 0) {
  //     compare = a.major.compareTo(b.major);
  //   }

  //   if (compare == 0) {
  //     compare = a.minor.compareTo(b.minor);
  //   }

  //   return compare;
  // }
        
  // Future _scanDevices() async {
    
  //   final regions = <Region>[

  //     Region(
  //       identifier: 'Covid-19',
  //       proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AEC',
  //     ),
  //     Region(
  //       identifier: 'Influenza A',
  //       proximityUUID: '6a84c716-0f2a-1ce9-f210-6a63bd873dd9',
  //     ),
  //     Region(
  //       identifier: 'Testing',
  //       proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AED',
  //     ),
  //   ];

  //   if (_streamRanging != null) {
  //     if (_streamRanging!.isPaused) {
  //       _streamRanging?.resume();
  //       print('meowing5');
  //       return;
  //     }
  //   }

  //   print('ilyas start scan');

  //   _streamRanging =
  //       flutterBeacon.ranging(regions).listen((RangingResult result) {
  //     print(result);
      
  //     _regionBeacons[result.region] = result.beacons;
  //     print('meow6');
  //         _beacons.clear();
  //         _regionBeacons.values.forEach((list) {
  //           _beacons.addAll(list);
  //         });
  //         print('meow7');
  //         _beacons.sort(_compareParameters);
  //   });

  //   if (_beacons.isNotEmpty){
  //     print('uuid: ${_beacons[0].proximityUUID.toString()}');
  //   } else {
  //     print('not detected');
  //   }

  //   print('ilyas done scan'); 
  // }

  // print('i am starting scan again and again');
  // _scanDevices();


  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  // bring to foreground
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    print('firing through timer');

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        print('timer firing every 10 sec');

        Future _scanDevices() async {
         print('kedua');
        }
      }

    }
    //to uncomment
    //_scanDevices();
    /// OPTIONAL for use custom notification
    /// the notification id must be equals with AndroidConfiguration when you call configure() method.
    flutterLocalNotificationsPlugin.show (
      888,
      'Contact Tracing',
      'Time: ${DateTime.now()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_foreground',
          'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small',
          ongoing: true,
        ),
      ),
    );

        // if you don't using custom notification, uncomment this
        // service.setForegroundNotificationInfo(
        //   title: "My App Service",
        //   content: "Updated at ${DateTime.now()}",
        // );
      
  });

    /// you can see this log in logcat
  print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

  // test using external plugin
  final deviceInfo = DeviceInfoPlugin();
  String? device;
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    device = androidInfo.model;
  }

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    device = iosInfo.model;
  }

  service.invoke(
    'update',
    {
      "current_date": DateTime.now().toIso8601String(),
      "device": device,
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  // Future _scanDevices() async {
  //   print("scan started");
  //   flutterBlue.startScan(timeout: const Duration(seconds: 4));

  //   var subscription = flutterBlue.scanResults.listen((results) {
  //       // do something with scan results
  //       for (ScanResult r in results) {
  //           print('${r.advertisementData.serviceUuids.toString()} found!');
  //       }
  //   });
  //   flutterBlue.stopScan();
  // }
  
  String text = "Stop Service";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Service App'),
        ),
        body: Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: FlutterBackgroundService().on('update'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!;
                String? device = data["device"];
                DateTime? date = DateTime.tryParse(data["current_date"]);
                return Column(
                  children: [
                    Text(device ?? 'Unknown'),
                    Text(date.toString()),
                  ],
                );
              },
            ),
            ElevatedButton(
              child: const Text("Foreground Mode"),
              onPressed: () {
                FlutterBackgroundService().invoke("setAsForeground");
              },
            ),
            ElevatedButton(
              child: const Text("Background Mode"),
              onPressed: () {
                FlutterBackgroundService().invoke("setAsBackground");
              },
            ),
            ElevatedButton(
              child: const Text("Scan Bluetooth"),
              onPressed: () {
                //_scanDevices();
              },
            ),
            ElevatedButton(
              child: Text(text),
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isRunning();
                if (isRunning) {
                  service.invoke("stopService");
                } else {
                  service.startService();
                }

                if (!isRunning) {
                  text = 'Stop Service';
                } else {
                  text = 'Start Service';
                }
                setState(() {});
              },
            ),
            const Expanded(
              child: LogView(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.play_arrow),
        ),
      ),
    );
  }
}

class LogView extends StatefulWidget {
  const LogView({Key? key}) : super(key: key);

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final Timer timer;
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.reload();
      print('sharedpreferences stuff');
      logs = sp.getStringList('log') ?? [];
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs.elementAt(index);
        return Text(log);
      },
    );
  }
}
