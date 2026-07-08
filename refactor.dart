import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final Map<String, String> fileMap = {
    'MainScreen.dart': 'main_screen.dart',
    'Storage_Backend.dart': 'storage_backend.dart',
    'Ads/BannerAdWidget.dart': 'shared_components/banner_ad_widget.dart',
    'Component/AppColour.dart': 'core/app_colour.dart',
    'Component/AppDrawer.dart': 'shared_components/app_drawer.dart',
    'Component/app_colors.dart': 'core/app_colors.dart',
    'Component/HashtagText.dart': 'shared_components/hashtag_text.dart',
    'Component/policySection.dart': 'shared_components/policy_section.dart',
    'Component/ShareCard.dart': 'shared_components/share_card.dart',

    'Component/CreatePost/CreatePostInputCard.dart':
        'screens/post/components/create_post_input_card.dart',
    'Component/CreatePost/CreatePostLivePreview.dart':
        'screens/post/components/create_post_live_preview.dart',
    'Component/CreatePost/CreatePostTopSection.dart':
        'screens/post/components/create_post_top_section.dart',
    'Component/CreatePost/TextfielsBuild.dart':
        'screens/post/components/text_fields_build.dart',

    'Component/Home/FeedFilterBar.dart':
        'screens/home/components/feed_filter_bar.dart',
    'Component/Home/HomeHeader.dart':
        'screens/home/components/home_header.dart',
    'Component/Home/PostCard.dart': 'screens/home/components/post_card.dart',
    'Component/Home/SearchBox.dart': 'screens/home/components/search_box.dart',

    'Component/Onboarding/OnboardingTemplate.dart':
        'screens/onboarding/components/onboarding_template.dart',
    'Component/Onboarding/OnboardingUserDetailsScreen.dart':
        'screens/onboarding/components/onboarding_user_details_screen.dart',

    'Component/Profile/ProfileGridPainter.dart':
        'screens/profile/components/profile_grid_painter.dart',
    'Component/Profile/ProfileHeaderSliver.dart':
        'screens/profile/components/profile_header_sliver.dart',
    'Component/Profile/ProfilePostSection.dart':
        'screens/profile/components/profile_post_section.dart',
    'Component/Profile/ProfileStatsBox.dart':
        'screens/profile/components/profile_stats_box.dart',
    'Component/Profile/ProfileStatsRow.dart':
        'screens/profile/components/profile_stats_row.dart',

    'Controllers/AuthGate.dart': 'core/auth_gate.dart',
    'Controllers/GoogleAuthController.dart': 'core/google_auth_controller.dart',
    'Controllers/PostProvider.dart': 'core/post_provider.dart',
    'Controllers/ThemeProvider.dart': 'core/theme_provider.dart',
    'Controllers/UserProvider.dart': 'core/user_provider.dart',

    'Screens/AboutScreen.dart': 'screens/about/about_screen.dart',
    'Screens/FacultyVerificationScreen.dart':
        'screens/auth/faculty_verification_screen.dart',
    'Screens/HomeScreen.dart': 'screens/home/home_screen.dart',
    'Screens/LogInScreen2.dart': 'screens/auth/login_screen.dart',
    'Screens/OnBoardingScreen.dart':
        'screens/onboarding/onboarding_screen.dart',
    'Screens/PrivacyPolicySheet.dart':
        'screens/about/privacy_policy_sheet.dart',
    'Screens/SearchScreen.dart': 'screens/search/search_screen.dart',

    'Screens/Post/CreatePostScreen.dart':
        'screens/post/create_post_screen.dart',
    'Screens/Post/EditPostScreen.dart': 'screens/post/edit_post_screen.dart',
    'Screens/Post/FullPostScreen.dart': 'screens/post/full_post_screen.dart',

    'Screens/Profile/EditProfileScreen.dart':
        'screens/profile/edit_profile_screen.dart',
    'Screens/Profile/ProfileScreen.dart': 'screens/profile/profile_screen.dart',
    'Screens/Profile/SettingsScreen.dart':
        'screens/profile/settings_screen.dart',

    'services/ShareService.dart': 'utils/share_service.dart',
    'utils/adPosition.dart': 'utils/ad_position.dart',
  };

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib dir not found');
    return;
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  print(
    'Step 1: Converting all relative imports to absolute package imports...',
  );
  for (final file in dartFiles) {
    String content = file.readAsStringSync();

    content = content.replaceAllMapped(
      RegExp(r'''import\s+['"]([^'"]+)['"]\s*;'''),
      (match) {
        final importPath = match.group(1)!;
        if (importPath.startsWith('package:') ||
            importPath.startsWith('dart:')) {
          return match.group(0)!;
        }

        final currentFileDir = p.dirname(file.path);
        final resolvedPath = p.normalize(p.join(currentFileDir, importPath));
        final packagePath = p
            .relative(resolvedPath, from: libDir.path)
            .replaceAll('\\', '/');

        return "import 'package:igit_connects/$packagePath';";
      },
    );

    file.writeAsStringSync(content);
  }

  print(
    'Step 2: Updating absolute package imports to point to their new snake_case locations...',
  );
  for (final file in dartFiles) {
    String content = file.readAsStringSync();

    for (final oldPath in fileMap.keys) {
      final newPath = fileMap[oldPath]!;
      final oldPackagePath =
          'package:igit_connects/${oldPath.replaceAll('\\', '/')}';
      final newPackagePath =
          'package:igit_connects/${newPath.replaceAll('\\', '/')}';

      content = content.replaceAll(oldPackagePath, newPackagePath);
    }

    file.writeAsStringSync(content);
  }

  print('Step 3: Moving files...');
  for (final file in dartFiles) {
    final relativePath = p
        .relative(file.path, from: libDir.path)
        .replaceAll('\\', '/');

    if (fileMap.containsKey(relativePath)) {
      final newRelativePath = fileMap[relativePath]!;
      final newFile = File(p.join(libDir.path, newRelativePath));

      newFile.parent.createSync(recursive: true);
      try {
        file.renameSync(newFile.path);
      } catch (e) {
        file.copySync(newFile.path);
        try {
          file.deleteSync();
        } catch (_) {}
      }
      print('Moved $relativePath -> $newRelativePath');
    }
  }

  print('Done refactoring!');
}
