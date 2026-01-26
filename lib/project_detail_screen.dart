import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Helps with Date formatting
import 'database_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ProjectDetailScreen({super.key, required this.docId, required this.data});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // Status Variables
  String? customerInvoiceMIS;
  String? financeMailStatus;
  String? financeInvoiceStatus;
  String? paymentStatus;

  // Date Variables
  DateTime? invoiceSubmittedDate;
  DateTime? expectedPaymentDate;
  DateTime? paymentDate;

  @override
  void initState() {
    super.initState();
    // Load existing data from the previous screen
    // Note: Mapping exact field names from Firestore
    customerInvoiceMIS = widget.data['customer_invoice_mis'] ?? 'Pending';
    financeMailStatus = widget.data['mail_sent_to_finance'] ?? 'Pending';
    financeInvoiceStatus = widget.data['invoice_from_finance'] ?? 'Pending';
    paymentStatus = widget.data['payment_status'] ?? 'Pending';

    // Load Dates (Firestore Timestamps need conversion)
    invoiceSubmittedDate = _toDate(widget.data['invoice_submitted_date']);
    expectedPaymentDate = _toDate(widget.data['expected_payment_date']);
    paymentDate = _toDate(widget.data['payment_date']);
  }

  // Helper to convert Firestore Timestamp to DateTime
  DateTime? _toDate(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  // Helper to pick a date
  Future<void> _pickDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00A67E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }

  // --- THE LOGIC POLICE 👮‍♂️ ---
  bool _validateSequence() {
    // Rule 1: Cannot complete "Mail to Finance" if "Customer Invoice MIS" is Pending
    if (financeMailStatus == 'Completed' && customerInvoiceMIS == 'Pending') {
      _showError("⛔ SEQUENCE ERROR:\nYou must complete 'Customer Invoice MIS' before sending Mail to Finance.");
      return false;
    }

    // Rule 2: Cannot complete "Invoice from Finance" if "Mail to Finance" is Pending
    if (financeInvoiceStatus == 'Completed' && financeMailStatus == 'Pending') {
      _showError("⛔ SEQUENCE ERROR:\nYou must send 'Mail to Finance' before receiving the Invoice.");
      return false;
    }

    // Rule 3: Cannot mark "Payment" as Paid if "Invoice from Finance" is Pending
    if ((paymentStatus == 'Paid' || paymentStatus == 'Completed') && financeInvoiceStatus == 'Pending') {
      _showError("⛔ SEQUENCE ERROR:\nYou cannot receive Payment without the Invoice from Finance!");
      return false;
    }

    return true; // All checks passed
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- SAVE LOGIC ---
  Future<void> _saveChanges() async {
    // 1. Run the Logic Check
    if (!_validateSequence()) return; 

    // 2. Prepare Data
    // Note: Field names match exactly what we used in the Table View
    Map<String, dynamic> updates = {
      'customer_invoice_mis': customerInvoiceMIS,
      'mail_sent_to_finance': financeMailStatus,
      'invoice_from_finance': financeInvoiceStatus,
      'payment_status': paymentStatus, // Stores 'Pending' or 'Paid'
      
      'invoice_submitted_date': invoiceSubmittedDate,
      'expected_payment_date': expectedPaymentDate,
      'payment_date': paymentDate,
      
      // Update overall status automatically
      'status': (paymentStatus == 'Paid' || paymentStatus == 'Completed') ? 'Completed' : 'Ongoing',
      
      // Timestamp for the Daily Log
      'last_updated': FieldValue.serverTimestamp(),
    };

    // 3. Send to Firebase
    await DatabaseService().updateProject(widget.docId, updates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project Updated Successfully! ✅"), backgroundColor: Colors.green)
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['project_name'] ?? 'Project Details'),
        backgroundColor: const Color(0xFF1A2342), // Fitsol Navy
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 30),
            
            // 1. Customer Invoice MIS
            _buildDropdownSection("1. Customer Invoice MIS", customerInvoiceMIS, (val) => customerInvoiceMIS = val),
            
            // 2. Mail Sent to Finance
            _buildDropdownSection("2. Mail Sent to Finance", financeMailStatus, (val) => financeMailStatus = val),
            
            // 3. Invoice Received from Finance
            _buildDropdownSection("3. Invoice Received (Finance)", financeInvoiceStatus, (val) => financeInvoiceStatus = val),

            const Divider(),

            // 4. Invoice Submitted To Customer (Date)
            // This is optional logic: Maybe they only submit after receiving the invoice?
            const Text("Invoice Submission Details", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2342))),
            _buildDateSelector("Date Submitted to Customer", invoiceSubmittedDate, (date) => invoiceSubmittedDate = date),
            
            const SizedBox(height: 10),
            const Text("Expected Payment Date", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2342))),
            _buildDateSelector("Select Expected Date", expectedPaymentDate, (date) => expectedPaymentDate = date),
            
            const Divider(),

            // 5. Payment from Customer
            // Special Dropdown (Pending / Paid)
            _buildPaymentDropdownSection("4. Payment From Customer", paymentStatus, (val) => paymentStatus = val),
            
            // Only show "Payment Date" selector if status is "Paid"
            if (paymentStatus == 'Paid' || paymentStatus == 'Completed')
              _buildDateSelector("Payment Received Date", paymentDate, (date) => paymentDate = date),

            const SizedBox(height: 40),
            
            // UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A67E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveChanges,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("UPDATE PROJECT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS (To keep code clean) ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, size: 40, color: Color(0xFF1A2342)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data['project_name'] ?? 'Untitled', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("ID: ${widget.data['employee_id']}", style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(String title, String? currentValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2342))),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: currentValue,
            items: ['Pending', 'Completed'].map((String val) {
              return DropdownMenuItem(
                value: val, 
                child: Text(
                  val,
                  style: TextStyle(
                    color: val == 'Completed' ? Colors.green[700] : Colors.orange[800],
                    fontWeight: FontWeight.bold
                  ),
                )
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                onChanged(val);
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Special dropdown for Payment (Uses 'Paid' instead of 'Completed')
  Widget _buildPaymentDropdownSection(String title, String? currentValue, Function(String?) onChanged) {
    // Normalize logic: If DB says 'Completed', show as 'Paid'
    String displayValue = (currentValue == 'Completed') ? 'Paid' : (currentValue ?? 'Pending');
    if (displayValue != 'Pending' && displayValue != 'Paid') displayValue = 'Pending'; // Safety fallback

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A2342))),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: displayValue,
            items: ['Pending', 'Paid'].map((String val) {
              return DropdownMenuItem(
                value: val, 
                child: Text(
                  val,
                  style: TextStyle(
                    color: val == 'Paid' ? Colors.green[700] : Colors.orange[800],
                    fontWeight: FontWeight.bold
                  ),
                )
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                onChanged(val);
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? dateValue, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () => _pickDate(context, onPicked),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  dateValue == null ? "Select Date" : DateFormat('dd MMM yyyy').format(dateValue),
                  style: TextStyle(
                    color: dateValue == null ? Colors.grey : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF00A67E)),
          ],
        ),
      ),
    );
  }
}
