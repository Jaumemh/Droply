import 'package:flutter/material.dart';

/// Stub para plataformas no-web
/// Este widget nunca se usa en plataformas no-web porque
/// usamos Syncfusion PDF Viewer en su lugar
class PdfViewerWeb extends StatelessWidget {
  final String pdfUrl;
  final bool allowDownload;

  const PdfViewerWeb({
    super.key,
    required this.pdfUrl,
    this.allowDownload = false,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('PDF Viewer no disponible'),
    );
  }
}
