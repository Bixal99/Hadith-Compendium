import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<String> generateHadithPDF({
  String query = '',
  required List<String> hadiths,
  required List<String> sanads,
  required String title,
  required String appName,
  required String credits,
  String? logoPath = 'assets/images/logo.png',
  required String fileName,
  required String savingDirectoryPath,
}) async {
  bool addSanadRow = true;

  // Initialize PDF document
  final pdf = pw.Document();

  // Load Amiri font for Arabic support
  final amiriFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
  final amiriFont = pw.Font.ttf(amiriFontData);

  // Load DejaVuSans font for arrows
  final arrowFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final arrowFont = pw.Font.ttf(arrowFontData);

  // Load logo image if provided
  pw.MemoryImage? logoImage;
  if (logoPath != null) {
    try {
      final logoData = await rootBundle.load(logoPath);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      throw Exception('Error loading logo: $e');
    }
  }

  // Validate input data
  if (hadiths.isEmpty && sanads.isEmpty) {
    throw Exception('Invalid input: Hadith and sanad lists cannot be empty.');
  } else if (hadiths.isEmpty) {
    throw Exception('Invalid input: Hadith list cannot be empty.');
  } else if (sanads.isEmpty) {
    addSanadRow = false;
  }
  if (sanads.isNotEmpty && hadiths.length != sanads.length) {
    throw Exception(
        'Invalid input: Hadith and sanad lists must have equal length');
  }

  // Cover page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Container(
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
          gradient: pw.LinearGradient(
            colors: [PdfColor.fromHex('DCC9A1'), PdfColors.white],
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Image(
                  logoImage,
                  width: 200,
                  height: 200,
                ),
              pw.SizedBox(height: 20),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: amiriFont,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  appName,
                  style: pw.TextStyle(
                    font: amiriFont,
                    fontSize: 18,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Prepare the table data for all hadiths
  final tableData = <List<pw.Widget>>[];

// Add table header
  tableData.add([
    pw.Container(
      color: PdfColor.fromHex("DCC9A1"),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Text(
          addSanadRow ? 'الحديث والسند' : 'الحديث',
          style: pw.TextStyle(
            font: amiriFont,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex("710E1A"),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ),
  ]);

// Add hadith rows (and sanad if enabled)
  for (int i = 0; i < hadiths.length; i++) {
    final sanadWidgets = <pw.Widget>[];
    if (addSanadRow) {
      final sanadNodes = sanads[i].split(',').map((n) => n.trim()).toList();
      for (int j = 0; j < sanadNodes.length; j++) {
        List<pw.Widget> rowChildren = [];

        rowChildren.add(
          pw.Container(
            constraints: const pw.BoxConstraints(maxWidth: 100),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey800, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey100,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Text(
              sanadNodes[j],
              style: pw.TextStyle(font: amiriFont, fontSize: 10),
              textAlign: pw.TextAlign.center,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        );

        if (j < sanadNodes.length - 1) {
          rowChildren.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3, bottom: 3, right: 10),
              child: pw.Text(
                '←',
                style: pw.TextStyle(
                  font: arrowFont,
                  fontSize: 14,
                  color: PdfColor.fromHex("710E1A"),
                ),
              ),
            ),
          );
        }

        sanadWidgets.add(
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: rowChildren,
            ),
          ),
        );
      }
    }

    // Hadith row
    tableData.add([
      pw.ConstrainedBox(
        constraints: const pw.BoxConstraints(maxHeight: 100),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              hadiths[i],
              style:
                  pw.TextStyle(font: amiriFont, fontSize: 11, lineSpacing: 2),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ),
      ),
    ]);

    if (addSanadRow) {
      tableData.add([
        pw.ConstrainedBox(
          constraints: const pw.BoxConstraints(maxHeight: 100),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Wrap(
                direction: pw.Axis.horizontal,
                spacing: 8,
                runSpacing: 8,
                children: sanadWidgets,
                alignment: pw.WrapAlignment.start,
              ),
            ),
          ),
        ),
      ]);
    }
  }

// Helper function for header
  pw.Widget buildHeader(pw.Context context, String appName, pw.Font amiriFont) {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          children: [
            pw.Text(
              appName,
              style: pw.TextStyle(
                font: amiriFont,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.right,
            ),
            pw.Container(
              height: 1,
              color: PdfColor.fromHex('DCC9A1'),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
            ),
          ],
        ),
      ),
    );
  }

// Helper function for footer
  pw.Widget buildFooter(pw.Context context, pw.Font amiriFont) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: pw.TextStyle(
            font: amiriFont,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  // Add content pages
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),
      header: (pw.Context context) => buildHeader(context, appName, amiriFont),
      footer: (pw.Context context) => buildFooter(context, amiriFont),
      build: (pw.Context context) {
        return [
          if (query.isNotEmpty) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "يبحث",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: amiriFont,
                    color: PdfColor.fromHex("710E1A"),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex("FFFCF1"),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    query,
                    style: pw.TextStyle(
                      fontSize: 15,
                      font: amiriFont,
                      color: PdfColors.grey900,
                      fontStyle: pw.FontStyle.italic,
                      letterSpacing: 0.8,
                      lineSpacing: 1.5,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  height: 2,
                  width: 100,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('D6C091'),
                        PdfColor.fromHex('DCC9A1')
                      ],
                      begin: pw.Alignment.centerLeft,
                      end: pw.Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(
                color: PdfColor.fromHex('DCC9A1'),
                thickness: 1,
                indent: 20,
                endIndent: 20),
          ],

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            defaultColumnWidth: const pw.FlexColumnWidth(1),
            children: [
              for (int i = 0; i < tableData.length; i++)
                pw.TableRow(
                  decoration: i % 2 == 0
                      ? const pw.BoxDecoration(color: PdfColors.white)
                      : pw.BoxDecoration(color: PdfColor.fromHex("FFFCF1")),
                  children: tableData[i],
                ),
            ],
          ),
        ];
      },
    ),
  );

  // Credits page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Container(
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          gradient: pw.LinearGradient(
            colors: [PdfColors.white, PdfColor.fromHex('DCC9A1')],
            begin: pw.Alignment.topCenter,
            end: pw.Alignment.bottomCenter,
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'شكر وتقدير',
                  style: pw.TextStyle(
                    font: amiriFont,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  credits,
                  style: pw.TextStyle(
                    font: amiriFont,
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'حقوق الطبع والنشر 2025',
                  style: pw.TextStyle(
                    font: amiriFont,
                    fontSize: 12,
                    color: PdfColors.grey500,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Save PDF
  final outputFile = File('$savingDirectoryPath/$fileName.pdf');
  await outputFile.writeAsBytes(await pdf.save());
  return outputFile.path;
}
