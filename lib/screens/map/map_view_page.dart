import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_directions/google_maps_directions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sample_map/apikey.dart';
import 'package:sample_map/dbend.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  Completer<GoogleMapController> mapController = Completer();

  LatLng parent = const LatLng(11.65564, 75.75274);

  LatLng driver = const LatLng(11.66903, 75.76262);

  DistanceValue? distanceBetween;

  DurationValue? durationValue;

  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }

  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    getDriverLocation();
    setCurrentLocation();
    // getPolyPoints();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("driver"),
        position: driver,
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sample Map"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Stack(children: [
        GoogleMap(
          onMapCreated: onMapCreated,
          markers: markers,
          onCameraMove: (_) {},
          initialCameraPosition: CameraPosition(target: parent, zoom: 11.0),
          polylines: {
            Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 6),
          },
          myLocationEnabled: true,
          compassEnabled: true,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
              alignment: Alignment.topCenter,
              child: InkWell(
                onTap: () {
                  showNotificationWithActions();
                },
                child: Container(
                    height: 60,
                    width: 180,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text('Distance :  ${distanceBetween?.text}'),
                          Text('Duration :  ${durationValue?.text}'),
                        ],
                      ),
                    )),
              )),
        ),
      ]),
    );
  }

  Future getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    String googleAPIKey =googleApiKey;
    // Position currentPosition = await getCurrentLocation();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPIKey,
        PointLatLng(parent.latitude, parent.longitude),
        PointLatLng(driver.latitude, driver.longitude));
    int oldDistance = distanceBetween?.meters ?? 0;
    distanceBetween = await distance(
        parent.latitude, parent.longitude, driver.latitude, driver.longitude,
        googleAPIKey: googleAPIKey);
    int newDistance = distanceBetween!.meters;
    if (oldDistance > 1000 && newDistance < 1000) {
      showNotificationWithActions();
    }
    oldDistance = newDistance;
    durationValue = await duration(
        parent.latitude, parent.longitude, driver.latitude, driver.longitude,
        googleAPIKey: googleAPIKey);
    if (result.points.isNotEmpty) {
      // result.points.clear();
      polylineCoordinates.clear();
      // ignore: avoid_function_literals_in_foreach_calls
      result.points.forEach((PointLatLng point) =>
          polylineCoordinates.add(LatLng(point.latitude, point.longitude)));

      setState(() {});
    }
  }

  getDriverLocation() {
    StreamSubscription _subscription;
    FirebaseApp secondaryApp = Firebase.app(defaultFirebaseAppName);
    DatabaseReference ref = FirebaseDatabase.instanceFor(
            app: secondaryApp,
            databaseURL: dbend)
        .ref('currentlocation')
        .child('1');
    _subscription = ref.onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      driver = LatLng(data?['latitude'], data?['longitude']);
      getPolyPoints();
      setState(() {});
    });
  }

  void setCurrentLocation() async {
    final loc = await getCurrentLocation();

    parent = LatLng(loc.latitude, loc.longitude);
    await getPolyPoints();
    setState(() {});
  }

  Future<Position> getCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
    });
    return await Geolocator.getCurrentPosition();
  }

  Future<void> showNotificationWithActions() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channel_id', 'Channel Name',
            channelDescription: 'Channel Description',
            importance: Importance.max,
            priority: Priority.high,icon: 'launch_background',
            ticker: 'ticker');

    int notification_id = 1;
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails,);

    await flutterLocalNotificationsPlugin.show(
      notification_id,
      'title',
      'value',
      notificationDetails,
      payload: 'Not present',
    );
  }
}
// ndm 11.685675108084403, 75.65532341678826
// kayakk 11.662552060183488, 75.75030561344798
// kkt 11.678103041446448, 75.69987777518847
// mok 11.673940702473077, 75.72808952069701
//11.662074355732592, 75.75092462162493