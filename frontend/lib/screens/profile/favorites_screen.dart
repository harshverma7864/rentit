import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/favorite_provider.dart';
import '../items/item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('My Favorites', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favProvider, _) {
          if (favProvider.isLoading && favProvider.favorites.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          if (favProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text('No favorites yet',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap the heart icon on items you like',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.accentCyan,
            onRefresh: () => favProvider.fetchFavorites(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favProvider.favorites.length,
              itemBuilder: (context, index) {
                final item = favProvider.favorites[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.isDark
                            ? AppTheme.accentBlue.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(item.imageUrls.first, fit: BoxFit.cover,
                                    width: 100, height: 100)
                                : Center(child: Text(item.categoryIcon,
                                    style: const TextStyle(fontSize: 32))),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text(item.location?.city ?? '',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.textHint)),
                                const SizedBox(height: 6),
                                Text('₹${item.pricePerDay.toInt()}/day',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentCyan)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.favorite, color: AppTheme.error),
                          onPressed: () => favProvider.toggleFavorite(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
