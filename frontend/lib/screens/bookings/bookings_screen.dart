import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMyRentals();
      context.read<BookingProvider>().fetchMyListingBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Bookings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('My Rentals'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Consumer<BookingProvider>(
                      builder: (context, bp, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Requests'),
                          if (bp.pendingRequestsCount > 0) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${bp.pendingRequestsCount}',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RentalsList(),
                  _RequestsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.myRentals.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (provider.myRentals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text('No rentals yet',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Browse items and start renting!',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.accentCyan,
          onRefresh: () => provider.fetchMyRentals(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.myRentals.length,
            itemBuilder: (context, index) {
              return _BookingCard(
                booking: provider.myRentals[index],
                isOwnerView: false,
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
            },
          ),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.myListingBookings.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentCyan),
          );
        }

        if (provider.myListingBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text('No requests yet',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Rental requests from others will appear here',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.accentCyan,
          onRefresh: () => provider.fetchMyListingBookings(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.myListingBookings.length,
            itemBuilder: (context, index) {
              return _BookingCard(
                booking: provider.myListingBookings[index],
                isOwnerView: true,
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
            },
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isOwnerView;

  const _BookingCard({required this.booking, required this.isOwnerView});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item image/icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: booking.item?.images.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            booking.item!.images.first,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Text(
                              booking.item?.categoryIcon ?? '📦',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        )
                      : Text(
                          booking.item?.categoryIcon ?? '📦',
                          style: const TextStyle(fontSize: 24),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.item?.title ?? 'Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwnerView
                          ? 'From: ${booking.renter?.name ?? 'Unknown'}'
                          : 'By: ${booking.owner?.name ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          // Date range & price
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppTheme.accentCyan),
                    const SizedBox(width: 6),
                    Text(
                      '${fmt.format(booking.startDate)} - ${fmt.format(booking.endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${booking.totalPrice.toInt()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ],
            ),
          ),

          if (booking.renterNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${booking.renterNote}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (booking.estimatedDeliveryTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Est. delivery: ${booking.estimatedDeliveryTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ],

          // Action buttons
          if (isOwnerView && booking.status == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Accept',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                      onTap: () => _showAcceptDialog(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Decline',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.error,
                      onTap: () => _respond(context, 'rejected'),
                    ),
                  ),
                ],
              ),
            ),

          if (!isOwnerView && booking.status == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ActionButton(
                label: 'Cancel Request',
                icon: Icons.close_rounded,
                color: AppTheme.error,
                onTap: () => _cancel(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context) {
    final deliveryCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Request',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassTextField(
              controller: deliveryCtrl,
              hintText: 'Est. delivery time (e.g., 2-3 hours)',
              prefixIcon: Icons.access_time_rounded,
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: noteCtrl,
              hintText: 'Add a note (optional)',
              prefixIcon: Icons.note_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BookingProvider>().respondToBooking(
                    booking.id,
                    status: 'accepted',
                    estimatedDeliveryTime: deliveryCtrl.text.isNotEmpty
                        ? deliveryCtrl.text
                        : null,
                    ownerNote:
                        noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _respond(BuildContext context, String status) {
    context.read<BookingProvider>().respondToBooking(booking.id, status: status);
  }

  void _cancel(BuildContext context) {
    context.read<BookingProvider>().cancelBooking(booking.id);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
