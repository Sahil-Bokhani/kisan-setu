import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'package:kisansetu/screens/admin/admin.dart';
import 'package:kisansetu/screens/farmer/farmer.dart';
import 'package:kisansetu/screens/trader/trader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ MUST be the very first line
  await Firebase.initializeApp(); // ✅ Must be awaited
  runApp(const MyApp()); // ✅ Your root widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanSetu',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/farmer': (context) => const FarmerDashboard(),
        '/post-crop': (context) => const PostCropScreen(),
        '/cold-storage': (context) => const ColdStorageListScreen(),
        '/store': (context) => const ProductListingScreen(),
        '/market-price': (context) => const MarketPriceScreen(),
        '/my-listings': (context) => const MyListingScreen(),
        '/complaints': (context) => const RaiseComplaintScreen(),
        '/auctionDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AuctionDetailScreen(
            cropId: args['cropId'],
            cropData: args['cropData'],
          );
        },
        '/cart': (context) => const CartScreen(),
        '/Complaints': (context) => const ComplaintsScreen(),
        '/my_complaints': (context) => const MyComplaintsScreen(),

        '/trader': (context) => const TraderDashboard(),
        '/allAuctions': (context) => const AllAuctionsScreen(),
        '/myBids': (context) => const MyBidsScreen(),

        '/admin': (context) => const AdminDashboard(),
        '/UserManagementScreen': (context) => const UserManagementScreen(),
        '/ManageStorageUnit': (context) => const ManageStorageScreen(),
        '/ManageInventory': (context) => const ManageInputInventoryScreen(),
        '/AuctionOversight': (context) => const AuctionOverviewScreen(),
      },
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
