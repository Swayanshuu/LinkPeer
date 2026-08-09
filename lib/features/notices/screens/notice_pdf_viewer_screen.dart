import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticePdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const NoticePdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<NoticePdfViewerScreen> createState() => _NoticePdfViewerScreenState();
}

class _NoticePdfViewerScreenState extends State<NoticePdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.pdfUrl));
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Validate minimum PDF size & magic bytes (%PDF)
        if (bytes.length < 50) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Invalid PDF file downloaded (File empty or corrupt)';
              _isLoading = false;
            });
          }
          return;
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/notice_doc_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes, flush: true);

        if (!await file.exists() || (await file.length()) < 50) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to write PDF file locally.';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to download PDF (HTTP ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading document: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdfToDevice() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getTemporaryDirectory();

      final rawFileName = widget.pdfUrl.split('/').last.split('?').first;
      final fileName = rawFileName.toLowerCase().endsWith('.pdf') ? rawFileName : '$rawFileName.pdf';
      final savedFile = File('${targetDir.path}/$fileName');

      if (_localPath != null) {
        final sourceFile = File(_localPath!);
        await sourceFile.copy(savedFile.path);
      } else {
        final response = await http.get(Uri.parse(widget.pdfUrl));
        await savedFile.writeAsBytes(response.bodyBytes);
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'PDF Downloaded!',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Download failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_localPath != null) {
      await Share.shareXFiles([XFile(_localPath!)], text: widget.title);
    } else {
      await Share.share(widget.pdfUrl, subject: widget.title);
    }
  }

  Future<void> _openPdfInAppBrowser() async {
    try {
      final googleDocsUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.pdfUrl)}';
      final uri = Uri.parse(googleDocsUrl);
      final rawUri = Uri.parse(widget.pdfUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else if (await canLaunchUrl(rawUri)) {
        await launchUrl(rawUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _openExternalPdf();
    }
  }

  Future<void> _openExternalPdf() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not launch external PDF viewer app',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error launching PDF: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          widget.title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: colors.primaryAccent,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.green),
            onPressed: _downloadPdfToDevice,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, color: colors.primaryText),
            onPressed: _openExternalPdf,
            tooltip: 'Open in External App',
          ),
          IconButton(
            icon: Icon(Icons.share, color: colors.primaryText),
            onPressed: _sharePdf,
            tooltip: 'Share Document',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primaryAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Loading PDF in app...',
                    style: TextStyle(color: colors.secondaryText, fontSize: 14),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 56,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.primaryText),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openPdfInAppBrowser,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open In-App Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openExternalPdf,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open External'),
                        ),
                        TextButton.icon(
                          onPressed: _downloadAndLoadPdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Native'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: PDFView(
                    key: ValueKey(_localPath),
                    filePath: _localPath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: _currentPage,
                    fitPolicy: FitPolicy.WIDTH,
                    preventLinkNavigation: false,
                    onRender: (pages) {
                      if (mounted) {
                        setState(() {
                          _totalPages = pages ?? 0;
                        });
                      }
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      _pdfViewController = pdfViewController;
                    },
                    onPageChanged: (int? page, int? total) {
                      if (page != null && mounted) {
                        setState(() {
                          _currentPage = page;
                        });
                      }
                    },
                    onError: (error) {
                      if (mounted) {
                        setState(() {
                          _errorMessage = 'Native PDF Viewer plugin not ready ($error).\n\nPlease perform a full app restart (re-run `flutter run`) or open in external viewer.';
                        });
                      }
                    },
                    onPageError: (page, error) {
                      debugPrint('Page $page error: $error');
                    },
                  ),
                ),
                if (_totalPages > 0)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Page ${_currentPage + 1} of $_totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
