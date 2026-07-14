class ProfanityFilter {
  // A comprehensive list of common English bad words and internet slurs.
  // We use lowercase for the set to enable case-insensitive matching.
  static final Set<String> _badWords = {
    'ass', 'asshole', 'bastard', 'bitch', 'bullshit', 'cock', 'cunt', 'damn',
    'dick',
    'fag',
    'faggot',
    'fuck',
    'fucker',
    'motherfucker',
    'nigga',
    'nigger',
    'pussy', 'shit', 'slut', 'whore',
    // You can easily append local slangs or college-specific terms here later
    'chutiya',
    'madarchod',
    'bhenchod',
    'gandu',
    'bhosadike',
    'laude',
    'bhosdi',
    'luli',
    'lulli',
    'fadu',
    'pipi',
    'muli',
    'mulli',
    'maia',
    'maiya',

    //Odia
    'maghia',
    'bando',
    'banda',
    'chhoda',
    'bia',
    'pela',
    'pelo',
    'rape',
    'randia',
    'randi',
    'behenchod',
    'chuka',
    'bedha',
  };

  /// Checks if the given text contains any profanity.
  /// Returns `true` if bad words are found, `false` otherwise.
  static bool hasProfanity(String text) {
    if (text.trim().isEmpty) return false;

    final normalizedText = text.toLowerCase();

    // Split the text into words (removing punctuation)
    final words = normalizedText
        .replaceAll(RegExp(r'[^\w\s]+'), ' ')
        .split(RegExp(r'\s+'));

    for (final word in words) {
      if (_badWords.contains(word)) {
        return true;
      }
    }

    return false;
  }
}
