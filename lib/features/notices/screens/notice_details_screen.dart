import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/features/notices/models/notice_attachment_model.dart';
import 'package:igit_connects/features/notices/models/notice_model.dart';
import 'package:igit_connects/features/notices/services/notice_service.dart';
import 'package:igit_connects/features/notices/screens/notice_pdf_viewer_screen.dart';
import 'package:igit_connects/features/notices/screens/notice_image_viewer_screen.dart';
import 'package:igit_connects/features/notices/screens/edit_notice_screen.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';

class NoticeDetailsScreen extends ConsumerStatefulWidget {
  final String noticeId;
  const NoticeDetailsScreen({super.key, required this.noticeId});

  @override
  ConsumerState<NoticeDetailsScreen> createState() =>
      _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends ConsumerState<NoticeDetailsScreen> {
  final NoticeService _noticeService = NoticeService();
  late PageController _imagePageController;

  NoticeModel? _notice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _loadNoticeDetails();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadNoticeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notice = await _noticeService.getNoticeById(widget.noticeId);
      if (mounted) {
        setState(() {
          _notice = notice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notice details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAttachment(NoticeAttachmentModel attachment) async {
    final type = attachment.fileType.toLowerCase();
    final name = attachment.fileName.toLowerCase();
    final url = attachment.fileUrl.toLowerCase();

    final isPdf =
        type == 'pdf' ||
        type.contains('pdf') ||
        name.endsWith('.pdf') ||
        url.contains('.pdf');
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].any(
      (ext) =>
          type.contains(ext) || name.endsWith('.$ext') || url.contains('.$ext'),
    );

    // 1. PDF File -> Open In-App PDF Viewer
    if (isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoticePdfViewerScreen(
            pdfUrl: attachment.fileUrl,
            title: attachment.fileName,
          ),
        ),
      );
      return;
    }

    // 2. Image Files -> Open In-App Interactive Image Viewer
    if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoticeImageViewerScreen(
            imageUrl: attachment.fileUrl,
            title: attachment.fileName,
          ),
        ),
      );
      return;
    }

    // 3. Other Documents -> Open via external browser/app launcher
    try {
      final uri = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open file ${attachment.fileName}',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error opening file: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _openExternalLink(String url) async {
    try {
      var formattedUrl = url.trim();
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not launch link: $url',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Invalid link: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _editNotice() async {
    if (_notice == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditNoticeScreen(notice: _notice!)),
    );
    if (updated == true) {
      _loadNoticeDetails();
    }
  }

  Future<void> _deleteNotice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.cardColor,
          title: Text(
            'Delete Notice',
            style: TextStyle(color: colors.primaryText),
          ),
          content: Text(
            'Are you sure you want to delete this notice and all attached files from storage?',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _noticeService.deleteNotice(widget.noticeId);
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Notice and storage attachments deleted successfully.',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Failed to delete notice: $e',
            isError: true,
          );
        }
      }
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Colors.purple;
      case 'zip':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim().toLowerCase();
    final userAsync = ref.watch(userProvider);
    final currentUser = userAsync.value;

    final userId = currentUser?['id']?.toString().trim().toLowerCase();
    final pubId = _notice?.publisherId.trim().toLowerCase();

    final isAuthor =
        _notice != null &&
        ((authUid != null && authUid == pubId) ||
            (userId != null && userId == pubId));

    final isAdmin =
        currentUser != null &&
        (currentUser['role']?.toString().toLowerCase() == 'admin' ||
            currentUser['user_type']?.toString().toLowerCase() == 'admin');

    final isAuthorOrAdmin = isAuthor || isAdmin;

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0.5,
        title: Text(
          'Notice Details',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          if (isAuthorOrAdmin) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colors.primaryAccent),
              onPressed: _editNotice,
              tooltip: 'Edit Notice',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteNotice,
              tooltip: 'Delete Notice',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primaryAccent),
            )
          : _errorMessage != null || _notice == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? 'Notice not found',
                      style: TextStyle(color: colors.primaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SENDER / PUBLISHER DETAILS
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.borderColor,
                          backgroundImage:
                              _notice!.publisherPhotoUrl != null &&
                                  _notice!.publisherPhotoUrl!.isNotEmpty
                              ? NetworkImage(_notice!.publisherPhotoUrl!)
                              : null,
                          child:
                              _notice!.publisherPhotoUrl == null ||
                                  _notice!.publisherPhotoUrl!.isEmpty
                              ? Icon(Icons.school, color: colors.primaryAccent)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notice!.publisherName ??
                                    'College Administration',
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Designation & User Type Badges
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.primaryAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (_notice!.publisherUserType ?? _notice!.publisherRole ?? 'Publisher').toUpperCase(),
                                      style: TextStyle(
                                        color: colors.primaryAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_notice!.publisherDesignation != null && _notice!.publisherDesignation!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _notice!.publisherDesignation!,
                                        style: TextStyle(
                                          color: colors.secondaryText,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if ((_notice!.publisherDepartment != null && _notice!.publisherDepartment!.isNotEmpty) ||
                                  (_notice!.publisherBranch != null && _notice!.publisherBranch!.isNotEmpty)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _notice!.publisherBranch ?? _notice!.publisherDepartment ?? '',
                                  style: TextStyle(
                                    color: colors.secondaryText.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _notice!.formattedDate,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _notice!.formattedTime,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. TITLE & CATEGORY / URGENT BADGES
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.primaryAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _notice!.category.toUpperCase(),
                          style: TextStyle(
                            color: colors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_notice!.isImportant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.priority_high,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'IMPORTANT NOTICE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _notice!.title,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. DESCRIPTION / CONTENT BODY
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: HashtagText(
                      text: _notice!.content,
                      fontSize: 15,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // External Link Button if provided
                  if (_notice!.externalUrl != null &&
                      _notice!.externalUrl!.trim().isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalLink(_notice!.externalUrl!),
                        icon: Icon(
                          Icons.open_in_new,
                          color: colors.primaryAccent,
                        ),
                        label: Text(
                          'Open Related Link / Website',
                          style: TextStyle(
                            color: colors.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.primaryAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. PDF ATTACHMENT BAR
                  if (_notice!.attachments.any(
                    (a) =>
                        a.fileType.toLowerCase().contains('pdf') ||
                        a.fileName.toLowerCase().endsWith('.pdf') ||
                        a.fileUrl.toLowerCase().contains('.pdf'),
                  )) ...[
                    Text(
                      'PDF Documents',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._notice!.attachments
                        .where(
                          (a) =>
                              a.fileType.toLowerCase().contains('pdf') ||
                              a.fileName.toLowerCase().endsWith('.pdf') ||
                              a.fileUrl.toLowerCase().contains('.pdf'),
                        )
                        .map(
                          (pdfAtt) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ListTile(
                              onTap: () => _openAttachment(pdfAtt),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                pdfAtt.fileName,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'PDF Document • ${pdfAtt.formattedFileSize}',
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),
                  ],

                  // 5. SLIDABLE SQUARE IMAGE CAROUSEL SLIDER
                  if (_notice!.attachments.any(
                    (a) => ['jpg', 'jpeg', 'png', 'webp', 'gif'].any(
                      (ext) =>
                          a.fileType.toLowerCase().contains(ext) ||
                          a.fileName.toLowerCase().endsWith('.$ext'),
                    ),
                  )) ...[
                    Builder(
                      builder: (context) {
                        final images = _notice!.attachments
                            .where(
                              (a) => ['jpg', 'jpeg', 'png', 'webp', 'gif'].any(
                                (ext) =>
                                    a.fileType.toLowerCase().contains(ext) ||
                                    a.fileName.toLowerCase().endsWith('.$ext'),
                              ),
                            )
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attached Images (${images.length})',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (images.length == 1) ...[
                              // SINGLE IMAGE: Prominent full-width container taking proper space
                              GestureDetector(
                                onTap: () => _openAttachment(images.first),
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxHeight: 320,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: colors.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colors.borderColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: images.first.fileUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        maxHeightDiskCache: 1200,
                                        placeholder: (ctx, url) => Container(
                                          height: 220,
                                          color: colors.cardColor,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (ctx, url, error) =>
                                            const SizedBox.shrink(),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Full View',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // MULTIPLE IMAGES: Smaller compact horizontal scrollable gallery cards
                              SizedBox(
                                height: 180,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final imgAtt = images[index];
                                    return GestureDetector(
                                      onTap: () => _openAttachment(imgAtt),
                                      child: Container(
                                        width: 180,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          color: colors.cardColor,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: colors.borderColor,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: imgAtt.fileUrl,
                                              fit: BoxFit.cover,
                                              maxHeightDiskCache: 800,
                                              placeholder: (ctx, url) => Container(
                                                color: colors.cardColor,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                              errorWidget: (ctx, url, error) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 36,
                                                  ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${index + 1}/${images.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }
}
