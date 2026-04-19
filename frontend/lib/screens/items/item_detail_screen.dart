import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/item_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/favorite_provider.dart';
import '../chat/chat_detail_screen.dart';
import '../profile/seller_profile_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItemById(widget.itemId);
      context.read<ReviewProvider>().fetchItemReviews(widget.itemId);
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _showRentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RentBottomSheet(itemId: widget.itemId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.selectedItem == null) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          final item = provider.selectedItem!;
          final currentUserId = context.read<AuthProvider>().user?.id;
          final isOwner =
              currentUserId != null && item.owner?.id == currentUserId;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
              ),
            ),
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // Image section
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: AppTheme.primaryDark,
                      leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      actions: [
                        if (!isOwner)
                          Consumer<FavoriteProvider>(
                            builder: (context, favProvider, _) {
                              final isFav = favProvider.isFavorite(item.id);
                              return IconButton(
                                onPressed: () => favProvider.toggleFavorite(item.id),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryDark.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? AppTheme.error : Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryBlue.withValues(alpha: 0.4),
                                AppTheme.primaryDark,
                              ],
                            ),
                          ),
                          child: item.imageUrls.isNotEmpty
                              ? Stack(
                                  children: [
                                    PageView.builder(
                                      controller: _imagePageController,
                                      itemCount: item.imageUrls.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => _FullScreenImageViewer(
                                                  imageUrls: item.imageUrls,
                                                  initialIndex: index,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Image.network(
                                            item.imageUrls[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                              child: Text(
                                                item.categoryIcon,
                                                style: const TextStyle(
                                                    fontSize: 80),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Image counter badge
                                    if (item.imageUrls.length > 1)
                                      Positioned(
                                        right: 16,
                                        bottom: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '${_currentImageIndex + 1} / ${item.imageUrls.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Dot indicators
                                    if (item.imageUrls.length > 1)
                                      Positioned(
                                        bottom: 16,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            item.imageUrls.length,
                                            (index) => AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 3),
                                              width:
                                                  _currentImageIndex == index
                                                      ? 20
                                                      : 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    _currentImageIndex == index
                                                        ? AppTheme.accentCyan
                                                        : Colors.white54,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    item.categoryIcon,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${item.pricePerDay.toInt()}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accentCyan,
                                      ),
                                    ),
                                    Text(
                                      'per day',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ).animate().fadeIn().slideY(begin: 0.1),

                            const SizedBox(height: 16),

                            // Quick info chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                    icon: Icons.verified_outlined,
                                    label: item.conditionLabel),
                                _InfoChip(
                                    icon: Icons.inventory_2_outlined,
                                    label: '${item.quantity} available'),
                                if (item.deliveryAvailable)
                                  _InfoChip(
                                      icon: Icons.local_shipping_outlined,
                                      label:
                                          'Delivery ₹${item.deliveryFee.toInt()}'),
                                _InfoChip(
                                    icon: Icons.calendar_month_outlined,
                                    label:
                                        'Max ${item.maxRentalDays} days'),
                                if (item.location?.city != null &&
                                    item.location!.city.isNotEmpty)
                                  _InfoChip(
                                      icon: Icons.location_on_outlined,
                                      label: item.location!.city),
                              ],
                            ).animate().fadeIn(delay: 200.ms),

                            // Damage warning if no in-app delivery
                            if (!item.hasInAppDelivery) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No in-app delivery. Damages will be managed by seller/buyer. Opt for in-app delivery for protection.',
                                        style: TextStyle(color: Colors.orange[300], fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 250.ms),
                            ],

                            // Delivery options display
                            if (item.deliveryOptions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item.hasSelfPickup)
                                    _InfoChip(icon: Icons.directions_walk, label: 'Self Pickup'),
                                  if (item.hasSellerDelivery)
                                    _InfoChip(icon: Icons.local_shipping, label: 'Seller Delivery'),
                                  if (item.hasInAppDelivery)
                                    _InfoChip(icon: Icons.verified_user, label: 'In-App Delivery'),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Pricing section
                            _SectionTitle(text: 'Pricing'),
                            const SizedBox(height: 12),
                            GlassCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  _PriceRow('Per Day', '₹${item.pricePerDay.toInt()}'),
                                  if (item.pricePerHour > 0)
                                    _PriceRow('Per Hour', '₹${item.pricePerHour.toInt()}'),
                                  if (item.pricePerWeek > 0)
                                    _PriceRow('Per Week', '₹${item.pricePerWeek.toInt()}'),
                                  Divider(color: AppTheme.textHint),
                                  _PriceRow('Security Deposit',
                                      '₹${item.securityDeposit.toInt()}',
                                      highlight: true),
                                ],
                              ),
                            ).animate().fadeIn(delay: 300.ms),

                            const SizedBox(height: 24),

                            // Description
                            _SectionTitle(text: 'Description'),
                            const SizedBox(height: 12),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ).animate().fadeIn(delay: 400.ms),

                            // Specs section (dynamic, from JSONB)
                            if (item.specs.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _SectionTitle(text: 'Specifications'),
                              const SizedBox(height: 12),
                              GlassCard(
                                margin: EdgeInsets.zero,
                                child: Column(
                                  children: item.specs.entries.map((e) {
                                    final label = e.key[0].toUpperCase() +
                                        e.key.substring(1).replaceAllMapped(
                                            RegExp(r'[A-Z]'),
                                            (m) => ' ${m.group(0)}');
                                    final value = e.value is bool
                                        ? (e.value ? 'Yes' : 'No')
                                        : e.value.toString();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(label,
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 14)),
                                          Text(
                                            value.isNotEmpty
                                                ? value[0].toUpperCase() +
                                                    value.substring(1)
                                                : value,
                                            style: TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ).animate().fadeIn(delay: 450.ms),
                            ],

                            if (item.rules.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _SectionTitle(text: 'Rental Rules'),
                              const SizedBox(height: 12),
                              Text(
                                item.rules,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Owner info
                            if (item.owner != null) ...[
                              _SectionTitle(text: 'Listed By'),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => SellerProfileScreen(userId: item.owner!.id)));
                                },
                                child: GlassCard(
                                margin: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppTheme.primaryBlue,
                                          backgroundImage: item.owner!.avatarUrl.isNotEmpty
                                              ? NetworkImage(item.owner!.avatarUrl)
                                              : null,
                                          child: item.owner!.avatarUrl.isEmpty
                                              ? Text(
                                                  item.owner!.name.isNotEmpty ? item.owner!.name[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    item.owner!.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textHint),
                                                ],
                                              ),
                                              if (item.owner!.rating > 0)
                                                Row(
                                                  children: [
                                                    Icon(Icons.star_rounded,
                                                        size: 16,
                                                        color: AppTheme.warning),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${item.owner!.rating.toStringAsFixed(1)} (${item.owner!.totalRatings} reviews)',
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme.textSecondary,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (item.owner!.location?.city != null && item.owner!.location!.city.isNotEmpty)
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on_outlined,
                                                        size: 14,
                                                        color: AppTheme.textHint),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item.owner!.location!.city,
                                                      style: TextStyle(
                                                        color: AppTheme.textHint,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (item.owner!.phone.isNotEmpty)
                                                Row(
                                                  children: [
                                                    Icon(Icons.phone_outlined,
                                                        size: 14,
                                                        color: AppTheme.textHint),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item.owner!.phone,
                                                      style: TextStyle(
                                                        color: AppTheme.textHint,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else if (item.owner!.contactLocked)
                                                Row(
                                                  children: [
                                                    Icon(Icons.lock_outline,
                                                        size: 14,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Upgrade to view contact',
                                                      style: TextStyle(
                                                        color: Colors.orange,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isOwner) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final chatProvider = context.read<ChatProvider>();
                                            final chat = await chatProvider.getOrCreateChat(
                                              userId: item.owner!.id,
                                              itemId: item.id,
                                            );
                                            if (chat != null && context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ChatDetailScreen(
                                                    chatId: chat.id,
                                                    otherUserName: item.owner!.name,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.chat_bubble_outline_rounded,
                                              size: 18, color: AppTheme.accentCyan),
                                          label: Text('Chat with Owner',
                                              style: TextStyle(color: AppTheme.accentCyan)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              ).animate().fadeIn(delay: 500.ms),
                            ],

                            // Reviews section
                            const SizedBox(height: 24),
                            _ItemReviewsSection(itemId: item.id, isOwner: isOwner),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom rent button
                if (!isOwner)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryDark.withValues(alpha: 0.9),
                            border: Border(
                              top: BorderSide(
                                color:
                                    AppTheme.accentBlue.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: GlassButton(
                            text: 'Rent This Item',
                            icon: Icons.handshake_rounded,
                            onPressed: item.isAvailable
                                ? _showRentBottomSheet
                                : null,
                            color: item.isAvailable
                                ? AppTheme.primaryBlue
                                : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RentBottomSheet extends StatefulWidget {
  final String itemId;

  const _RentBottomSheet({required this.itemId});

  @override
  State<_RentBottomSheet> createState() => _RentBottomSheetState();
}

class _RentBottomSheetState extends State<_RentBottomSheet> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _deliveryOption = 'pickup';
  int _quantity = 1;
  final _noteController = TextEditingController();
  DateTime? _scheduledPickup;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.primaryDeep,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectPickupTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final base = AppTheme.isDark ? ThemeData.dark() : ThemeData.light();
        final scheme = AppTheme.isDark
            ? ColorScheme.dark(primary: AppTheme.primaryBlue, surface: AppTheme.primaryDeep)
            : ColorScheme.light(primary: AppTheme.primaryBlue, surface: AppTheme.primaryDeep);
        return Theme(
          data: base.copyWith(colorScheme: scheme),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _scheduledPickup = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _submitRent() async {
    final booking = context.read<BookingProvider>();
    final success = await booking.createBooking(
      itemId: widget.itemId,
      startDate: _startDate,
      endDate: _endDate,
      deliveryOption: _deliveryOption,
      quantity: _quantity,
      renterNote: _noteController.text.isNotEmpty ? _noteController.text : null,
      scheduledPickupTime: _scheduledPickup,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Rental request sent! Waiting for owner approval.'
              : booking.error ?? 'Something went wrong'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy');
    final item = context.read<ItemProvider>().selectedItem;
    final days = _endDate.difference(_startDate).inDays.clamp(1, 9999);
    final total = (days * (item?.pricePerDay ?? 0) +
        (_deliveryOption == 'delivery' ? (item?.deliveryFee ?? 0) : 0)) * _quantity;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryDeep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Book This Item',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Date selection
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Start Date',
                    date: fmt.format(_startDate),
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateSelector(
                    label: 'End Date',
                    date: fmt.format(_endDate),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Schedule pickup
            GestureDetector(
              onTap: _selectPickupTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: GlassDecoration.subtle,
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppTheme.accentCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Pickup Time',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _scheduledPickup != null
                                ? DateFormat('hh:mm a').format(_scheduledPickup!)
                                : 'Tap to set time',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delivery option
            if (item?.deliveryAvailable == true) ...[
              Text(
                'Delivery Option',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: 'Self Pickup',
                      icon: Icons.directions_walk_rounded,
                      isSelected: _deliveryOption == 'pickup',
                      onTap: () =>
                          setState(() => _deliveryOption = 'pickup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionChip(
                      label: 'Delivery',
                      icon: Icons.local_shipping_outlined,
                      isSelected: _deliveryOption == 'delivery',
                      onTap: () =>
                          setState(() => _deliveryOption = 'delivery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Quantity selector
            if ((item?.quantity ?? 1) > 1) ...[
              Text(
                'Quantity',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: GlassDecoration.subtle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item?.quantity ?? 1} available',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: Icon(Icons.remove_circle_outline,
                              color: _quantity > 1
                                  ? AppTheme.accentCyan
                                  : AppTheme.textHint),
                          iconSize: 24,
                        ),
                        Text(
                          '$_quantity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < (item?.quantity ?? 1)
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: Icon(Icons.add_circle_outline,
                              color: _quantity < (item?.quantity ?? 1)
                                  ? AppTheme.accentCyan
                                  : AppTheme.textHint),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Note
            GlassTextField(
              controller: _noteController,
              hintText: 'Add a note for the owner (optional)',
              prefixIcon: Icons.note_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Price summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: GlassDecoration.subtle,
              child: Column(
                children: [
                  _PriceRow('$days day${days > 1 ? 's' : ''} × ₹${item?.pricePerDay.toInt() ?? 0}${_quantity > 1 ? ' × $_quantity' : ''}',
                      '₹${(days * (item?.pricePerDay ?? 0) * _quantity).toInt()}'),
                  if (_deliveryOption == 'delivery')
                    _PriceRow('Delivery Fee${_quantity > 1 ? ' × $_quantity' : ''}',
                        '₹${((item?.deliveryFee.toInt() ?? 0) * _quantity)}'),
                  Divider(color: AppTheme.textHint),
                  _PriceRow('Total', '₹${total.toInt()}', highlight: true),
                  _PriceRow('Security Deposit${_quantity > 1 ? ' × $_quantity' : ''}',
                      '₹${((item?.securityDeposit.toInt() ?? 0) * _quantity)}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Consumer<BookingProvider>(
              builder: (context, bookingProvider, _) => GlassButton(
                text: 'Send Rental Request',
                isLoading: bookingProvider.isLoading,
                onPressed: _submitRent,
                icon: Icons.send_rounded,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: GlassDecoration.subtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.surfaceGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? AppTheme.accentCyan : AppTheme.textHint),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentCyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PriceRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: highlight ? 16 : 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.accentCyan : AppTheme.textPrimary,
              fontSize: highlight ? 18 : 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Image counter
          if (widget.imageUrls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          // Bottom dot indicators
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppTheme.accentCyan
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Item Reviews Section ----

class _ItemReviewsSection extends StatelessWidget {
  final String itemId;
  final bool isOwner;

  const _ItemReviewsSection({required this.itemId, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.itemReviews;
        final avg = reviewProvider.avgRating;
        final total = reviewProvider.totalReviews;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with average
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(text: 'Reviews'),
                if (total > 0)
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${avg.toStringAsFixed(1)} ($total)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Write review button (only for non-owners)
            if (!isOwner)
              GestureDetector(
                onTap: () => _showReviewDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.isDark
                          ? AppTheme.accentBlue.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 18, color: AppTheme.accentCyan),
                      const SizedBox(width: 8),
                      Text('Write a Review',
                          style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

            if (!isOwner && reviews.isNotEmpty) const SizedBox(height: 16),

            // Reviews list
            if (reviews.isEmpty && isOwner)
              Text('No reviews yet', style: TextStyle(color: AppTheme.textHint, fontSize: 14)),

            ...reviews.take(5).map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.isDark ? AppTheme.surfaceGlass : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.isDark
                        ? AppTheme.accentBlue.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryBlue,
                          backgroundImage: review.reviewer?.avatarUrl != null &&
                                  review.reviewer!.avatarUrl.isNotEmpty
                              ? NetworkImage(review.reviewer!.avatarUrl)
                              : null,
                          child: (review.reviewer?.avatarUrl == null ||
                                  review.reviewer!.avatarUrl.isEmpty)
                              ? Text(
                                  (review.reviewer?.name ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review.reviewer?.name ?? 'User',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 14,
                                  color: AppTheme.warning,
                                )),
                              ),
                            ],
                          ),
                        ),
                        if (review.createdAt != null)
                          Text(
                            _formatDate(review.createdAt!),
                            style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                          ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(review.comment,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                    ],
                  ],
                ),
              ),
            )),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  void _showReviewDialog(BuildContext context) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.primaryDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate this Item', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 36,
                      color: AppTheme.warning,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              // Optional comment
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(color: AppTheme.textHint),
                  filled: true,
                  fillColor: AppTheme.surfaceGlass,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () async {
                      Navigator.pop(ctx);
                      final reviewProvider = context.read<ReviewProvider>();
                      final success = await reviewProvider.createItemReview(
                        itemId: itemId,
                        rating: selectedRating,
                        comment: commentCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Review submitted!'
                              : reviewProvider.error ?? 'Failed to submit review'),
                          backgroundColor: success ? AppTheme.success : AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
