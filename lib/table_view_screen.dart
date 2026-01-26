import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class TableViewScreen extends StatelessWidget {
  const TableViewScreen({super.key});

  // --- 1. Helper for Background Color ---
  Color _getStatusColor(String? status) {
    if (status == 'Completed' || status == 'Paid') {
      return const Color(0xFFC8E6C9); // Light Green
    } else if (status == 'Pending') {
      return const Color(0xFFFFF9C4); // Light Yellow
    } else {
      return Colors.grey[100]!; // Grey for unknown/empty
    }
  }

  // --- 2. Helper for Text Color ---
  Color _getStatusTextColor(String? status) {
    if (status == 'Completed' || status == 'Paid') {
      return const Color(0xFF2E7D32); // Dark Green Text
    } else if (status == 'Pending') {
      return const Color(0xFFF57F17); // Dark Orange Text
    } else {
      return Colors.grey[800]!; // Dark Grey Text
    }
  }

  // --- 3. The "Box" Builder Widget ---
  // This ensures every cell looks exactly the same!
  Widget _buildStatusBox(String? status) {
    String displayStatus = status ?? 'Pending'; // Default to Pending if empty
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(displayStatus),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12), // Subtle border for neatness
      ),
      alignment: Alignment.center,
      child: Text(
        displayStatus,
        style: TextStyle(
          color: _getStatusTextColor(displayStatus),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MASTER SHEET 📑'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getInvoices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF1A2342)), // Fitsol Navy
                headingRowHeight: 60,
                dataRowHeight: 70, // Slightly taller rows for the boxes
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Emp ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  DataColumn(label: Text('Project', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  DataColumn(label: Text('Customer\nInvoice MIS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  DataColumn(label: Text('Mail Sent\nto Finance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  DataColumn(label: Text('Invoice from\nFinance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  DataColumn(label: Text('Payment\nStatus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  DataColumn(label: Text('Last\nUpdated', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                ],
                rows: docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  return DataRow(cells: [
                    // Emp ID
                    DataCell(Text(data['employee_id'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                    
                    // Project Name
                    DataCell(Text(data['project_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),

                    // --- STATUS BOXES (Using the helper!) ---
                    DataCell(_buildStatusBox(data['customer_invoice_mis'])),
                    DataCell(_buildStatusBox(data['mail_sent_to_finance'])),
                    DataCell(_buildStatusBox(data['invoice_from_finance'])),
                    DataCell(_buildStatusBox(data['payment_status'])),

                    // Last Updated Date
                    DataCell(Text(
                      data['last_updated'] != null 
                      ? DateFormat('dd/MM/yy').format((data['last_updated'] as Timestamp).toDate()) 
                      : '-',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
