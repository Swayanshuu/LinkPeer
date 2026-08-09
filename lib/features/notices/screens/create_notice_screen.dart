import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/shared_components/app_dropdown_field.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/features/notices/config/notice_config.dart';
import 'package:igit_connects/features/notices/services/notice_service.dart';
import 'package:igit_connects/features/notices/services/notice_storage_service.dart';

class CreateNoticeScreen extends ConsumerStatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  ConsumerState<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends ConsumerState<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isImportant = false;
  List<PlatformFile> _selectedFiles = [];
  bool _isPublishing = false;

  final NoticeService _noticeService = NoticeService();
  final NoticeStorageService _storageService = NoticeStorageService();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final remainingSlots =
        NoticeConfig.maxNoticeAttachments - _selectedFiles.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum ${NoticeConfig.maxNoticeAttachments} attachments allowed per notice.',
          ),
        ),
      );
      return;
    }

    final pickedFiles = await _storageService.pickNoticeAttachments();
    if (pickedFiles.isEmpty) return;

    final combinedList = [..._selectedFiles, ...pickedFiles];

    final validationError = _storageService.validateAttachments(combinedList);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedFiles = combinedList;
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _publishNotice() async {
    if (!_formKey.currentState!.validate()) return;

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final user =
        ref.read(userProvider).value ?? ref.read(userProvider).asData?.value;
    final publisherId = user?['id']?.toString() ?? authUid;

    if (publisherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session invalid. Please log in again.'),
        ),
      );
      return;
    }

    final validationError = _storageService.validateAttachments(_selectedFiles);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      await _noticeService.createNotice(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        publisherId: publisherId,
        isImportant: _isImportant,
        externalUrl: _urlController.text.trim(),
        attachmentFiles: _selectedFiles,
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'College notice published successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to publish notice: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0.5,
        title: Text(
          'Create College Notice',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      body: _isPublishing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primaryAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Publishing Notice & Uploading Attachments...',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please do not close this screen',
                    style: TextStyle(color: colors.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    Text(
                      'Notice Title',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'e.g. End Semester Examination Schedule 2026',
                        hintStyle: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: colors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Notice title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    AppDropdownFormField<String>(
                      value: _selectedCategory,
                      label: 'Notice Category',
                      icon: Icons.category_outlined,
                      items: NoticeConfig.creationCategories,
                      onChanged: (newCat) {
                        if (newCat != null) {
                          setState(() {
                            _selectedCategory = newCat;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content Field
                    Text(
                      'Notice Content',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contentController,
                      style: TextStyle(color: colors.primaryText),
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Enter full announcement text, instructions, and details...',
                        hintStyle: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: colors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Notice content is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // External Link Field (Optional)
                    Text(
                      'External Link / Form URL (Optional)',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _urlController,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'https://college.edu/registration-link',
                        hintStyle: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.link,
                          color: colors.secondaryText,
                        ),
                        filled: true,
                        fillColor: colors.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mark as Important Checkbox
                    Container(
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isImportant
                              ? Colors.redAccent
                              : colors.borderColor,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _isImportant,
                        onChanged: (val) {
                          setState(() {
                            _isImportant = val == true;
                          });
                        },
                        activeColor: Colors.redAccent,
                        title: const Text(
                          'Mark as Important / Urgent Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Highlights this notice with an urgent tag on the Notice Board',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Attachments Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attachments',
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Max size: ${NoticeConfig.maxNoticeFileSizeFormatted} per file • Max ${NoticeConfig.maxNoticeAttachments} files',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _selectedFiles.length <
                                  NoticeConfig.maxNoticeAttachments
                              ? _pickAttachments
                              : null,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Add File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryAccent,
                            side: BorderSide(color: colors.primaryAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Attached Files List
                    if (_selectedFiles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'No file attached yet. PDF, DOCX, XLSX, Images, ZIP etc. supported.',
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.insert_drive_file,
                                color: colors.primaryAccent,
                              ),
                              title: Text(
                                file.name,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatSize(file.size),
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _removeAttachment(index),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _publishNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Publish College Notice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
