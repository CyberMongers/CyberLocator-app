import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_rocket/services/ws_services.dart';
import 'package:socket_rocket/utils/utils.dart';

class RocketSocket extends StatefulWidget {
  const RocketSocket({super.key});

  @override
  State<RocketSocket> createState() => _RocketSocketState();
}

class _RocketSocketState extends State<RocketSocket> {
  final mapController = MapController();
  LatLng? currentLocation;
  bool? isTransmitting = false;
  WSServices wsServices = WSServices();
  Timer? timer;
  List locationHistory = [];
  String? userId;


  @override
  void initState() {
    setUserId();
    isTransmitting = false;
    // HardCoded roomId
    wsServices.connectRoomSocket(context, "123456");
    Geolocator.isLocationServiceEnabled().then((value) {
      if (!value) {
        Geolocator.requestPermission();
        debugPrint("Requesting Location permission");
      }
    });
    getCurrentLocation();
    super.initState();
  }

  @override
  void dispose() {
    mapController.dispose();
    wsServices.channel.sink.close();
    super.dispose();
  }

  void setUserId() async {
    userId = await getUserId();
    if (userId == null) {
      createUserId();
      userId = await getUserId();
    }
  }

  }

  void getCurrentLocation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation)
        .then((value) {
      setState(() {
        currentLocation = LatLng(value.latitude, value.longitude);
        mapController.move(currentLocation!, 15);
      });
    });
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      setState(() {
        currentLocation = LatLng(position!.latitude, position.longitude);
        mapController.move(currentLocation!, 15);
      });
    });
  }

  void transmitLocation() {
    if (currentLocation != null) {
      debugPrint("Location available");
      locationHistory.add(
          "Latitude: ${currentLocation!.latitude.toString()}, Longitude: ${currentLocation!.longitude.toString()}");
      wsServices.sendMsg(
        userId!,
        currentLocation!.latitude.toString(),
        currentLocation!.longitude.toString(),
      );
    } else {
      debugPrint("Location not available, sending kolkata location temp");
      locationHistory.add("Location not available, sending fake location");
      wsServices.sendMsg(
        userId!,
        "22.5726",
        "88.3639",
      );
    }
  }

  void startTransmitting() {
    // Temporary timer for testing
    debugPrint("Start Transmitting");
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        transmitLocation();
      });
    });
  }

  void stopTransmiting() {
    debugPrint("Stop Transmitting");
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: currentLocation ?? LatLng(22.5726, 88.3639),
                  //   bounds: LatLngBounds(
                  //       LatLng(29, 77.8963), LatLng(29.8659, 77.8963)),
                ),
                nonRotatedChildren: [],
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.kavach.socket_rocket',
                  ),
                  currentLocation == null
                      ? Container()
                      : MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLocation!,
                              width: 80,
                              height: 80,
                              builder: (context) => const Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            height: 200,
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: locationHistory.isEmpty
                ? const Center(
                    child: const Text("No location transmitted yet!"))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: locationHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.wifi_tethering_rounded),
                        title: Text(locationHistory[index].toString()),
                      );
                    },
                  ),
          ),
          const SizedBox(
            height: 10,
          ),
          Card(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(userId == null
                        ? "Retrieving UserId..."
                        : "UserId: $userId"),
                    const Spacer(),
                  ],
                ),
              )),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    child: Text("RoomID: 123456"),
                  )),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    getCurrentLocation();
                    isTransmitting = !isTransmitting!;
                    isTransmitting! ? startTransmitting() : stopTransmiting();
                    locationHistory.add(
                        "------------Transmission ${isTransmitting! ? "Started" : "Stopped"}------------");
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTransmitting! ? Colors.red : Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                child: Text(
                  isTransmitting! ? "Stop Transmitting" : "Start Transmitting",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    )));
  }
}
