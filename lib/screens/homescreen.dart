import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_rocket/constants/snackbar.dart';
import 'package:socket_rocket/services/ws_services.dart';
import 'package:socket_rocket/utils/utils.dart';
import 'package:socket_rocket/widgets/alert_widget.dart';

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
  bool manOutOfBound = false;

  @override
  void initState() {
    setUserId();
    isTransmitting = false;

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

  void getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showSnackBar(context,
            "Location permissions are permanently denied!\nPlease enable them from settings");
      }

      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

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
    // HardCoded roomId
    wsServices.connectRoomSocket(context, "123456");
    // Temporary timer for testing
    debugPrint("Start Transmitting");
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        transmitLocation();
        getCurrentLocation();
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
        backgroundColor: manOutOfBound ? Colors.red : Colors.blue.shade700,
        body: SafeArea(
            child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
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
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            // hardcoded area bounds for ground personal
                            point: LatLng(22.5310, 88.3260),
                            color: Colors.red.withOpacity(0.5),
                            borderColor: Colors.red,
                            borderStrokeWidth: 1,
                            useRadiusInMeter: true,
                            radius: 8000,
                          ),
                        ],
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
                                    Icons.person_pin_circle_rounded,
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
                height: 10,
              ),
              alertBox(manOutOfBound),
              manOutOfBound
                  ? const SizedBox(
                      height: 10,
                    )
                  : Container(),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Scrollbar(
                    radius: const Radius.circular(10),
                    child: ListView(
                      children: [
                        Container(
                          width: double.maxFinite,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          constraints: const BoxConstraints(
                              minHeight: 100, maxHeight: 150),
                          child: locationHistory.isEmpty
                              ? const Center(
                                  child: Text("No location transmitted yet!"))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: locationHistory.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: const Icon(
                                          Icons.wifi_tethering_rounded),
                                      title: Text(
                                          locationHistory[index].toString()),
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 15),
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
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      // cheat code to test out of bound
                                      manOutOfBound = !manOutOfBound;
                                    });
                                  },
                                  child: const Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 15),
                                        child: Center(
                                            child: Text("RoomID: 123456")),
                                      )),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      getCurrentLocation();
                                      isTransmitting = !isTransmitting!;
                                      isTransmitting!
                                          ? startTransmitting()
                                          : stopTransmiting();
                                      locationHistory.add(
                                          "------------Transmission ${isTransmitting! ? "Started" : "Stopped"}------------");
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isTransmitting!
                                        ? Colors.red
                                        : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 15),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                  ),
                                  child: Text(
                                    isTransmitting!
                                        ? "Stop Transmitting"
                                        : "Start Transmitting",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )));
  }
}
