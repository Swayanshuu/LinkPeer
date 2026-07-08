import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool isLoading = false;

  Future<void> _processPayment(String planType, double amount) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Premium subscriptions are coming soon! Stay tuned."),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFeatureRow(String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.primaryText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required AppColors colors,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required bool isPro,
    required VoidCallback onSubscribe,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPro
            ? colors.primaryAccent.withValues(alpha: 0.1)
            : colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPro
              ? colors.primaryAccent
              : colors.borderColor.withValues(alpha: 0.5),
          width: isPro ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "MOST POPULAR",
                style: TextStyle(
                  color: colors.onPrimaryAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: colors.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "₹$price",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "/month",
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: features
                  .map((f) => _buildFeatureRow(f, colors))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: isPro ? colors.primaryAccent : colors.bgColor,
                foregroundColor: isPro
                    ? colors.onPrimaryAccent
                    : colors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isPro
                      ? BorderSide.none
                      : BorderSide(color: colors.borderColor),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      "Upgrade to $title",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);
    final currentPlan = user.value?["subscription_plan"] ?? "free";

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "LinkPeer Premium",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Supercharge your\nprofessional growth.",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Get verified, boost your profile visibility, and unlock unlimited posting capabilities.",
                  style: TextStyle(color: colors.secondaryText, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: colors.primaryAccent,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Plan",
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentPlan.toString().toUpperCase(),
                            style: TextStyle(
                              color: colors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                _buildPlanCard(
                  context: context,
                  colors: colors,
                  title: "Premium Lite",
                  price: "49",
                  description:
                      "Essential tools for students and professionals.",
                  features: [
                    "Verified badge on profile",
                    "Higher visibility in directory",
                    "Up to 10 posts per day",
                    "Up to 15 imaged posts per month",
                    "Up to 4 images per post",
                  ],
                  isPro: false,
                  onSubscribe: () => _processPayment("premium_lite", 49),
                ),
                _buildPlanCard(
                  context: context,
                  colors: colors,
                  title: "Premium Pro",
                  price: "99",
                  description: "Maximum visibility and unlimited features.",
                  features: [
                    "Everything in Premium Lite",
                    "Highest ranking in search & directory",
                    "Unlimited posts per day",
                    "Unlimited imaged posts",
                    "Up to 10 images per post",
                    "Priority support",
                  ],
                  isPro: true,
                  onSubscribe: () => _processPayment("premium_pro", 99),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
