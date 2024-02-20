import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sample_map/dbend.dart';

class UpdateMap extends StatefulWidget {
  const UpdateMap({super.key});

  @override
  State<UpdateMap> createState() => _UpdateMapState();
}

class _UpdateMapState extends State<UpdateMap> {
  Position? currentPosition;
  StreamSubscription<Position>? positioSubscription;
  String? error;
  bool isLoading = false;

  @override
  void dispose() {
    positioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus"),
        centerTitle: true,
      ),
      body: Center(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Text(error?.toString() ?? "")
                : currentPosition == null
                    ? const Text('Turn on location')
                    : Text(
                        "DATA : ${currentPosition?.latitude},${currentPosition?.longitude},\n"
                        "Speed: ${currentPosition?.speed} (Acc: ${currentPosition?.speedAccuracy.toStringAsFixed(2)})\n"
                        "Altitude: ${currentPosition?.altitude} (Acc: ${currentPosition?.altitudeAccuracy.toStringAsFixed(2)})\n"
                        "Floor: ${currentPosition?.floor}\n",
                        textAlign: TextAlign.center,
                      ),
      ),
      bottomSheet: ListTile(
          title: OutlinedButton(
        onPressed: () {
          fetchAndSaveLocation();
        },
        child: const Text("Turn on location"),
      )),
    );
  }

  Future<bool> grandPermission() async {
    final requestResult = await Geolocator.requestPermission();
    if (requestResult.name == 'denied') {
      return false;
    }
    return true;
  }

  Future savePositionToDb() async {
    final url = Uri.https(dbend, "currentlocation/1.json");
    await http.put(
      url,
      headers: {'content-type': 'application/json'},
      body: json.encode(
        {
          'latitude': currentPosition?.latitude,
          'longitude': currentPosition?.longitude,
          'speed': currentPosition?.speed,
          'speedAccuracy': currentPosition?.speedAccuracy
        },
      ),
    );
  }

  listenToPosition() {
    positioSubscription = Geolocator.getPositionStream().listen((event) {
      currentPosition = event;
      setState(() {});
      savePositionToDb();
    })
      ..onError((err) {
        error = err.toString();
        setState(() {});
        positioSubscription?.cancel();
      });
  }

  Future<bool> checkLocationIsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future enablePermission() async {
    return await Geolocator.openLocationSettings();
  }

  fetchAndSaveLocation() async {
    setState(() {
      isLoading = true;
      error = null;
      currentPosition = null;
    });
    final permissionGranded = await grandPermission();
    if (permissionGranded == true) {
      final isEnabled = await checkLocationIsEnabled();
      setState(() {
        isLoading = false;
      });
      if (isEnabled) {
        listenToPosition();
      } else {
        enablePermission();
      }
    } else {
      error = 'Permission denied by user';
      currentPosition = null;
      isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }
}
