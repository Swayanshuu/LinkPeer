class NoticeConfig {
  /// Maximum attachment size allowed per file (10 MB in bytes)
  static const int maxNoticeFileSize = 10 * 1024 * 1024;

  /// Maximum number of attachments allowed per notice
  static const int maxNoticeAttachments = 5;

  /// Formatted max size text for UI warnings
  static const String maxNoticeFileSizeFormatted = '10 MB';

  /// Standard College Notice categories
  static const List<String> categories = [
    'All',
    'Examination',
    'Academics',
    'Placement',
    'Events',
    'Administrative',
    'General',
  ];

  /// Creation notice categories (without 'All')
  static List<String> get creationCategories =>
      categories.where((c) => c != 'All').toList();
}
