import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item_model.dart';
import '../items/item_detail_screen.dart';
import '../items/browse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemProvider = context.read<ItemProvider>();
      itemProvider.fetchItems(refresh: true);
      itemProvider.fetchRecommended();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryDeep],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accentCyan,
          onRefresh: () => context.read<ItemProvider>().fetchItems(refresh: true),
          child: CustomScrollView(
            slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey, ${(auth.user?.name ?? '').isNotEmpty ? auth.user!.name.split(' ').first : 'there'} 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: AppTheme.accentCyan),
                                const SizedBox(width: 4),
                                Text(
                                  auth.user?.location?.city ?? 'Set your location',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn().slideX(begin: -0.1),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryBlue,
                          backgroundImage: auth.user?.avatarUrl != null && auth.user!.avatarUrl.isNotEmpty
                              ? NetworkImage(auth.user!.avatarUrl)
                              : null,
                          child: (auth.user?.avatarUrl == null || auth.user!.avatarUrl.isEmpty)
                              ? Text(
                                  (auth.user?.name ?? '').isNotEmpty ? auth.user!.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search bar
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BrowseScreen()),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGlass,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.accentBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded,
                                    color: AppTheme.accentCyan),
                                const SizedBox(width: 12),
                                Text(
                                  'Search items to rent...',
                                  style: TextStyle(
                                    color: AppTheme.textHint,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryChip(icon: '📱', label: 'Electronics', category: 'electronics'),
                        _CategoryChip(icon: '🚗', label: 'Vehicles', category: 'vehicles'),
                        _CategoryChip(icon: '🪑', label: 'Furniture', category: 'furniture'),
                        _CategoryChip(icon: '👗', label: 'Clothing', category: 'clothing'),
                        _CategoryChip(icon: '⚽', label: 'Sports', category: 'sports'),
                        _CategoryChip(icon: '🔧', label: 'Tools', category: 'tools'),
                        _CategoryChip(icon: '📚', label: 'Books', category: 'books'),
                        _CategoryChip(icon: '🎉', label: 'Party', category: 'party'),
                        _CategoryChip(icon: '📷', label: 'Cameras', category: 'cameras'),
                        _CategoryChip(icon: '📦', label: 'Other', category: 'other'),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recommended section
            Consumer<ItemProvider>(
              builder: (context, provider, _) {
                if (provider.recommendedItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text(
                          'Recommended For You',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.recommendedItems.length,
                          itemBuilder: (context, index) {
                            final item = provider.recommendedItems[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceGlass,
                                  borderRadius: BorderRadius.circular(16),
                                  border: item.isBoosted
                                      ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5)
                                      : Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            child: Center(
                                              child: item.imageUrls.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                      child: Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity),
                                                    )
                                                  : Text(item.categoryIcon, style: const TextStyle(fontSize: 36)),
                                            ),
                                          ),
                                          if (item.isBoosted)
                                            Positioned(
                                              top: 6, left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Promoted', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
                                          Text('₹${item.pricePerDay.toInt()}/day',
                                              style: TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),

            // Trending items header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Near You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BrowseScreen()),
                      ),
                      child: Text(
                        'See All',
                        style: TextStyle(color: AppTheme.accentCyan),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ),

            // Item grid
            Consumer<ItemProvider>(
              builder: (context, itemProvider, _) {
                if (itemProvider.isLoading && itemProvider.items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                  );
                }

                if (itemProvider.items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: AppTheme.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'No items available yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to list an item!',
                              style: TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = itemProvider.items[index];
                        return _ItemCard(item: item)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 * (index % 6)));
                      },
                      childCount: itemProvider.items.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String icon;
  final String label;
  final String category;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BrowseScreen(initialCategory: category),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Stack(
              children: [
                Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.accentCyan.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Center(
                child: item.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          item.imageUrls.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                          errorBuilder: (_, __, ___) => Text(
                            item.categoryIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      )
                    : Text(
                        item.categoryIcon,
                        style: const TextStyle(fontSize: 40),
                      ),
              ),
                ),
                if (item.isBoosted)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Promoted', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (!item.hasInAppDelivery)
                  Positioned(
                    top: 8, right: 8,
                    child: Tooltip(
                      message: 'No in-app delivery protection',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location?.city ?? '',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.pricePerDay.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      Text(
                        '/day',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
