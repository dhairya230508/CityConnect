import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


Future<void> generateUserComplaintPdf(List<QueryDocumentSnapshot> docs) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // Filter complaints to ONLY those belonging to current user
  final userDocs = docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return (data['UserID'] ?? '').toString() == currentUser.uid;
  }).toList();

  final pdf = pw.Document();

  int total = userDocs.length;
  int pending = 0;
  int inProgress = 0;
  int resolved = 0;

  for (var doc in userDocs) {
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
          'CityConnect Citizen Portal',
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
                    'My Complaints History',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Account: ${currentUser.email ?? "Citizen"}',
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
            _buildStatCard('Total Submitted', '$total', PdfColor.fromHex('1976D2')),
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
          headers: ['Department', 'Address', 'Status', 'Date Submitted'],
          data: userDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            String dateText = 'N/A';
            if (data['CreatedAt'] != null && data['CreatedAt'] is Timestamp) {
              DateTime date = (data['CreatedAt'] as Timestamp).toDate();
              dateText = DateFormat('dd/MM/yyyy').format(date);
            }

            return [
              (data['ProblemType'] ?? '').toString(),
              (data['Address'] ?? '').toString(),
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
    name: 'My_CityConnect_Complaints_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
