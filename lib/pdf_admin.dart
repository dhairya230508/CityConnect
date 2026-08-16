import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates and triggers layout/download for the Admin PDF Report.
Future<void> generateAdminComplaintPdf({
  required List<QueryDocumentSnapshot> docs,
  required Map<String, String> userCities,
  DateTime? reportFromDate,
  DateTime? reportToDate,
  String reportSelectedCity = 'All Cities',
}) async {
  final pdf = pw.Document();

  String dateRangeText = 'All Time';
  if (reportFromDate != null && reportToDate != null) {
    final fromStr = DateFormat('dd/MM/yyyy').format(reportFromDate);
    final toStr = DateFormat('dd/MM/yyyy').format(reportToDate);
    dateRangeText = '$fromStr to $toStr';
  } else if (reportFromDate != null) {
    final fromStr = DateFormat('dd/MM/yyyy').format(reportFromDate);
    dateRangeText = 'From $fromStr';
  } else if (reportToDate != null) {
    final toStr = DateFormat('dd/MM/yyyy').format(reportToDate);
    dateRangeText = 'Up to $toStr';
  }

  int total = docs.length;
  int pending = 0;
  int inProgress = 0;
  int resolved = 0;

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['ComplaintStatus'] ?? 'Pending').toString();
    if (status == 'Pending') {
      pending++;
    } else if (status == 'In Progress') {
      inProgress++;
    } else if (status == 'Resolved') {
      resolved++;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(
          'CityConnect Admin Report',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
        ),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
        ),
      ),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('1976D2'),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CityConnect Municipal Reports',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'City: $reportSelectedCity | Date Range: $dateRangeText',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Total Complaints', '$total', PdfColor.fromHex('1976D2')),
            _buildStatCard('Pending', '$pending', PdfColor.fromHex('F59E0B')),
            _buildStatCard('In Progress', '$inProgress', PdfColor.fromHex('3B82F6')),
            _buildStatCard('Resolved', '$resolved', PdfColor.fromHex('22C55E')),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
          headerHeight: 25,
          cellHeight: 25,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headers: ['Department', 'Citizen', 'Contact', 'City', 'Status', 'Date'],
          data: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = (data['UserID'] ?? '').toString();
            final city = userCities[userId] ?? (data['City'] ?? 'N/A').toString();

            String dateText = 'N/A';
            if (data['CreatedAt'] != null && data['CreatedAt'] is Timestamp) {
              DateTime date = (data['CreatedAt'] as Timestamp).toDate();
              dateText = DateFormat('dd/MM/yyyy').format(date);
            }

            return [
              (data['ProblemType'] ?? '').toString(),
              (data['Name'] ?? '').toString(),
              (data['Contact'] ?? '').toString(),
              city,
              (data['ComplaintStatus'] ?? 'Pending').toString(),
              dateText,
            ];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'CityConnect_Admin_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
  );
}

pw.Widget _buildStatCard(String label, String value, PdfColor color) {
  return pw.Container(
    width: 100,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color, width: 1),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );
}
