import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TraderDashboard extends StatefulWidget {
  const TraderDashboard({super.key});

  @override
  State<TraderDashboard> createState() => _TraderDashboardState();
}

class _TraderDashboardState extends State<TraderDashboard> {
  int _selectedIndex = 1; // Home as default
  String userName = '';
  String userLocation = '';
  bool isLoading = true;

  final List<String> activityFeed = [
    "Your bid on 'Wheat – Sharbati' is currently highest ✅",
    "3 auctions ending in next 1 hour!",
    "New Mandi Price uploaded for Maize (Junagadh)",
  ];

  @override
  void initState() {
    super.initState();
    fetchTraderData();
  }

  Future<void> fetchTraderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        userName = data['name'] ?? 'Trader';
        userLocation = data['location']?['district'] ?? 'Unknown';
        isLoading = false;
      });
    }
  }

  void onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    // TODO: Implement actual navigation if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(radius: 40),
              const SizedBox(height: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("Trader", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              drawerItem("My Profile", Icons.person),
              drawerItem("My Wallet", Icons.account_balance_wallet),
              drawerItem("My Bids", Icons.gavel),
              drawerItem("Settings", Icons.settings),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const CircleAvatar(),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title:
            isLoading
                ? const Text("Loading...")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $userName",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      userLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
        actions: const [
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                dashboardCard("Live Auctions", Icons.gavel, () {
                  Navigator.pushNamed(context, '/allAuctions');
                }),
                dashboardCard("Cold Storage", Icons.ac_unit, () {
                  Navigator.pushNamed(context, '/cold-storage');
                }),
                dashboardCard("Watchlist", Icons.favorite, () {
                  //Navigator.pushNamed(context, '/watchlist');
                }),
                dashboardCard("My Bids", Icons.history, () {
                  Navigator.pushNamed(context, '/myBids');
                }),
                dashboardCard("Raise Complaint", Icons.report_problem, () {
                  Navigator.pushNamed(context, '/complaints');
                }),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Activity",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    itemCount: activityFeed.length,
                    itemBuilder:
                        (context, index) => Text("• ${activityFeed[index]}"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onTabTapped,
        selectedItemColor: Colors.red[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget dashboardCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.red[700]),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // TODO: Implement drawer navigation
      },
    );
  }
}
