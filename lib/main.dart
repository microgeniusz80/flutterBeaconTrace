import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
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

Future<void> startScanUUID() async {

  SharedPreferences preferences = await SharedPreferences.getInstance();
  
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

    _streamRanging = flutterBeacon.ranging(regions).listen((RangingResult result) async {
      //print(result);
      if(result.beacons.isNotEmpty){
        print('Exposed to: ${result.beacons[0].major.toString()}, ${result.beacons[0].minor.toString()}');
        await preferences.setString("nama", result.beacons[0].major.toString());
      }
      
      _regionBeacons[result.region] = result.beacons;
      _beacons.clear();

      _regionBeacons.values.forEach((list) {
        _beacons.addAll(list);
      });
      
      _beacons.sort(_compareParameters);
    });
  }

  await _scanDevices();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Service App'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              child: const Text("show contents"),
              onPressed: () async {
                final SharedPreferences sp = await SharedPreferences.getInstance();
                await sp.reload();
                print ('kandungan sharedPref: ${sp.getString('nama')}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
