import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class PrinterService {
  // Common path for USB printers on Linux/RPi
  static const String _printerPath = '/dev/usb/lp0';

  Future<void> printTicket({
    required String ticketNumber,
    required String office,
    required String patientName,
    required String date,
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text('MedixaLink',
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      bytes += generator.feed(1);

      // Ticket Info
      bytes += generator.text('TURNO', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(ticketNumber,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size3,
            width: PosTextSize.size3,
            bold: true,
          ));
      bytes += generator.feed(1);

      // Location
      bytes += generator.text('Por favor, espere en:', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(office,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
          ));
      bytes += generator.feed(1);

      // Patient
      bytes += generator.text('Paciente: $patientName', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(date, styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
      
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Write to printer file
      final file = File(_printerPath);
      if (await file.exists()) {
        await file.writeAsBytes(bytes);
        print('Ticket printed successfully');
      } else {
        print('Printer not found at $_printerPath');
        throw Exception('Impresora no encontrada en $_printerPath');
      }
    } catch (e) {
      print('Error printing ticket: $e');
      rethrow;
    }
  }
}
