import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:iconstruct/features/project_creation/data/bom_export.dart';

/// Renders a bill of materials as a canvass sheet a builder can hand to a
/// hardware shop — as a PDF, as images for chat apps, or straight to a printer.
class BomExportService {
  BomExportService._();

  static const PdfColor _navy = PdfColor.fromInt(0xFF2C3E50);
  static const PdfColor _cream = PdfColor.fromInt(0xFFEDE4D4);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1E3042);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5A6E7E);
  static const PdfColor _line = PdfColor.fromInt(0xFFBFC8D2);

  static Future<Uint8List> buildPdf(BomExportData data) async {
    final doc = pw.Document(
      title: '${data.estimateName} — Material Canvass Sheet',
      author: 'iConstruct',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        header: (context) =>
            context.pageNumber == 1 ? _header(data) : _continuedHeader(data),
        footer: _footer,
        build: (context) => [
          _summary(data),
          pw.SizedBox(height: 16),
          _materialsTable(data),
          pw.SizedBox(height: 18),
          _shopBlock(data),
        ],
      ),
    );

    return doc.save();
  }

  /// Opens the system share sheet with the canvass sheet as a PDF.
  static Future<void> sharePdf(BomExportData data) async {
    final bytes = await buildPdf(data);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: '${data.fileBaseName}.pdf',
        ),
      ],
      subject: '${data.estimateName} — material list',
      text: _shareMessage(data),
    );
  }

  /// Shares the sheet as PNG pages, which chat apps preview inline.
  static Future<void> shareImages(BomExportData data) async {
    final bytes = await buildPdf(data);

    final files = <XFile>[];
    var page = 1;
    await for (final raster in Printing.raster(bytes, dpi: 144)) {
      final png = await raster.toPng();
      files.add(
        XFile.fromData(
          png,
          mimeType: 'image/png',
          name: '${data.fileBaseName}-p$page.png',
        ),
      );
      page++;
    }

    if (files.isEmpty) {
      await sharePdf(data);
      return;
    }

    await Share.shareXFiles(
      files,
      subject: '${data.estimateName} — material list',
      text: _shareMessage(data),
    );
  }

  /// Opens the platform print / save-as-PDF preview.
  static Future<void> printSheet(BomExportData data) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPdf(data),
      name: data.fileBaseName,
    );
  }

  static String _shareMessage(BomExportData data) {
    final area = data.areaSqm > 0
        ? ' (${_trimDouble(data.areaSqm)} sq.m)'
        : '';
    return 'Requesting a quotation for ${data.materials.length} materials — '
        '${data.estimateName}$area. Prices and availability are up to you; '
        'please fill in the blank columns.';
  }

  static pw.Widget _header(BomExportData data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const pw.BoxDecoration(color: _navy),
            width: double.infinity,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'iConstruct',
                      style: pw.TextStyle(
                        color: _cream,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Material Canvass Sheet',
                      style: const pw.TextStyle(color: _cream, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Prepared',
                      style: const pw.TextStyle(color: _cream, fontSize: 8),
                    ),
                    pw.Text(
                      _formatDate(data.generatedAt),
                      style: pw.TextStyle(
                        color: _cream,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            pdfSafe(data.estimateName),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _continuedHeader(BomExportData data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pdfSafe(data.estimateName),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            'Material Canvass Sheet · continued',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Generated by iConstruct. Prices are set by the hardware shop; '
              'no payment is processed in the app.',
              style: const pw.TextStyle(fontSize: 7.5, color: _muted),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summary(BomExportData data) {
    final entries = <List<String>>[
      ['Renovation type', data.renovationType.isEmpty ? '-' : data.renovationType],
      [
        'Project area',
        data.areaSqm > 0 ? '${_trimDouble(data.areaSqm)} sq.m' : 'Not set',
      ],
      ['Materials', '${data.materials.length} items'],
      [
        'Budget preference',
        (data.budgetPreference ?? '').trim().isEmpty
            ? 'Not set'
            : data.budgetPreference!.trim(),
      ],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            for (final entry in entries)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry[0].toUpperCase(),
                      style: const pw.TextStyle(fontSize: 7, color: _muted),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      pdfSafe(entry[1]),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if ((data.notes ?? '').trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF6F1E7),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              pdfSafe('Notes: ${data.notes!.trim()}'),
              style: const pw.TextStyle(fontSize: 9, color: _ink),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _materialsTable(BomExportData data) {
    const headers = [
      '#',
      'Material',
      'Size',
      'Qty',
      'Unit',
      'Unit Price (PHP)',
      'Amount (PHP)',
    ];

    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _navy),
        children: [
          for (var i = 0; i < headers.length; i++)
            _cell(
              headers[i],
              bold: true,
              color: _cream,
              align: i >= 3 ? pw.TextAlign.center : pw.TextAlign.left,
            ),
        ],
      ),
    ];

    var index = 1;
    data.byCategory.forEach((category, items) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFEAE0),
          ),
          children: [
            _cell(''),
            _cell(category.toUpperCase(), bold: true, size: 8),
            _cell(''),
            _cell(''),
            _cell(''),
            _cell(''),
            _cell(''),
          ],
        ),
      );

      for (final item in items) {
        rows.add(
          pw.TableRow(
            children: [
              _cell('${index++}', align: pw.TextAlign.center, size: 8.5),
              _cell(
                item.name,
                bold: true,
                secondary: item.notes,
              ),
              _cell(item.size ?? '-', size: 8.5),
              _cell(item.quantityLabel, align: pw.TextAlign.center),
              _cell(
                item.unit.isEmpty ? '-' : item.unit,
                align: pw.TextAlign.center,
                size: 8.5,
              ),
              _cell(''),
              _cell(''),
            ],
          ),
        );
      }
    });

    rows.add(
      pw.TableRow(
        children: [
          _cell(''),
          _cell('GRAND TOTAL', bold: true),
          _cell(''),
          _cell(''),
          _cell(''),
          _cell(''),
          _cell(''),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FixedColumnWidth(38),
        4: pw.FixedColumnWidth(40),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.4),
      },
      children: rows,
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    double size = 9.5,
    PdfColor color = _ink,
    pw.TextAlign align = pw.TextAlign.left,
    String? secondary,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: align == pw.TextAlign.center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pdfSafe(text),
            textAlign: align,
            style: pw.TextStyle(
              fontSize: size,
              color: color,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          if (secondary != null && secondary.trim().isNotEmpty) ...[
            pw.SizedBox(height: 1.5),
            pw.Text(
              pdfSafe(secondary.trim()),
              style: const pw.TextStyle(fontSize: 7.5, color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _shopBlock(BomExportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'For the hardware shop',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _blankField('Shop name'),
              _blankField('Contact number'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _blankField('Quotation valid until'),
              _blankField('Estimated delivery / lead time'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'You can also submit this quotation digitally through iConstruct so '
            'the builder can compare it with other shops.',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _blankField(String label) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              height: 0.6,
              width: double.infinity,
              color: _line,
            ),
          ],
        ),
      ),
    );
  }

  /// The built-in PDF fonts only cover Latin-1, so typographic characters that
  /// arrive from AI suggestions or a builder's own notes are folded to ASCII
  /// instead of rendering as blanks.
  static String pdfSafe(String text) {
    const replacements = {
      '\u2014': '-',
      '\u2013': '-',
      '\u2018': "'",
      '\u2019': "'",
      '\u201C': '"',
      '\u201D': '"',
      '\u2026': '...',
      '\u2022': '-',
      '\u00D7': 'x',
      '\u20B1': 'PHP ',
      '\u20AC': 'EUR ',
      '\u2192': '->',
      '\u00A0': ' ',
    };

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final mapped = replacements[char];
      if (mapped != null) {
        buffer.write(mapped);
      } else if (rune <= 0xFF) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
