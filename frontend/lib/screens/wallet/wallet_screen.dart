import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  void _showAddMoneyDialog() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Money',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: GlassTextField(
          controller: amountCtrl,
          hintText: 'Enter amount',
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                final success =
                    await context.read<WalletProvider>().addMoney(amount);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? '₹${amount.toInt()} added to wallet'
                          : 'Failed to add money'),
                      backgroundColor:
                          success ? AppTheme.success : AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
          ),
        ),
        child: Consumer<WalletProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.wallet == null) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.accentCyan),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Balance card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${provider.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddMoneyDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Money'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 24),

                // Transaction history
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (provider.wallet == null ||
                    provider.wallet!.transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppTheme.textHint),
                          const SizedBox(height: 12),
                          Text('No transactions yet',
                              style: TextStyle(color: AppTheme.textHint)),
                        ],
                      ),
                    ),
                  )
                else
                  ...provider.wallet!.transactions.reversed.map(
                    (txn) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _txnColor(txn.type)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _txnIcon(txn.type),
                              color: _txnColor(txn.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (txn.createdAt != null)
                                  Text(
                                    DateFormat('MMM dd, hh:mm a')
                                        .format(txn.createdAt!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${txn.type == 'debit' || txn.type == 'payment' ? '-' : '+'}₹${txn.amount.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: txn.type == 'debit' ||
                                      txn.type == 'payment'
                                  ? AppTheme.error
                                  : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _txnColor(String type) {
    switch (type) {
      case 'credit':
        return AppTheme.success;
      case 'debit':
      case 'payment':
        return AppTheme.error;
      case 'refund':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _txnIcon(String type) {
    switch (type) {
      case 'credit':
        return Icons.arrow_downward_rounded;
      case 'debit':
      case 'payment':
        return Icons.arrow_upward_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }
}
