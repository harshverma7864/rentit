import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.send_rounded;
      case 'booking_accepted':
        return Icons.check_circle_rounded;
      case 'booking_rejected':
        return Icons.cancel_rounded;
      case 'booking_completed':
        return Icons.celebration_rounded;
      case 'booking_cancelled':
        return Icons.block_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'booking_request':
        return AppTheme.primaryBlue;
      case 'booking_accepted':
        return AppTheme.success;
      case 'booking_rejected':
        return AppTheme.error;
      case 'booking_completed':
        return AppTheme.accentCyan;
      case 'booking_cancelled':
        return AppTheme.warning;
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<NotificationProvider>().markAllRead(),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(color: AppTheme.accentCyan, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.accentCyan),
                    );
                  }

                  if (provider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: AppTheme.textHint),
                          const SizedBox(height: 16),
                          Text('No notifications',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.accentCyan,
                    onRefresh: () => provider.fetchNotifications(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = provider.notifications[index];
                        return GlassCard(
                          onTap: () {
                            if (!notif.isRead) {
                              provider.markAsRead(notif.id);
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getColor(notif.type)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIcon(notif.type),
                                  color: _getColor(notif.type),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notif.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.createdAt != null
                                          ? DateFormat('MMM dd, hh:mm a')
                                              .format(notif.createdAt!)
                                          : '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(
                            delay: Duration(milliseconds: 50 * index));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
