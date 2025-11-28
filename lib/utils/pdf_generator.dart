import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'theme_provider.dart';
class PdfGenerator {
  static Future<File> generateInvoice({
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String shipperName,
    required String consigneeName,
    required List<InvoiceLine> lines,
    required double total,
    String currency = '€',
    String logoAssetPath = 'assets/icon/logo.png',
    String? driverName,
    String? driverPhone,
    String? shippingAddress,
    String? shippingCity,
    String? shippingPostalCode,
    String? shippingCountry,
    List<PackageDetail>? packages,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logo;
    try {
      final logoBytes = await rootBundle.load(logoAssetPath);
      logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Could not load logo: $e');
    }
    final pw.Font baseFont = await _loadFontOrDefault('assets/fonts/Roboto-Regular.ttf', isBold: false);
    final pw.Font boldFont = await _loadFontOrDefault('assets/fonts/Roboto-Bold.ttf', isBold: true);
    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(baseFont, boldFont),
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _header(logo, invoiceNumber, invoiceDate),
                pw.SizedBox(height: 12),
                _parties(shipperName, consigneeName),
                pw.SizedBox(height: 12),
                if (shippingAddress != null && driverName != null) ...[
                  _shippingAndDriverRow(
                    shippingAddress,
                    shippingCity,
                    shippingPostalCode,
                    shippingCountry,
                    driverName,
                    driverPhone,
                  ),
                  pw.SizedBox(height: 12),
                ] else ...[
                  if (shippingAddress != null) ...[
                    _shippingInfo(shippingAddress, shippingCity, shippingPostalCode, shippingCountry),
                    pw.SizedBox(height: 12),
                  ],
                  if (driverName != null) ...[
                    _driverInfo(driverName, driverPhone),
                    pw.SizedBox(height: 12),
                  ],
                ],
                if (packages != null && packages.isNotEmpty) ...[
                  _packagesTable(packages),
                  pw.SizedBox(height: 12),
                ],
                _linesTable(lines, currency),
                pw.SizedBox(height: 8),
                _totals(total, currency),
                pw.SizedBox(height: 16),
                _footerCert(),
              ],
            ),
          ),
        ],
      ),
    );
    final dir = await _getDownloadsOrDocs();
    final ts = invoiceDate.toIso8601String().replaceAll(':', '-').split('.')[0];
    final file = File('${dir.path}/invoice_${invoiceNumber}_$ts.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  static pw.PageTheme _buildPageTheme(pw.Font base, pw.Font bold) {
    return pw.PageTheme(
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold,
      ),
      pageFormat: PdfPageFormat.a4,
      buildBackground: (context) => pw.Container(color: PdfColor.fromInt(RydyColors.darkBg.value)),
    );
  }
  static Future<pw.Font> _loadFontOrDefault(String assetPath, {required bool isBold}) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (_) {
      return isBold ? pw.Font.helveticaBold() : pw.Font.helvetica();
    }
  }
  static pw.Widget _header(pw.ImageProvider? logo, String number, DateTime date) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(width: 90, height: 42, child: pw.Image(logo, fit: pw.BoxFit.contain))
        else
          pw.Text('Flytt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(RydyColors.cardBg.value),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('COMMERCIAL INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
              pw.SizedBox(height: 2),
              pw.Text('Invoice No: $number', style: pw.TextStyle(color: PdfColor.fromInt(RydyColors.subText.value), fontSize: 10)),
              pw.Text('Date: ${_formatDate(date)}', style: pw.TextStyle(color: PdfColor.fromInt(RydyColors.subText.value), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
  static pw.Widget _parties(String shipper, String consignee) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(RydyColors.cardBg.value),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5)),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(children: [
            _cell(title: 'Shipper', value: shipper),
            _cell(title: 'Consignee', value: consignee),
          ]),
        ],
      ),
    );
  }
  static pw.Widget _linesTable(List<InvoiceLine> lines, String currency) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(RydyColors.cardBg.value),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5)),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(children: [
            _headerCell('Description'),
            _headerCell('Qty'),
            _headerCell('Unit Price'),
            _headerCell('Subtotal'),
          ]),
          for (int i = 0; i < lines.length; i++)
            pw.TableRow(
              decoration: (i % 2 == 1)
                  ? pw.BoxDecoration(color: PdfColor.fromInt(RydyColors.darkBg.value))
                  : null,
              children: [
                _cell(value: lines[i].description),
                _cell(value: '${lines[i].qty}'),
                _cell(value: _formatCurrency(currency, lines[i].unit)),
                _cell(value: _formatCurrency(currency, lines[i].qty * lines[i].unit)),
              ],
            ),
        ],
      ),
    );
  }
  static pw.Widget _totals(double total, String currency) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.8),
            color: PdfColor.fromInt(RydyColors.cardBg.value),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(children: [
            pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.subText.value))),
            pw.SizedBox(width: 6),
            pw.Text(_formatCurrency(currency, total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
          ]),
        ),
      ],
    );
  }
  static pw.Widget _footerCert() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'I/We certify that the information on this invoice is true and correct and that the contents of this shipment are as stated above.',
        style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(RydyColors.subText.value)),
      ),
    );
  }
  static pw.Widget _cell({String title = '', required String value}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(RydyColors.subText.value)),
            ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value)),
          ),
        ],
      ),
    );
  }
  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromInt(RydyColors.textColor.value)),
      ),
    );
  }
  static Future<Directory> _getDownloadsOrDocs() async {
    if (Platform.isAndroid) {
      try {
        final downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) return downloads;
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      } catch (e) {
        print('Error accessing external storage: $e');
      }
    }
    if (Platform.isIOS) {
      final documents = await getApplicationDocumentsDirectory();
      return documents;
    }
    return await getApplicationDocumentsDirectory();
  }
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  static String _formatCurrency(String currency, double amount) {
    return '$currency${amount.toStringAsFixed(2)}';
  }
  static pw.Widget _shippingInfo(String? address, String? city, String? postalCode, String? country) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(RydyColors.cardBg.value),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Shipping Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
            pw.SizedBox(height: 8),
            if (address != null) pw.Text('Address: $address', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
            if (city != null) pw.Text('City: $city', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
            if (postalCode != null) pw.Text('Postal Code: $postalCode', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
            if (country != null) pw.Text('Country: $country', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
          ],
        ),
      ),
    );
  }
  static pw.Widget _shippingAndDriverRow(
    String address,
    String? city,
    String? postalCode,
    String? country,
    String driverName,
    String? driverPhone,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _shippingInfo(address, city, postalCode, country)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _driverInfo(driverName, driverPhone)),
      ],
    );
  }
  static pw.Widget _driverInfo(String? name, String? phone) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(RydyColors.cardBg.value),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Delivery Driver Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
            pw.SizedBox(height: 8),
            if (name != null) pw.Text('Driver: $name', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
            if (phone != null) pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(RydyColors.textColor.value))),
          ],
        ),
      ),
    );
  }
  static pw.Widget _packagesTable(List<PackageDetail> packages) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(RydyColors.cardBg.value),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text('Package Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(RydyColors.textColor.value))),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(RydyColors.dividerColor.value), width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.8),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2.4),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(RydyColors.darkBg.value)),
                children: [
                  _headerCell('Package #'),
                  _headerCell('Size'),
                  _headerCell('Receiver'),
                  _headerCell('Address'),
                  _headerCell('Weight'),
                ],
              ),
              for (int i = 0; i < packages.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: i % 2 == 0 ? PdfColor.fromInt(RydyColors.cardBg.value) : PdfColor.fromInt(RydyColors.darkBg.value),
                  ),
                  children: [
                    _cell(value: '${i + 1}'),
                    _cell(value: packages[i].size),
                    _cell(value: packages[i].receiverName),
                    _cell(value: packages[i].address),
                    _cell(value: packages[i].weight),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
class PackageDetail {
  final String receiverName;
  final String address;
  final String weight;
  final String size;
  PackageDetail({
    required this.receiverName,
    required this.address,
    required this.weight,
    required this.size,
  });
}
class InvoiceLine {
  final String description;
  final int qty;
  final double unit;
  InvoiceLine({
    required this.description,
    required this.qty,
    required this.unit,
  });
}
