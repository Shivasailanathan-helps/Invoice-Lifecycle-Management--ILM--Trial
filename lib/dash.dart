import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY LOG 📊'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getInvoices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          // --- CALCULATE THE "CHART" DATA ---
          int pendingPayment = 0;
          int pendingFinance = 0;
          int completedToday = 0;

          // Get start of today (Midnight)
          DateTime now = DateTime.now();
          DateTime todayMidnight = DateTime(now.year, now.month, now.day);

          List<DocumentSnapshot> todaysUpdates = [];

          for (var doc in docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            // Check Statuses
            if (data['payment_status'] == 'Pending') pendingPayment++;
            if (data['finance_mail_status'] == 'Pending') pendingFinance++;

            // Check if updated today
            if (data['last_updated'] != null) {
              DateTime updatedTime = (data['last_updated'] as Timestamp).toDate();
              if (updatedTime.isAfter(todayMidnight)) {
                todaysUpdates.add(doc);
                completedToday++;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: THE SUMMARY CARDS (THE CHART) ---
                const Text("LIVE SNAPSHOT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard("Pending Payment", pendingPayment.toString(), Colors.orange),
                    _buildStatCard("Pending Finance", pendingFinance.toString(), Colors.blue),
                    _buildStatCard("Done Today", completedToday.toString(), Colors.green), // <--- NOW USED HERE!
                  ],
                ),
                const SizedBox(height: 20),

                // --- SECTION 2: THE LOG BOOK (Today's Work) ---
                const Text("UPDATED TODAY (THE LOG)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                
                if (todaysUpdates.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Text("No updates yet today.", textAlign: TextAlign.center),
                  )
                else
                  ...todaysUpdates.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime time = (data['last_updated'] as Timestamp).toDate();
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2F1),
                          child: Icon(Icons.history, color: Color(0xFF00A67E)),
                        ),
                        title: Text(data['project_name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "Updated at ${DateFormat('hh:mm a').format(time)}\nStatus: ${data['payment_status'] == 'Pending' ? 'Waiting Payment' : 'Paid'}",
                          style: const TextStyle(height: 1.5),
                        ),
                        trailing: const Icon(Icons.check_circle, color: Color(0xFF00A67E), size: 16),
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15), // Slightly smaller padding to fit 3 cards
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)
            ),
          ],
        ),
      ),
    );
  }
}
