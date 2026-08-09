import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/features/notices/config/notice_config.dart';
import 'package:igit_connects/features/notices/models/notice_attachment_model.dart';
import 'package:igit_connects/features/notices/models/notice_model.dart';
import 'package:igit_connects/features/notices/services/notice_service.dart';
import 'package:igit_connects/features/notices/services/notice_storage_service.dart';

class EditNoticeScreen extends StatefulWidget {
  final NoticeModel notice;

  const EditNoticeScreen({
    super.key,
    required this.notice,
  });

  @override
  State<EditNoticeScreen> createState() => _EditNoticeScreenState();
}

class _EditNoticeScreenState extends State<EditNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _urlController;
  late String _selectedCategory;
  late bool _isImportant;

  List<NoticeAttachmentModel> _existingAttachments = [];
  final List<PlatformFile> _newFiles = [];

  bool _isSaving = false;
  final _noticeService = NoticeService();
  final _storageService = NoticeStorageService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notice.title);
    _contentController = TextEditingController(text: widget.notice.content);
    _urlController = TextEditingController(text: widget.notice.externalUrl ?? '');
    _selectedCategory = widget.notice.category;
    _isImportant = widget.notice.isImportant;
    _existingAttachments = List.from(widget.notice.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickNewFiles() async {
    final totalCount = _existingAttachments.length + _newFiles.length;
    if (totalCount >= NoticeConfig.maxNoticeAttachments) {
      CustomSnackBar.show(
        context,
        message: 'Maximum 5 attachments allowed per notice.',
        isError: true,
      );
      return;
    }

    try {
      final files = await _storageService.pickNoticeAttachments();
      if (files.isEmpty) return;

      final validationError = _storageService.validateAttachments(files);
      if (validationError != null) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: validationError,
            isError: true,
          );
        }
        return;
      }

      setState(() {
        for (var file in files) {
          if (_existingAttachments.length + _newFiles.length < NoticeConfig.maxNoticeAttachments) {
            _newFiles.add(file);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error picking files: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteExistingAttachment(NoticeAttachmentModel attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.cardColor,
          title: Text('Delete Attachment', style: TextStyle(color: colors.primaryText)),
          content: Text(
            'Are you sure you want to delete "${attachment.fileName}" from storage?',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: colors.secondaryText)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _noticeService.deleteNoticeAttachment(attachment.id, attachment.filePath);
        setState(() {
          _existingAttachments.removeWhere((a) => a.id == attachment.id);
        });
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Attachment deleted from storage.',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Failed to delete attachment: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Update Notice Text Details
      await _noticeService.updateNotice(
        noticeId: widget.notice.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        isImportant: _isImportant,
        externalUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      );

      // 2. Upload any new file attachments
      if (_newFiles.isNotEmpty) {
        await _noticeService.addNoticeAttachments(
          noticeId: widget.notice.id,
          attachmentFiles: _newFiles,
        );
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Notice updated successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to update notice: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          'Edit Notice',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _isSaving ? null : _saveNotice,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Title Input
              Text(
                'Notice Title',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: 'e.g. End Semester Examination Schedule 2026',
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text(
                'Category',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: NoticeConfig.categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : NoticeConfig.categories.first,
                    isExpanded: true,
                    dropdownColor: colors.cardColor,
                    style: TextStyle(color: colors.primaryText, fontSize: 15),
                    items: NoticeConfig.categories
                        .where((c) => c != 'All')
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notice Content
              Text(
                'Notice Content',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: 'Enter complete notice details here...',
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter notice description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // External URL
              Text(
                'External URL (Optional)',
                style: TextStyle(
                  color: colors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: 'https://example.com/more-info',
                  hintStyle: TextStyle(color: colors.secondaryText),
                  prefixIcon: Icon(Icons.link, color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Important / Urgent Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.priority_high, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Important / Urgent',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Highlights notice with URGENT badge',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isImportant,
                      activeThumbColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() {
                          _isImportant = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Manage Attachments Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attachments (${_existingAttachments.length + _newFiles.length}/${NoticeConfig.maxNoticeAttachments})',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickNewFiles,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: const Text('Add File'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Existing Attachments List
              if (_existingAttachments.isNotEmpty) ...[
                Text(
                  'Existing Storage Attachments:',
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _existingAttachments.length,
                  itemBuilder: (context, index) {
                    final file = _existingAttachments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.fileName,
                                  style: TextStyle(color: colors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${file.fileType.toUpperCase()} • ${file.formattedFileSize}',
                                  style: TextStyle(color: colors.secondaryText, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteExistingAttachment(file),
                            tooltip: 'Delete File',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Newly Picked Attachments List
              if (_newFiles.isNotEmpty) ...[
                Text(
                  'New Attachments to Upload:',
                  style: TextStyle(color: colors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _newFiles.length,
                  itemBuilder: (context, index) {
                    final file = _newFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.primaryAccent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(color: colors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${file.extension?.toUpperCase() ?? 'FILE'} • ${(file.size / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(color: colors.secondaryText, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                _newFiles.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveNotice,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
