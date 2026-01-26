import 'package:flutter/material.dart';
import 'database_service.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();

  @override
  void dispose() {
    _projectController.dispose();
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use the brand colors from main.dart automatically!
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        backgroundColor: const Color(0xFF1A2342), // Fitsol Navy
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Project Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2342)),
            ),
            const SizedBox(height: 5),
            const Text("Enter details to track logistics & emissions.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),

            // --- Inputs with Green Focus Color ---
            _buildTextField(_projectController, "Project Name", Icons.business),
            const SizedBox(height: 16),
            _buildTextField(_employeeNameController, "Employee Name", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_employeeIdController, "Employee ID", Icons.badge),
            const SizedBox(height: 40),

            // --- The Fitsol Green Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A67E), // Eco Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: () async {
                  if (_projectController.text.isEmpty || _employeeIdController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in Project Name and ID')),
                    );
                    return;
                  }

                  await DatabaseService().addInvoice(
                    projectName: _projectController.text,
                    employeeId: _employeeIdController.text,
                    status: "Ongoing",
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('START TRACKING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to make text fields look consistent
  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A2342)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00A67E), width: 2), // Green when typing
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
