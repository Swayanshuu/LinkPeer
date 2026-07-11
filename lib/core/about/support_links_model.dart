class SupportLinksModel {
  final String privacyPolicy;
  final String accountDeletion;
  final String childSafety;
  final String supportEmail;
  final String supportWebsite;

  SupportLinksModel({
    required this.privacyPolicy,
    required this.accountDeletion,
    required this.childSafety,
    required this.supportEmail,
    required this.supportWebsite,
  });

  factory SupportLinksModel.fromJson(Map<String, dynamic> json) {
    return SupportLinksModel(
      privacyPolicy: json['privacyPolicy'] ?? '',
      accountDeletion: json['accountDeletion'] ?? '',
      childSafety: json['childSafety'] ?? '',
      supportEmail: json['supportEmail'] ?? '',
      supportWebsite: json['supportWebsite'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacyPolicy': privacyPolicy,
      'accountDeletion': accountDeletion,
      'childSafety': childSafety,
      'supportEmail': supportEmail,
      'supportWebsite': supportWebsite,
    };
  }
}
