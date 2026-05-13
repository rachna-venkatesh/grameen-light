import 'dart:async';
import 'map_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const GrameenLightApp());
}

class GrameenLightApp extends StatelessWidget {
  const GrameenLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grameen Light',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

class StreetLightPole {
  final String id;
  String status;
  String lastReport;
  String updatedAt;

  StreetLightPole({
    required this.id,
    required this.status,
    required this.lastReport,
    this.updatedAt = "Initial data",
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  StreamSubscription<QuerySnapshot>? poleSubscription;

  List<StreetLightPole> poles = [
    StreetLightPole(id: "Pole 01", status: "Working", lastReport: "No issue"),
    StreetLightPole(id: "Pole 02", status: "Working", lastReport: "No issue"),
    StreetLightPole(
      id: "Pole 03",
      status: "Fused",
      lastReport: "Bulb not working",
    ),
    StreetLightPole(
      id: "Pole 04",
      status: "Repairing",
      lastReport: "Assigned to technician",
    ),
    StreetLightPole(id: "Pole 05", status: "Working", lastReport: "No issue"),
    StreetLightPole(
      id: "Pole 06",
      status: "Burning in Day",
      lastReport: "Energy wastage reported",
    ),
  ];

  @override
  void initState() {
    super.initState();
    syncPolesFromFirebase();
  }

  @override
  void dispose() {
    poleSubscription?.cancel();
    super.dispose();
  }

  Future<void> syncPolesFromFirebase() async {
    final poleRef = FirebaseFirestore.instance.collection("poles");

    for (final pole in poles) {
      final doc = await poleRef.doc(pole.id).get();

      if (!doc.exists) {
        await poleRef.doc(pole.id).set({
          "id": pole.id,
          "status": pole.status,
          "lastReport": pole.lastReport,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }
    }

    poleSubscription = poleRef.snapshots().listen((snapshot) {
      if (!mounted) return;

      final loadedPoles = snapshot.docs.map((doc) {
        final data = doc.data();

        return StreetLightPole(
          id: data["id"] ?? doc.id,
          status: data["status"] ?? "Working",
          lastReport: data["lastReport"] ?? "No issue",
          updatedAt: data["updatedAtText"] ?? "Recently updated",
        );
      }).toList();

      loadedPoles.sort((a, b) => a.id.compareTo(b.id));

      setState(() {
        poles = loadedPoles;
      });
    });
  }

  Future<void> addReport(String poleId, String status, String issue) async {
    final complaintId =
        "GL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    setState(() {
      final pole = poles.firstWhere((p) => p.id == poleId);
      pole.status = status;
      pole.lastReport = issue;
    });

    await FirebaseFirestore.instance.collection("complaints").add({
      "complaintId": complaintId,
      "poleId": poleId,
      "status": status,
      "issue": issue,
      "dateTime": DateTime.now().toString().substring(0, 16),
      "createdAt": FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection("poles").doc(poleId).set({
      "id": poleId,
      "status": status,
      "lastReport": issue,
      "updatedAt": FieldValue.serverTimestamp(),
      "updatedAtText": DateTime.now().toString().substring(0, 16),
    }, SetOptions(merge: true));
  }

  int countStatus(String status) {
    return poles.where((pole) => pole.status == status).length;
  }

  Future<void> markPoleAsWorking(String poleId) async {
    setState(() {
      final pole = poles.firstWhere((p) => p.id == poleId);
      pole.status = "Working";
      pole.lastReport = "Issue fixed by repair team";
    });

    await FirebaseFirestore.instance.collection("poles").doc(poleId).set({
      "id": poleId,
      "status": "Working",
      "lastReport": "Issue fixed by repair team",
      "updatedAt": FieldValue.serverTimestamp(),
      "updatedAtText": DateTime.now().toString().substring(0, 16),
    }, SetOptions(merge: true));
  }

  int calculateEnergySaved() {
    final burningCount = countStatus("Burning in Day");

    if (burningCount == 0) return 30;
    if (burningCount == 1) return 25;
    if (burningCount == 2) return 20;
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        poles: poles,
        workingCount: countStatus("Working"),
        fusedCount: countStatus("Fused"),
        repairingCount: countStatus("Repairing"),
        burningDayCount: countStatus("Burning in Day"),
        onReportAdded: addReport,
      ),
      MapPage(poles: poles, onReportAdded: addReport),
      ReportsPage(onPoleFixed: markPoleAsWorking),
      AnalyticsPage(
        workingCount: countStatus("Working"),
        fusedCount: countStatus("Fused"),
        repairingCount: countStatus("Repairing"),
        burningDayCount: countStatus("Burning in Day"),
        energySaved: calculateEnergySaved(),
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            backgroundColor: const Color(0xFF161B22),
            selectedItemColor: const Color(0xFFff4ecd),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
              BottomNavigationBarItem(
                icon: Icon(Icons.report),
                label: "Reports",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: "Analytics",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<StreetLightPole> poles;
  final int workingCount;
  final int fusedCount;
  final int repairingCount;
  final int burningDayCount;
  final Future<void> Function(String poleId, String status, String issue)
  onReportAdded;

  const HomePage({
    super.key,
    required this.poles,
    required this.workingCount,
    required this.fusedCount,
    required this.repairingCount,
    required this.burningDayCount,
    required this.onReportAdded,
  });

  Color getStatusColor(String status) {
    if (status == "Working") return Colors.greenAccent;
    if (status == "Fused") return Colors.redAccent;
    if (status == "Repairing") return Colors.orangeAccent;
    if (status == "Burning in Day") return Colors.cyanAccent;
    return Colors.white54;
  }

  void openReportDialog(BuildContext context, {String? selectedPole}) {
    String poleId = selectedPole ?? poles.first.id;
    String status = "Fused";
    final issueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text("Report Streetlight"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: poleId,
                      dropdownColor: const Color(0xFF161B22),
                      decoration: const InputDecoration(
                        labelText: "Select Pole",
                        border: OutlineInputBorder(),
                      ),
                      items: poles.map((pole) {
                        return DropdownMenuItem(
                          value: pole.id,
                          child: Text(pole.id),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          poleId = value!;
                        });
                      },
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

                onReportAdded(poleId, status, issue);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Complaint submitted successfully"),
                    backgroundColor: Color(0xFFff4ecd),
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
    final energySaved = burningDayCount == 0 ? "24%" : "18%";

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFff4ecd),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Grameen-Light",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff4ecd), Color(0xFF6a5cff)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, size: 42),
                    SizedBox(height: 15),
                    Text(
                      "Smart Village Energy",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Citizen-led streetlight audit for safer villages and reduced energy wastage.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "Streetlight Status",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: buildStatusCard(
                      "Working",
                      "$workingCount",
                      Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: buildStatusCard(
                      "Fused",
                      "$fusedCount",
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: buildStatusCard(
                      "Repairing",
                      "$repairingCount",
                      Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: buildStatusCard(
                      "Energy Saved",
                      energySaved,
                      Colors.cyanAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text(
                "Pole Map",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: poles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final pole = poles[index];
                  final color = getStatusColor(pole.status);

                  return GestureDetector(
                    onTap: () =>
                        openReportDialog(context, selectedPole: pole.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: color),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, color: color, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            pole.id,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pole.status,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: color),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Updated: ${pole.updatedAt}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => openReportDialog(context),
                  icon: const Icon(Icons.add_alert),
                  label: const Text(
                    "Quick Report Streetlight",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff4ecd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatusCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  final Future<void> Function(String poleId) onPoleFixed;

  const ReportsPage({super.key, required this.onPoleFixed});

  Future<void> markAsFixed(String documentId) async {
    await FirebaseFirestore.instance
        .collection("complaints")
        .doc(documentId)
        .update({
          "status": "Fixed",
          "issue": "Repair completed successfully by technician",
          "fixedAt": FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteReport(String documentId) async {
    await FirebaseFirestore.instance
        .collection("complaints")
        .doc(documentId)
        .delete();
  }

  Color getStatusColor(String status) {
    if (status == "Working") return Colors.greenAccent;
    if (status == "Fused") return Colors.redAccent;
    if (status == "Repairing") return Colors.orangeAccent;
    if (status == "Burning in Day") return Colors.yellowAccent;
    if (status == "Fixed") return Colors.greenAccent;
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Repair Tracker",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Track complaints, mark repaired issues as fixed, or remove test reports.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("complaints")
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    "Total Complaints: $count",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFff4ecd),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("complaints")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading reports"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFff4ecd),
                      ),
                    );
                  }

                  final reports = snapshot.data!.docs;

                  if (reports.isEmpty) {
                    return const Center(
                      child: Text(
                        "No complaints yet.\nSubmit a report from Home or Map.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final documentId = reports[index].id;
                      final data =
                          reports[index].data() as Map<String, dynamic>;

                      final status = data["status"] ?? "Unknown";
                      final poleId = data["poleId"] ?? "";
                      final statusColor = getStatusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["complaintId"] ?? "No ID",
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text("Pole: $poleId"),
                            Text("Status: $status"),
                            Text("Issue: ${data["issue"] ?? ""}"),
                            Text(
                              "Reported: ${data["dateTime"] ?? ""}",
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: status == "Fixed"
                                        ? null
                                        : () async {
                                            await markAsFixed(documentId);
                                            onPoleFixed(poleId);

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Complaint fixed. Pole status changed to Working.",
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text("Mark Fixed"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      disabledBackgroundColor: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await deleteReport(documentId);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Report deleted"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Delete"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  final int workingCount;
  final int fusedCount;
  final int repairingCount;
  final int burningDayCount;
  final int energySaved;

  const AnalyticsPage({
    super.key,
    required this.workingCount,
    required this.fusedCount,
    required this.repairingCount,
    required this.burningDayCount,
    required this.energySaved,
  });

  @override
  Widget build(BuildContext context) {
    final total = workingCount + fusedCount + repairingCount + burningDayCount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Energy Analytics",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 25),
            analyticsCard(
              "Total Poles",
              "$total",
              Icons.lightbulb,
              Colors.amberAccent,
            ),
            analyticsCard(
              "Working Lights",
              "$workingCount",
              Icons.check_circle,
              Colors.greenAccent,
            ),
            analyticsCard(
              "Pending Repairs",
              "${fusedCount + repairingCount}",
              Icons.build,
              Colors.orangeAccent,
            ),
            analyticsCard(
              "Daytime Wastage",
              "$burningDayCount",
              Icons.wb_sunny,
              Colors.redAccent,
            ),
            analyticsCard(
              "Energy Saved This Month",
              "$energySaved%",
              Icons.energy_savings_leaf,
              Colors.cyanAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget analyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 18),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 40),

            const CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFFff4ecd),

              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              "Village Citizen",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              user?.email ?? "No Email",

              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 40),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_city, color: Color(0xFFff4ecd)),
                      SizedBox(width: 12),
                      Text(
                        "Smart Village Monitoring",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(Icons.energy_savings_leaf, color: Color(0xFFff4ecd)),
                      SizedBox(width: 12),
                      Text(
                        "Energy Saving Initiative",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFFff4ecd)),
                      SizedBox(width: 12),
                      Text(
                        "Citizen Safety & Repair Tracking",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },

                icon: const Icon(Icons.logout),

                label: const Text("Logout", style: TextStyle(fontSize: 18)),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
