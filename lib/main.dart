import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'dart:math';


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
        await flutterBeacon.initializeScanning;
        //await broadcastUUID();
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

class DataController extends GetxController{
  String? selfmajor;
  String? selfminor;

  DataController(){
    selfmajor = random(1, 65535).toString();
    selfminor = random(1, 65535).toString();
  }

  String _status = '';
  String get status => _status;
  set status (String data){
    _status = data;
    update();
  }

  String _major = '';
  String get major => _major;
  set major (String data){
    _major = data;
    update();
  }

  String _minor = '';
  String get minor => _minor;
  set minor (String data){
    _minor = data;
    update();
  }

  String _disease = '';
  String get disease => _disease;
  set disease (String data){
    _disease = data;
    update();
  }

  String _infection = '';
  String get infection => _infection;
  set infection (String data){
    _infection = data;
    update();
  }

  int random(int min, int max) {
    return min + Random().nextInt(max - min);
  }

}

Future<void> broadcastUUID() async {

  //await flutterBeacon.initializeScanning;
  bool isBroadcasting = await flutterBeacon.isBroadcasting();

  const covid = 'CB10023F-A318-3394-4199-A8730C7C1AE0';
  // const influenza = 'CB10023F-A318-3394-4199-A8730C7C1001';
  // const chickenpox = 'CB10023F-A318-3394-4199-A8730C7C1002';
  // const healthy = 'CB10023F-A318-3394-4199-A8730C7C1AEC';

  int random(int min, int max) {
    return min + Random().nextInt(max - min);
  }

  var uuidController = covid;
  var majorController = random(1, 65535).toString();
  var minorController = random(1, 65535).toString();

  print('broadcasting ke: ${isBroadcasting}');

  if (isBroadcasting) {
    await flutterBeacon.stopBroadcast();
    Timer(const Duration(seconds: 3), () async {
      await flutterBeacon.startBroadcast(BeaconBroadcast(
        proximityUUID: uuidController,
        major: int.tryParse(majorController) ?? 0,
        minor: int.tryParse(minorController) ?? 0,
      ));
    });
  } else {
    await flutterBeacon.startBroadcast(BeaconBroadcast(
      proximityUUID: uuidController,
      major: int.tryParse(majorController) ?? 0,
      minor: int.tryParse(minorController) ?? 0,
    ));
  }

}

Future<void> startScanUUID() async {

  SharedPreferences preferences = await SharedPreferences.getInstance();
  DataController controller = Get.put(DataController());
  controller.major = 'empty';
  
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
        controller.major = result.beacons[0].major.toString();
        controller.minor = result.beacons[0].minor.toString();
        controller.disease = result.beacons[0].proximityUUID.toString();
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
  bool broadcasting = false;

  //DataController controller = Get.find();
  DataController controller = Get.find();

  final covid = 'CB10023F-A318-3394-4199-A8730C7C1AE0';
  // const influenza = 'CB10023F-A318-3394-4199-A8730C7C1001';
  // const chickenpox = 'CB10023F-A318-3394-4199-A8730C7C1002';
  // const healthy = 'CB10023F-A318-3394-4199-A8730C7C1AEC';

  final uuidController = 'CB10023F-A318-3394-4199-A8730C7C1AE0';

  @override
  Widget build(BuildContext context) {

    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      onPrimary: Colors.white,
      primary: broadcasting ? Colors.red : Theme.of(context).primaryColor,
      minimumSize: Size(88, 36),
      padding: EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Contact Tracing'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final SharedPreferences sp = await SharedPreferences.getInstance();
                await sp.reload();
                controller.major = sp.getString('nama').toString();
                controller.minor = '-';
                // print ('kandungan sharedPref: ${sp.getString('nama')}');
                // print('Major: ${controller.major.toString()}');
              },
              child: const Text('Reset Exposure'),
            ),
            GetBuilder<DataController>(
              builder: (controller) {
                return Text('Exposed to: ${controller.major.toString()}, ${controller.minor.toString()}');
              }
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                if (broadcasting) {
                  await flutterBeacon.stopBroadcast();
                } else {
                  await flutterBeacon.startBroadcast(BeaconBroadcast(
                    proximityUUID: uuidController,
                    major: int.tryParse(controller.selfmajor.toString()) ?? 0,
                    minor: int.tryParse(controller.selfminor.toString()) ?? 0,
                  ));
                }

                final isBroadcasting = await flutterBeacon.isBroadcasting();

                if (mounted) {
                  setState(() {
                    broadcasting = isBroadcasting;
                  });
                }
              },
              child: Text('${broadcasting ? '(INFECTED) - Click to be healthy' : '(HEALTHY) - click to be infected with covid'}'),
            )
          ],
        ),
      ),
    );
  }
}
