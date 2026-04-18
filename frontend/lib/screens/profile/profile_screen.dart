import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../providers/item_provider.dart';
import '../../providers/auth_provider.dart';
import '../items/create_item_screen.dart';
import '../auth/welcome_screen.dart';
import '../chat/chats_list_screen.dart';
import '../wallet/wallet_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'address_screen.dart';
import '../subscription/subscription_screen.dart';
import '../disputes/disputes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchMyItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accentCyan,
          onRefresh: () async {
            await context.read<ItemProvider>().fetchMyItems();
          },
          child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            // Profile header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              (user?.name ?? '').isNotEmpty ? user!.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (user?.location?.city != null &&
                      user!.location!.city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          user.location!.city,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 32),

            // Incomplete profile banner
            if (user != null && !user.isProfileComplete)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.15),
                        Colors.orange.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete your profile',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add ${user.incompleteFields.join(', ')}',
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: 16),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            // Menu options
            _MenuSection(
              title: 'Giver Mode',
              children: [
                _MenuItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'List a New Item',
                  subtitle: 'Start renting out your items',
                  color: AppTheme.accentCyan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateItemScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'My Listings',
                  subtitle: 'Manage your listed items',
                  color: AppTheme.primaryLight,
                  onTap: () => _showMyListings(context),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            _MenuSection(
              title: 'Account',
              children: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  color: AppTheme.accentBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                  subtitle: 'Add money, view transactions',
                  color: AppTheme.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  subtitle: 'View all conversations',
                  color: AppTheme.accentCyan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatsListScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  subtitle: 'View all alerts',
                  color: AppTheme.primaryLight,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Update Location',
                  color: AppTheme.warning,
                  onTap: () => _showLocationDialog(context),
                ),
                _MenuItem(
                  icon: Icons.home_outlined,
                  label: 'My Addresses',
                  subtitle: 'Manage delivery addresses',
                  color: AppTheme.accentBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddressListScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Subscription',
                  subtitle: 'Manage your plan',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.gavel_rounded,
                  label: 'My Disputes',
                  subtitle: 'View raised disputes',
                  color: AppTheme.warning,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DisputesScreen(),
                    ),
                  ),
                ),
                if (user != null && !user.isSeller)
                  _MenuItem(
                    icon: Icons.storefront_rounded,
                    label: 'Become a Seller',
                    subtitle: 'Start listing items to sell',
                    color: AppTheme.success,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.primaryDeep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Become a Seller', style: TextStyle(color: AppTheme.textPrimary)),
                          content: const Text(
                            'Enable seller mode to list items on the marketplace. You can always list items for rent or sale.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Enable'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await auth.becomeSeller();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seller mode enabled!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      }
                    },
                  ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppTheme.error,
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
        ),
      ),
    );
  }

  void _showMyListings(BuildContext context) {
    final items = context.read<ItemProvider>().myItems;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryDeep,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Listings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No items listed yet',
                          style:
                              TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GlassCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(item.categoryIcon,
                                        style: const TextStyle(
                                            fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.pricePerDay.toInt()}/day',
                                        style: TextStyle(
                                          color: AppTheme.accentCyan,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isAvailable
                                        ? AppTheme.success
                                            .withValues(alpha: 0.2)
                                        : AppTheme.error
                                            .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.isAvailable
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: item.isAvailable
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Boost button
                                IconButton(
                                  icon: Icon(
                                    Icons.rocket_launch_outlined,
                                    color: item.isBoosted ? Colors.amber : AppTheme.accentCyan,
                                    size: 20,
                                  ),
                                  onPressed: () => _showBoostDialog(context, item.id, item.title),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppTheme.error, size: 20),
                                  onPressed: () {
                                    context
                                        .read<ItemProvider>()
                                        .deleteItem(item.id);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBoostDialog(BuildContext ctx, String itemId, String itemTitle) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Boost Item', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promote "$itemTitle" to appear first in search results.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            _BoostTile(label: '30 minutes', price: '₹10', onTap: () async {
              Navigator.pop(dialogCtx);
              final success = await ctx.read<ItemProvider>().boostItem(itemId, '30min');
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(success ? 'Item boosted for 30 minutes!' : (ctx.read<ItemProvider>().error ?? 'Failed')),
                ));
                if (success) Navigator.pop(ctx); // Close bottom sheet
              }
            }),
            _BoostTile(label: '1 hour', price: '₹20', onTap: () async {
              Navigator.pop(dialogCtx);
              final success = await ctx.read<ItemProvider>().boostItem(itemId, '1hour');
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(success ? 'Item boosted for 1 hour!' : (ctx.read<ItemProvider>().error ?? 'Failed')),
                ));
                if (success) Navigator.pop(ctx);
              }
            }),
            _BoostTile(label: '3 hours', price: '₹50', onTap: () async {
              Navigator.pop(dialogCtx);
              final success = await ctx.read<ItemProvider>().boostItem(itemId, '3hours');
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(success ? 'Item boosted for 3 hours!' : (ctx.read<ItemProvider>().error ?? 'Failed')),
                ));
                if (success) Navigator.pop(ctx);
              }
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    final cityCtrl = TextEditingController();
    bool isDetecting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.primaryDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Location',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassTextField(
                controller: cityCtrl,
                hintText: 'Enter your city',
                prefixIcon: Icons.location_city_rounded,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isDetecting
                      ? null
                      : () async {
                          setDialogState(() => isDetecting = true);
                          try {
                            LocationPermission perm =
                                await Geolocator.checkPermission();
                            if (perm == LocationPermission.denied) {
                              perm = await Geolocator.requestPermission();
                            }
                            if (perm == LocationPermission.denied ||
                                perm == LocationPermission.deniedForever) {
                              setDialogState(() => isDetecting = false);
                              return;
                            }
                            final pos = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.medium,
                              ),
                            );
                            final placemarks = await placemarkFromCoordinates(
                              pos.latitude,
                              pos.longitude,
                            );
                            if (placemarks.isNotEmpty) {
                              final p = placemarks.first;
                              final city = p.locality ?? p.subAdministrativeArea ?? '';
                              final address =
                                  '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}';
                              cityCtrl.text = city;
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                context.read<AuthProvider>().updateLocation(
                                  pos.latitude,
                                  pos.longitude,
                                  address.trim(),
                                  city,
                                );
                              }
                            }
                          } catch (_) {}
                          setDialogState(() => isDetecting = false);
                        },
                  icon: isDetecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentCyan,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded,
                          color: AppTheme.accentCyan),
                  label: Text(
                    isDetecting ? 'Detecting...' : 'Use GPS Location',
                    style: const TextStyle(color: AppTheme.accentCyan),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (cityCtrl.text.isNotEmpty) {
                  context
                      .read<AuthProvider>()
                      .updateLocation(0, 0, '', cityCtrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: GlassDecoration.card,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _BoostTile extends StatelessWidget {
  final String label;
  final String price;
  final VoidCallback onTap;

  const _BoostTile({required this.label, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
