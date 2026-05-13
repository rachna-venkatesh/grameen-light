import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'main.dart';

class MapPage extends StatelessWidget {
  final List<StreetLightPole> poles;
  final Future<void> Function(String poleId, String status, String issue)
  onReportAdded;

  const MapPage({super.key, required this.poles, required this.onReportAdded});

  static const LatLng villageCenter = LatLng(12.9716, 77.5946);

  LatLng getPolePosition(String poleId) {
    switch (poleId) {
      case "Pole 01":
        return const LatLng(12.9716, 77.5946);
      case "Pole 02":
        return const LatLng(12.9720, 77.5950);
      case "Pole 03":
        return const LatLng(12.9711, 77.5941);
      case "Pole 04":
        return const LatLng(12.9708, 77.5952);
      case "Pole 05":
        return const LatLng(12.9724, 77.5942);
      case "Pole 06":
        return const LatLng(12.9719, 77.5936);
      default:
        return villageCenter;
    }
  }

  BitmapDescriptor getMarkerColor(String status) {
    if (status == "Working") {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (status == "Fused") {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (status == "Repairing") {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (status == "Burning in Day") {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    return BitmapDescriptor.defaultMarker;
  }

  String getAiSuggestion(String status) {
    if (status == "Fused") {
      return "AI Suggestion: Possible bulb failure or wiring issue. Repair priority: High.";
    } else if (status == "Repairing") {
      return "AI Suggestion: Technician already assigned. Monitor repair completion.";
    } else if (status == "Burning in Day") {
      return "AI Suggestion: Possible timer/sensor fault causing energy wastage. Repair priority: Medium.";
    } else {
      return "AI Suggestion: Pole is functioning normally. No immediate action required.";
    }
  }

  void openMapReportDialog(BuildContext context, StreetLightPole pole) {
    String status = pole.status;
    final issueController = TextEditingController(text: pole.lastReport);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text("Report ${pole.id}"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getAiSuggestion(status),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: status,
                      dropdownColor: const Color(0xFF161B22),
                      decoration: const InputDecoration(
                        labelText: "Select Status",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Working",
                          child: Text("Working"),
                        ),
                        DropdownMenuItem(value: "Fused", child: Text("Fused")),
                        DropdownMenuItem(
                          value: "Repairing",
                          child: Text("Repairing"),
                        ),
                        DropdownMenuItem(
                          value: "Burning in Day",
                          child: Text("Burning in Day"),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          status = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: issueController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Issue Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff4ecd),
              ),
              onPressed: () {
                final issue = issueController.text.trim().isEmpty
                    ? "No description provided"
                    : issueController.text.trim();

                Navigator.pop(context);
                onReportAdded(pole.id, status, issue);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${pole.id} complaint submitted"),
                    backgroundColor: const Color(0xFFff4ecd),
                  ),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = poles.map((pole) {
      return Marker(
        markerId: MarkerId(pole.id),
        position: getPolePosition(pole.id),
        icon: getMarkerColor(pole.status),
        infoWindow: InfoWindow(title: pole.id, snippet: pole.status),
        onTap: () {
          openMapReportDialog(context, pole);
        },
      );
    }).toSet();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Pole Map",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.map, color: Color(0xFFff4ecd)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFff4ecd).withOpacity(0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: villageCenter,
                  zoom: 16,
                ),
                markers: markers,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Marker colors: Green = Working, Red = Fused, Orange = Repairing, Yellow = Burning in Day.\nTap any marker to report that pole directly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
