// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class PdfViewerWeb extends StatefulWidget {
  final String pdfUrl;
  final bool allowDownload;

  const PdfViewerWeb({
    super.key,
    required this.pdfUrl,
    this.allowDownload = false,
  });

  @override
  State<PdfViewerWeb> createState() => _PdfViewerWebState();
}

class _PdfViewerWebState extends State<PdfViewerWeb> {
  late String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement();
        
        // Usar parámetros de URL para ocultar la toolbar del PDF
        // Esto dificulta (pero no previene 100%) la descarga
        final url = widget.allowDownload 
            ? widget.pdfUrl
            : '${widget.pdfUrl}#toolbar=0&navpanes=0&scrollbar=1';
        
        iframe.src = url;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        
        // Configuraciones adicionales
        iframe.allow = 'fullscreen';
        
        // Prevenir clic derecho si no se permite descarga
        if (!widget.allowDownload) {
          iframe.setAttribute('oncontextmenu', 'return false;');
        }
        
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }
}
