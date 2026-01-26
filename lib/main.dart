import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_project_screen.dart';
import 'database_service.dart';
import 'project_detail_screen.dart';
import 'dash.dart'; 
import 'table_view_screen.dart'; 

void main() {
  // OPTIMIZATION: Don't wait for Firebase here! 
  // Run the app immediately so the user sees the UI instantly.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitsolApp());
}

class FitsolApp extends StatelessWidget {
  const FitsolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitsol Invoice Flow',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2342),
          primary: const Color(0xFF1A2342),
          secondary: const Color(0xFF00A67E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2342),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00A67E),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      // OPTIMIZATION: Initialize Firebase in the background while showing a Splash Screen
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // 1. If Error
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Database Connection Error", style: TextStyle(color: Colors.red))),
            );
          }

          // 2. If Connected -> Show the App
          if (snapshot.connectionState == ConnectionState.done) {
            return const HomeScreen();
          }

          // 3. While Loading -> Show Instant Splash Screen
          return Scaffold(
            backgroundColor: const Color(0xFF1A2342), // Fitsol Navy
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Placeholder (or use Image.asset if it loads fast enough)
                  const Icon(Icons.eco, size: 80, color: Colors.white), 
                  const SizedBox(height: 20),
                  const Text("FITSOL", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Color(0xFF00A67E)), // Green Spinner
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- HOME SCREEN WITH 3 TABS ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProjectListScreen(),
    const TableViewScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF00A67E),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Daily Log'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.table_view), label: 'Master Sheet'), 
        ],
      ),
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProjectScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text("NEW PROJECT"),
            )
          : null,
    );
  }
}

// --- PROJECT LIST SCREEN ---
class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28, 
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(), // Hide if error
            ),
            const SizedBox(width: 10),
            const Text(
              'FITSOL PROJECTS', 
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("No carbon tracked yet.\nStart a new project!", textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final invoices = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              var data = invoices[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF00A67E)),
                  ),
                  title: Text(
                    data['project_name'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2342)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "ID: ${data['employee_id']} • Status: ${data['status']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(
                          docId: invoices[index].id,
                          data: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
