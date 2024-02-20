import 'package:flutter/material.dart';
import 'package:sample_map/screens/parent_view/map_view_page.dart';
import 'package:sample_map/screens/driver_view/update_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bus_alert_outlined),
            title: const Text("Driver"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return const UpdateMap();
              }));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Parent"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return const MapViewPage();
              }));
            },
          )
        ],
      ),
    );
  }
}
