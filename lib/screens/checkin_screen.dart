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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _onKeyPress(val),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: Text(val, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left: Info / Welcome
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 120, color: Colors.white),
                  SizedBox(height: 40),
                  Text(
                    'Bienvenido',
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Por favor, ingrese su DNI para anunciarse al profesional.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.white70, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right: Numpad
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade50,
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4)
                         )
                      ]
                    ),
                    child: Text(
                      _dni.isEmpty ? 'Ingrese DNI' : _dni,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 56, 
                        letterSpacing: 6,
                        color: _dni.isEmpty ? Colors.grey.shade400 : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Keypad
                  Expanded(
                     child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                      children: [
                        Expanded(child: Row(children: ['1', '2', '3'].map(_buildKey).toList())),
                        Expanded(child: Row(children: ['4', '5', '6'].map(_buildKey).toList())),
                        Expanded(child: Row(children: ['7', '8', '9'].map(_buildKey).toList())),
                        Expanded(child: Row(children: [
                             const Expanded(child: SizedBox()), // Empty
                             _buildKey('0'),
                             Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton(
                               onPressed: _onBackspace,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.red.shade50,
                                 foregroundColor: Colors.red,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                                 padding: const EdgeInsets.symmetric(vertical: 24)
                               ),
                               child: const Icon(Icons.backspace_outlined, size: 32),
                             ))),
                        ])),
                      ],
                    ),
                  ),
                   const SizedBox(height: 30),
                   SizedBox(
                     height: 90,
                     child: ElevatedButton(
                       onPressed: _dni.length >= 6 && !_isLoading ? _onSubmit : null,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF006FEE),
                         foregroundColor: Colors.white,
                         elevation: 4,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                       ),
                       child: const Text('CONFIRMAR LLEGADA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                     ),
                   )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
