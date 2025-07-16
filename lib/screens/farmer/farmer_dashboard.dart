import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 2; // Home tab

  String userName = '';
  String userLocation = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final data = doc.data();
    //print(data);

    if (data != null) {
      setState(() {
        userName = data['name'] ?? 'User';
        userLocation = data['location']?['district'] ?? 'Unknown';
        isLoading = false;
      });
    }
  }

  final List<String> activityFeed = [
    "Your Crop Auction is Live!",
    "Cold Storage booking ends in 2 days",
    "New mandi prices available",
    "Rain forecasted in your region 🌧️",
  ];

  void onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    // TODO: Navigate to corresponding screen based on index
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
                "$userName ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text("Agri18921", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              drawerButton("My Profile", Icons.person),
              drawerButton("My KAM", Icons.support_agent),
              drawerButton("My Wallet", Icons.account_balance_wallet),
              drawerButton("My Orders", Icons.receipt_long),
              drawerButton("Bank Details", Icons.account_balance),
              drawerButton("Terms, Privacy & Policy", Icons.privacy_tip),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        leading: Builder(
          builder:
              (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    //backgroundImage: AssetImage('assets/images/user_placeholder.png'),
                  ),
                ),
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
          SizedBox(width: 16),
          Icon(Icons.settings, color: Colors.white),
          SizedBox(width: 8),
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
                dashboardCard("Post Crop", Icons.agriculture, "/post-crop"),
                dashboardCard(
                  "Book Cold Storage",
                  Icons.ac_unit,
                  '/cold-storage',
                ),
                dashboardCard("Store", Icons.shopping_bag, "/store"),
                dashboardCard(
                  "Check Market Prices",
                  Icons.show_chart,
                  "/market-price",
                ),
                dashboardCard(
                  "My Listings / Auctions",
                  Icons.list_alt,
                  "/my-listings",
                ),
                dashboardCard("Raise Complaint", Icons.report, "/complaints"),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            //color: Colors.green.shade50,
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
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Storage',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget dashboardCard(String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.green.shade700),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawerButton(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // TODO: Navigation / Action
      },
    );
  }
}
