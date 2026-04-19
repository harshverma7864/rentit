import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/dispute_provider.dart';
import '../../models/dispute_model.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisputeProvider>().fetchMyDisputes();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppTheme.warning;
      case 'under_review':
        return AppTheme.primaryLight;
      case 'resolved':
        return AppTheme.success;
      case 'dismissed':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Disputes'),
        ),
        body: Consumer<DisputeProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              );
            }

            if (provider.disputes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gavel_rounded, size: 64, color: AppTheme.textHint),
                    const SizedBox(height: 16),
                    Text(
                      'No disputes yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.disputes.length,
              itemBuilder: (context, index) {
                final dispute = provider.disputes[index];
                return _buildDisputeCard(dispute, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDisputeCard(DisputeModel dispute, int index) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: _statusColor(dispute.status), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dispute.reason,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(dispute.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dispute.statusLabel,
                  style: TextStyle(
                    color: _statusColor(dispute.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dispute.description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (dispute.againstUser != null) ...[
                Text(
                  'Against: ',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                ),
                Text(
                  dispute.againstUser!.name,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
              const Spacer(),
              if (dispute.createdAt != null)
                Text(
                  _formatDate(dispute.createdAt!),
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
            ],
          ),
          if (dispute.resolution.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resolution: ${dispute.resolution}',
                      style: TextStyle(color: AppTheme.success, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
