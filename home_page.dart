import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  // Minimal blue/gray color scheme
  final Color primaryBlue = Color(0xFF2196F3); // Blue 500
  final Color lightBlue = Color(0xFFE3F2FD); // Blue 50
  final Color darkGray = Color(0xFF424242); // Gray 800
  final Color mediumGray = Color(0xFF757575); // Gray 600
  final Color lightGray = Color(0xFFF5F5F5); // Gray 100

  void showAlerts() async {
    QuerySnapshot snapshot = await _db
        .collection("events")
        .orderBy("timestamp", descending: true)
        .limit(10)
        .get();

    final events = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        "time": data["timestamp"]?.toDate() ?? DateTime.now(),
        "image": data["imageUrl"],
        "type": data["type"] ?? "unknown",
      };
    }).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Recent Alerts",
          style: TextStyle(color: darkGray, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: events.isEmpty
              ? Text("No recent alerts", style: TextStyle(color: mediumGray))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: [
                      DataColumn(
                        label: Text("Time", style: TextStyle(color: darkGray, fontWeight: FontWeight.w600)),
                      ),
                      DataColumn(
                        label: Text("Image", style: TextStyle(color: darkGray, fontWeight: FontWeight.w600)),
                      ),
                      DataColumn(
                        label: Text("Face", style: TextStyle(color: darkGray, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    rows: events.map((event) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              event["time"].toString().substring(0, 19),
                              style: TextStyle(fontSize: 12, color: mediumGray),
                            ),
                          ),
                          DataCell(
                            event["image"] != null
                                ? Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(event["image"]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.image_not_supported, color: mediumGray),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  event["type"] == "stranger"
                                      ? Icons.warning
                                      : Icons.verified_user,
                                  color: event["type"] == "stranger"
                                      ? Colors.red.shade400
                                      : Colors.green.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event["type"].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: event["type"] == "stranger"
                                        ? Colors.red.shade400
                                        : Colors.green.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      print("Navigate to Live Feed");
    } else if (index == 1) {
      print("Navigate to Add Faces");
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
      Future.delayed(Duration.zero, () {
        setState(() => _selectedIndex = 0);
      });
    } else if (index == 3) {
      print("Logout user");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: lightGray, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(
                          fontSize: 14,
                          color: mediumGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.username,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.notifications, size: 24),
                      color: primaryBlue,
                      onPressed: showAlerts,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security,
                          size: 48,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "CCTV Monitoring",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "System is active and monitoring",
                        style: TextStyle(
                          fontSize: 16,
                          color: mediumGray,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              "All systems operational",
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: lightGray, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          iconSize: 24,
          selectedItemColor: primaryBlue,
          unselectedItemColor: mediumGray,
          backgroundColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.videocam),
              label: "Live Feed",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.face),
              label: "Add Faces",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: "Logout",
            ),
          ],
        ),
      ),
    );
  }
}