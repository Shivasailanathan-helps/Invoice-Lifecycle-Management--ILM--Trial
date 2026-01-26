import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // Connection to the "invoices" folder in the cloud
  final CollectionReference invoiceCollection =
      FirebaseFirestore.instance.collection('invoices');

  // --- 1. SAVE DATA (Create) ---
  Future<void> addInvoice({
    required String projectName,
    required String employeeId,
    required String status,
  }) async {
    return await invoiceCollection.add({
      'project_name': projectName,
      'employee_id': employeeId,
      'status': status,
      'created_at': FieldValue.serverTimestamp(), // Timestamper
    }).then((value) => print("Invoice Added"))
      .catchError((error) => print("Failed to add invoice: $error"));
  }

  // --- 2. READ DATA (Stream) ---
  Stream<QuerySnapshot> getInvoices() {
    return invoiceCollection.orderBy('created_at', descending: true).snapshots();
  }

  // --- 3. UPDATE DATA (Edit) ---
  Future<void> updateProject(String docId, Map<String, dynamic> newValues) async {
    try {
      newValues['last_updated'] = FieldValue.serverTimestamp();
      await invoiceCollection.doc(docId).update(newValues);
      print("Project Updated Successfully!");
    } catch (e) {
      print("Failed to update project: $e");
    }
  }
}

