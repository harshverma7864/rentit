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
                                  (user.name)[0].toUpperCase(),
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
                              (user?.name ?? 'U')[0].toUpperCase(),
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
