import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kiosk_provider.dart';
import '../services/printer_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _dni = '';
  bool _isLoading = false;

  void _onKeyPress(String val) {
    if (_dni.length < 15) {
      setState(() {
        _dni += val;
      });
    }
  }

  void _onBackspace() {
    if (_dni.isNotEmpty) {
      setState(() {
        _dni = _dni.substring(0, _dni.length - 1);
      });
    }
  }

  Future<void> _onSubmit() async {
    setState(() => _isLoading = true);
    
    try {
      final kiosk = Provider.of<KioskProvider>(context, listen: false);
      final printer = PrinterService();
      final result = await kiosk.performCheckIn(_dni);
      
      final status = result['status'] as String? ?? 'error';
      
      if (status == 'choose_appointment') {
        // Multiple appointments - show selection dialog
        if (mounted) _showAppointmentSelector(result);
      } else if (status == 'already_attended') {
        // Already attended - offer to go to secretary
        if (mounted) _showAlreadyAttendedDialog(result);
      } else if (status == 'see_secretary') {
        // No appointment - show secretary ticket
        try {
          await printer.printTicket(
            ticketNumber: result['ticketNumber']?.toString() ?? 'S-???',
            office: result['office']?.toString() ?? 'Recepción',
            patientName: result['patientName']?.toString() ?? 'Paciente',
            date: result['date']?.toString() ?? DateTime.now().toString(),
          );
        } catch (e) { print("Print failed: $e"); }
        if (mounted) _showSecretaryDialog(result);
      } else if (status == 'success') {
        // Success - print ticket and show confirmation
        try {
          await printer.printTicket(
            ticketNumber: result['ticketNumber']?.toString() ?? 'T-???',
            office: result['office']?.toString() ?? 'Consultorio',
            patientName: result['patientName']?.toString() ?? 'Paciente',
            date: result['date']?.toString() ?? DateTime.now().toString(),
          );
        } catch (e) { print("Print failed: $e"); }
        if (mounted) _showSuccessDialog(result);
      } else {
        throw Exception(result['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 64, color: Colors.green),
        title: const Text('¡Bienvenido!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TURNO: ${result['ticketNumber'] ?? "---"}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(result['office'] ?? 'Espere llamado',
              style: const TextStyle(fontSize: 24, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Text('Dr. ${result['doctorName'] ?? 'Médico de turno'}',
              style: const TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _dni = ''); }, 
            child: const Text('CERRAR', style: TextStyle(fontSize: 20))
          )
        ],
      ),
    );
  }

  void _showSecretaryDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.support_agent, size: 64, color: Colors.orange),
        title: const Text('Diríjase a Recepción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TURNO: ${result['ticketNumber'] ?? "S-???"}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Por favor acérquese al área de recepción.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _dni = ''); }, 
            child: const Text('CERRAR', style: TextStyle(fontSize: 20))
          )
        ],
      ),
    );
  }

  void _showAlreadyAttendedDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 64, color: Colors.blue),
        title: Text('Hola, ${result['patientName'] ?? 'Paciente'}'),
        content: const Text(
          'Ya fue atendido hoy.\n¿Necesita solicitar un nuevo turno?',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _dni = ''); }, 
            child: const Text('CANCELAR')
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Call secretary request
              final kiosk = Provider.of<KioskProvider>(context, listen: false);
              final secretaryResult = await kiosk.requestSecretary(_dni);
              if (mounted) _showSecretaryDialog(secretaryResult);
            }, 
            child: const Text('IR A RECEPCIÓN')
          ),
        ],
      ),
    );
  }

  void _showAppointmentSelector(Map<String, dynamic> result) {
    final appointments = result['appointments'] as List<dynamic>? ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hola, ${result['patientName'] ?? 'Paciente'}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tienes múltiples turnos hoy.\nSelecciona uno:',
                style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ...appointments.map((apt) {
                final time = DateTime.tryParse(apt['time'] ?? '') ?? DateTime.now();
                final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.medical_services, color: Colors.blue),
                    title: Text(apt['doctorName'] ?? 'Médico'),
                    subtitle: Text(apt['specialty'] ?? 'General'),
                    trailing: Text(formattedTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _confirmAppointment(apt['id']);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); setState(() => _dni = ''); }, 
            child: const Text('CANCELAR')
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    setState(() => _isLoading = true);
    try {
      final kiosk = Provider.of<KioskProvider>(context, listen: false);
      final result = await kiosk.confirmAppointment(appointmentId);
      
      if (result['status'] == 'success') {
        final printer = PrinterService();
        try {
          await printer.printTicket(
            ticketNumber: result['ticketNumber']?.toString() ?? 'T-???',
            office: result['office']?.toString() ?? 'Consultorio',
            patientName: result['patientName']?.toString() ?? 'Paciente',
            date: result['date']?.toString() ?? DateTime.now().toString(),
          );
        } catch (e) { print("Print failed: $e"); }
        if (mounted) _showSuccessDialog(result);
      } else {
        throw Exception(result['message'] ?? 'Error al confirmar turno');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildKey(String val) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ElevatedButton(
          onPressed: () => _onKeyPress(val),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildActionKey({required IconData icon, required VoidCallback onTap, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen for global messages (like Test Print results)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kiosk = Provider.of<KioskProvider>(context, listen: false);
      kiosk.messageStream.listen((msg) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(msg), 
               backgroundColor: msg.toLowerCase().contains('error') ? Colors.red : Colors.green
             )
           );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Increased breakpoint for 5-inch screens (often 800px width)
          // Should default to single column if width < 900
          final isSmallScreen = constraints.maxWidth < 900;
          
          return Row(
            children: [
              // Left Side: Hero / Welcome Area (Hidden on very small screens if needed, or smaller flex)
              if (!isSmallScreen)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                       colors: [Color(0xFF006FEE), Color(0xFF004CB4)],
                     )
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50, left: -50,
                        child: Icon(Icons.medical_services, size: 200, color: Colors.white.withOpacity(0.1))
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.health_and_safety, size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'Bienvenido a\nMedixaLink',
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Anúnciese llegada para su turno escaneando su DNI o ingresándolo manualmente.',
                                style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Right Side: Interaction
              Expanded(
                flex: 6,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                             "Ingrese su DNI",
                             style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)
                          ),
                          const SizedBox(height: 10),
                          
                          // Display Area
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _dni.isEmpty ? '________' : _dni,
                                    style: TextStyle(
                                      fontSize: 32, 
                                      fontWeight: FontWeight.bold, 
                                      letterSpacing: 4,
                                      color: _dni.isEmpty ? Colors.grey.shade300 : Colors.black87
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Keypad Grid
                          if (_isLoading)
                            const Expanded(child: Center(child: CircularProgressIndicator()))
                          else ...[
                            Expanded(child: FittedBox(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: ['1', '2', '3'].map(_buildKey).toList()),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: ['4', '5', '6'].map(_buildKey).toList()),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: ['7', '8', '9'].map(_buildKey).toList()),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center, 
                                  children: [
                                       _buildActionKey(
                                         icon: Icons.backspace, 
                                         color: Colors.red, 
                                         onTap: _onBackspace
                                       ),
                                       _buildKey('0'),
                                       _buildActionKey(
                                         icon: Icons.check, 
                                         color: Colors.green, 
                                         onTap: (_dni.length >= 6) ? _onSubmit : () {}
                                       ),
                                  ]
                                ),
                              ],
                            ))),
                          ],

                          const SizedBox(height: 20),

                          // Manual Confirm Button (Smaller height)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_dni.length >= 6 && !_isLoading) ? _onSubmit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('CONFIRMAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
