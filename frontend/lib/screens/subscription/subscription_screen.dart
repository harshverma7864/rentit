import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Consumer<SubscriptionProvider>(
        builder: (context, sub, _) {
          if (sub.isLoading && sub.subscription == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final current = sub.subscription;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current plan
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Plan', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          (current?.plan ?? 'free').toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: current?.isPremium == true
                                ? Colors.amber
                                : current?.isBasic == true
                                    ? AppTheme.accentCyan
                                    : Colors.grey,
                          ),
                        ),
                        if (current?.expiresAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${_formatDate(current!.expiresAt!)}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statChip('Listings Left', current?.freeListingsRemaining == -1 ? '∞' : '${current?.freeListingsRemaining ?? 3}'),
                            const SizedBox(width: 12),
                            _statChip('Contact Views', current?.freeContactViewsRemaining == -1 ? '∞' : '${current?.freeContactViewsRemaining ?? 5}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Free plan
                _buildPlanCard(
                  name: 'Free',
                  price: '₹0',
                  features: ['3 free listings', '5 contact views', 'Basic search'],
                  isCurrent: current?.isFree == true,
                  color: Colors.grey,
                  onUpgrade: null,
                ),
                const SizedBox(height: 12),

                // Basic plan
                _buildPlanCard(
                  name: 'Basic',
                  price: '₹99/month',
                  features: ['15 listings', '30 contact views', 'Priority support'],
                  isCurrent: current?.isBasic == true,
                  color: AppTheme.accentCyan,
                  onUpgrade: current?.isBasic != true
                      ? () => _purchase('basic', 99)
                      : null,
                ),
                const SizedBox(height: 12),

                // Premium plan
                _buildPlanCard(
                  name: 'Premium',
                  price: '₹299/month',
                  features: ['Unlimited listings', 'Unlimited contact views', 'Priority placement', 'Badge on profile'],
                  isCurrent: current?.isPremium == true,
                  color: Colors.amber,
                  onUpgrade: current?.isPremium != true
                      ? () => _purchase('premium', 299)
                      : null,
                ),
              ].animate(interval: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required Color color,
    VoidCallback? onUpgrade,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            )),
            const SizedBox(height: 12),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Current Plan', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              )
            else if (onUpgrade != null)
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: onUpgrade,
                  text: 'Upgrade to $name',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(String plan, int price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Upgrade to ${plan[0].toUpperCase()}${plan.substring(1)}'),
        content: Text('₹$price will be deducted from your wallet. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final success = await context.read<SubscriptionProvider>().purchasePlan(plan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Plan upgraded successfully!' : (context.read<SubscriptionProvider>().error ?? 'Failed'))),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
