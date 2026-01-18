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

      // Call Backend to Check-in
      // We need to implement this method in KioskProvider or direct http here.
      // Let's assume KioskProvider has checkIn
      final result = await kiosk.performCheckIn(_dni);
      
      // Result should contain: { ticket: 'A001', office: 'Consultorio 2', patient: 'Juan Perez', date: '...' }
      
      // Print Ticket
      try {
        await printer.printTicket(
          ticketNumber: result['ticketNumber'],
          office: result['office'],
          patientName: result['patientName'],
          date: result['date'],
        );
      } catch (e) {
        print("Printing failed: $e");
        // Don't block UI success on print fail, but maybe show toast
      }

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle, size: 64, color: Colors.green),
            title: const Text('¡Bienvenido!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Te has anunciado correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  'TURNO: ${result['ticketNumber']}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  result['office'],
                  style: const TextStyle(fontSize: 24, color: Colors.blueGrey),
                ),
                const SizedBox(height: 16),
                const Text('Retira tu ticket impreso.', style: TextStyle(fontSize: 14, color: Colors.grey))
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _dni = '';
                    _isLoading = false;
                  });
                }, 
                child: const Text('CERRAR', style: TextStyle(fontSize: 20))
              )
            ],
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Left Side: Hero / Welcome Area
          Expanded(
            flex: 5,
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
                    child: Icon(Icons.medical_services, size: 300, color: Colors.white.withOpacity(0.1))
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.health_and_safety, size: 60, color: Colors.white),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Bienvenido a\nMedixaLink',
                            style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Anúnciese llegada para su turno escaneando su DNI o ingresándolo manualmente.',
                            style: TextStyle(fontSize: 24, color: Colors.white70, height: 1.5),
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
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                       "Ingrese su DNI",
                       style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 20),
                    
                    // Display Area
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 15, offset: const Offset(0, 5))
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dni.isEmpty ? '________' : _dni,
                            style: TextStyle(
                              fontSize: 40, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 4,
                              color: _dni.isEmpty ? Colors.grey.shade300 : Colors.black87
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Keypad Grid
                    if (_isLoading)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else ...[
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: ['1', '2', '3'].map(_buildKey).toList()),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: ['4', '5', '6'].map(_buildKey).toList()),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: ['7', '8', '9'].map(_buildKey).toList()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                             // Empty placeholder to balance grid or Back button
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

                    const SizedBox(height: 40),

                    // Manual Confirm Button (Optional, since we have check key, but good to have explicit)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: (_dni.length >= 6 && !_isLoading) ? _onSubmit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('CONFIRMAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
