import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/main_screen.dart';

class PaymentResultScreen extends StatelessWidget {
  final String status;
  final String? txnId;

  const PaymentResultScreen({super.key, required this.status, this.txnId});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSuccess = status == 'success';

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? colors.successColor : Colors.red,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? "Payment Successful!" : "Payment Failed",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess
                    ? "Your Premium Subscription is now active. Enjoy your new features!"
                    : "Something went wrong with your payment. Please try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, fontSize: 16),
              ),
              if (txnId != null) ...[
                const SizedBox(height: 16),
                Text(
                  "Transaction ID: $txnId",
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: colors.onPrimaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isSuccess ? "Start Exploring" : "Go Back",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
