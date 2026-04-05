import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../chat/chat_detail_screen.dart';
import '../wallet/wallet_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _loading = true);
    final b = await context.read<BookingProvider>().fetchBookingById(widget.bookingId);
    if (mounted) setState(() { _booking = b; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : _booking == null
              ? const Center(child: Text('Booking not found', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  color: AppTheme.accentCyan,
                  onRefresh: _loadBooking,
                  child: _buildContent(currentUserId),
                ),
    );
  }

  Widget _buildContent(String currentUserId) {
    final booking = _booking!;
    final isOwner = booking.owner?.id == currentUserId;
    final fmt = DateFormat('MMM dd, yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Item info
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: booking.item?.images.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            booking.item!.images.first,
                            fit: BoxFit.cover, width: 64, height: 64,
                            errorBuilder: (_, __, ___) => Text(
                              booking.item?.categoryIcon ?? '📦',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        )
                      : Text(booking.item?.categoryIcon ?? '📦', style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.item?.title ?? 'Item',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwner ? 'Renter: ${booking.renter?.name ?? ''}' : 'Owner: ${booking.owner?.name ?? ''}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 12),

        // Date & Price summary
        GlassCard(
          child: Column(
            children: [
              _InfoRow(icon: Icons.calendar_today_rounded, label: 'Period',
                  value: '${fmt.format(booking.startDate)} - ${fmt.format(booking.endDate)}'),
              const Divider(color: AppTheme.textHint, height: 20),
              _InfoRow(icon: Icons.attach_money_rounded, label: 'Rental Price',
                  value: '₹${booking.totalPrice.toInt()}'),
              _InfoRow(icon: Icons.shield_outlined, label: 'Security Deposit',
                  value: '₹${booking.securityDeposit.toInt()}'),
              if (booking.finalPrice != null) ...[
                const Divider(color: AppTheme.textHint, height: 20),
                _InfoRow(icon: Icons.handshake_rounded, label: 'Negotiated Price',
                    value: '₹${booking.finalPrice!.toInt()}', valueColor: AppTheme.success),
              ],
              const Divider(color: AppTheme.textHint, height: 20),
              _InfoRow(icon: Icons.payment_rounded, label: 'Total Payable',
                  value: '₹${((booking.finalPrice ?? booking.totalPrice) + booking.securityDeposit).toInt()}',
                  valueColor: AppTheme.accentCyan),
              _InfoRow(icon: Icons.info_outline, label: 'Payment',
                  value: booking.paymentStatus == 'paid' ? 'Paid ✓' : 'Unpaid',
                  valueColor: booking.paymentStatus == 'paid' ? AppTheme.success : AppTheme.warning),
              if (booking.paymentStatus == 'paid')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Security deposit ₹${booking.securityDeposit.toInt()} held in escrow — returned on completion',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),

        // Delivery status
        if (booking.deliveryOption == 'delivery')
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(
                    booking.deliveryStatus == 'delivered' ? Icons.check_circle_rounded
                        : booking.deliveryStatus == 'out_for_delivery' ? Icons.local_shipping_rounded
                        : Icons.hourglass_top_rounded,
                    color: booking.deliveryStatus == 'delivered' ? AppTheme.success : AppTheme.warning, size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.deliveryStatus == 'delivered' ? 'Delivered'
                        : booking.deliveryStatus == 'out_for_delivery' ? 'Out for Delivery'
                        : booking.deliveryStatus == 'pending' ? 'Delivery Pending'
                        : 'Not Started',
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ]),
                if (isOwner && booking.paymentStatus == 'paid' && booking.deliveryStatus != 'delivered') ...[
                  const SizedBox(height: 12),
                  _buildActionButton(
                    label: booking.deliveryStatus == 'pending' ? 'Mark Out for Delivery' : 'Mark Delivered',
                    icon: Icons.local_shipping_rounded,
                    color: AppTheme.primaryLight,
                    onTap: () async {
                      final next = booking.deliveryStatus == 'pending' ? 'out_for_delivery' : 'delivered';
                      await context.read<BookingProvider>().updateDeliveryStatus(booking.id, next);
                      _loadBooking();
                    },
                  ),
                ],
                if (isOwner && booking.paymentStatus != 'paid' && booking.deliveryStatus == 'none')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Payment must be completed before delivery', style: TextStyle(fontSize: 12, color: AppTheme.warning)),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

        if (booking.deliveryOption == 'delivery') const SizedBox(height: 12),

        // Negotiation section
        if (booking.status == 'pending')
          _buildNegotiationSection(booking, isOwner),

        // Notes
        if (booking.renterNote.isNotEmpty || booking.ownerNote.isNotEmpty)
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              if (booking.renterNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Renter: ${booking.renterNote}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
              if (booking.ownerNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Owner: ${booking.ownerNote}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ]),
          ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        // Action buttons
        if (!isOwner && booking.status == 'accepted' && booking.paymentStatus == 'unpaid')
          _buildActionButton(
            label: 'Pay Now (₹${((booking.finalPrice ?? booking.totalPrice) + booking.securityDeposit).toInt()})',
            icon: Icons.payment_rounded,
            color: AppTheme.success,
            onTap: () => _payForBooking(booking),
          ),

        if (isOwner && booking.status == 'pending')
          Row(children: [
            Expanded(child: _buildActionButton(
              label: 'Accept', icon: Icons.check_circle_outline_rounded, color: AppTheme.success,
              onTap: () => _showAcceptDialog(booking),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildActionButton(
              label: 'Decline', icon: Icons.cancel_outlined, color: AppTheme.error,
              onTap: () async {
                await context.read<BookingProvider>().respondToBooking(booking.id, status: 'rejected');
                _loadBooking();
              },
            )),
          ]),

        if (!isOwner && booking.status == 'pending')
          _buildActionButton(
            label: 'Cancel Request', icon: Icons.close_rounded, color: AppTheme.error,
            onTap: () async {
              await context.read<BookingProvider>().cancelBooking(booking.id);
              if (mounted) Navigator.pop(context);
            },
          ),

        if (!isOwner && (booking.status == 'accepted' || booking.status == 'active') && booking.deliveryStatus != 'delivered')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildActionButton(
              label: booking.deliveryStatus == 'out_for_delivery' ? 'Cancel (delivery fee applies)' : 'Cancel Booking',
              icon: Icons.close_rounded, color: AppTheme.error,
              onTap: () async {
                await context.read<BookingProvider>().cancelBooking(booking.id);
                if (mounted) Navigator.pop(context);
              },
            ),
          ),

        if ((booking.status == 'accepted' || booking.status == 'active') && booking.paymentStatus == 'paid')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildActionButton(
              label: 'Mark Completed', icon: Icons.check_circle_rounded, color: AppTheme.success,
              onTap: () async {
                await context.read<BookingProvider>().completeBooking(booking.id);
                _loadBooking();
              },
            ),
          ),

        const SizedBox(height: 8),
        if (booking.status != 'rejected' && booking.status != 'cancelled')
          _buildActionButton(
            label: 'Chat', icon: Icons.chat_bubble_outline_rounded, color: AppTheme.accentCyan,
            onTap: () => _openChat(booking, isOwner),
          ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildNegotiationSection(BookingModel booking, bool isOwner) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.handshake_rounded, size: 20, color: AppTheme.accentCyan),
            const SizedBox(width: 8),
            const Text('Negotiate Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
          const SizedBox(height: 8),
          Text('Current price: ₹${booking.totalPrice.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          if (booking.proposedPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Proposed: ₹${booking.proposedPrice!.toInt()} (${booking.negotiationStatus})',
                style: TextStyle(color: AppTheme.warning, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),

          // Negotiation history
          if (booking.negotiationHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...booking.negotiationHistory.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(
                  entry.from == 'renter' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16, color: entry.from == 'renter' ? AppTheme.accentCyan : AppTheme.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.from == 'renter' ? 'Renter' : 'Owner'}: ₹${entry.amount.toInt()}',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                if (entry.message.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.message, style: TextStyle(fontSize: 12, color: AppTheme.textHint), overflow: TextOverflow.ellipsis)),
                ],
              ]),
            )),
          ],

          const SizedBox(height: 12),

          // Can propose if no accepted negotiation
          if (booking.negotiationStatus != 'accepted')
            _buildActionButton(
              label: 'Propose Price',
              icon: Icons.edit_rounded,
              color: AppTheme.primaryBlue,
              onTap: () => _showNegotiateDialog(booking),
            ),

          // Accept latest proposal (other party proposed)
          if (booking.proposedPrice != null &&
              booking.negotiationStatus != 'accepted' &&
              ((isOwner && booking.negotiationStatus == 'proposed') ||
               (!isOwner && booking.negotiationStatus == 'counter')))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildActionButton(
                label: 'Accept ₹${booking.proposedPrice!.toInt()}',
                icon: Icons.check_rounded,
                color: AppTheme.success,
                onTap: () async {
                  await context.read<BookingProvider>().acceptNegotiation(booking.id);
                  _loadBooking();
                },
              ),
            ),

          if (booking.negotiationStatus == 'accepted')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.success),
                const SizedBox(width: 6),
                Text('Price agreed: ₹${booking.finalPrice?.toInt() ?? booking.proposedPrice?.toInt()}',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms);
  }

  void _showNegotiateDialog(BookingModel booking) {
    final priceCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Propose Price', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ₹${booking.totalPrice.toInt()}', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            GlassTextField(
              controller: priceCtrl,
              hintText: 'Your proposed price',
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: messageCtrl,
              hintText: 'Message (optional)',
              prefixIcon: Icons.message_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              if (price == null || price <= 0) return;
              Navigator.pop(ctx);
              await context.read<BookingProvider>().negotiatePrice(
                booking.id, price, message: messageCtrl.text.isNotEmpty ? messageCtrl.text : null,
              );
              _loadBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Propose'),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BookingModel booking) {
    final deliveryCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Request', style: TextStyle(color: AppTheme.textPrimary)),
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
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookingProvider>().respondToBooking(
                booking.id,
                status: 'accepted',
                estimatedDeliveryTime: deliveryCtrl.text.isNotEmpty ? deliveryCtrl.text : null,
                ownerNote: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              );
              _loadBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _payForBooking(BookingModel booking) async {
    final wallet = context.read<WalletProvider>();
    await wallet.fetchWallet();
    final totalAmount = (booking.finalPrice ?? booking.totalPrice) + booking.securityDeposit;

    if (!mounted) return;

    if (wallet.balance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance (₹${wallet.balance.toInt()}). Need ₹${totalAmount.toInt()}.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(label: 'Add Money', textColor: Colors.white, onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          }),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Payment', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Rental: ₹${(booking.finalPrice ?? booking.totalPrice).toInt()}', style: const TextStyle(color: AppTheme.textSecondary)),
          Text('Security Deposit: ₹${booking.securityDeposit.toInt()}', style: const TextStyle(color: AppTheme.textSecondary)),
          const Divider(color: AppTheme.textHint),
          Text('Total: ₹${totalAmount.toInt()}', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Security deposit is held in escrow and returned on completion.', style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await wallet.payForBooking(booking.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Payment successful!' : wallet.error ?? 'Payment failed'),
                  backgroundColor: success ? AppTheme.success : AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
                if (success) _loadBooking();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _openChat(BookingModel booking, bool isOwner) async {
    final otherUserId = isOwner ? booking.renter?.id ?? '' : booking.owner?.id ?? '';
    final otherUserName = isOwner ? booking.renter?.name ?? 'User' : booking.owner?.name ?? 'User';
    if (otherUserId.isEmpty) return;

    final chat = await context.read<ChatProvider>().getOrCreateChat(
      userId: otherUserId, itemId: booking.item?.id, bookingId: booking.id,
    );
    if (chat != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chat.id, otherUserName: otherUserName)));
    }
  }

  Widget _buildActionButton({
    required String label, required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.textHint),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
      ]),
    );
  }
}
