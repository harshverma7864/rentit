import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../models/item_model.dart';
import '../../models/review_model.dart';
import '../../services/api_service.dart';
import '../../providers/review_provider.dart';
import '../items/item_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String userId;
  const SellerProfileScreen({super.key, required this.userId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final ApiService _api = ApiService();
  UserModel? _seller;
  List<ItemModel> _items = [];
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get('/auth/user/${widget.userId}'),
        _api.get('/auth/user/${widget.userId}/items'),
        _api.get('/auth/user/${widget.userId}/reviews'),
      ]);

      setState(() {
        _seller = UserModel.fromJson(results[0]['user']);
        _items = (results[1]['items'] as List)
            .map<ItemModel>((e) => ItemModel.fromJson(e))
            .toList();
        _reviews = (results[2]['reviews'] as List)
            .map<ReviewModel>((e) => ReviewModel.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_seller?.name ?? 'Seller Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seller == null
              ? const Center(child: Text('Seller not found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        _buildProfileHeader(),
                        const SizedBox(height: 24),

                        // Stats
                        _buildStats(),
                        const SizedBox(height: 24),

                        // Items
                        Text('Listings (${_items.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_items.isEmpty)
                          const Text('No items listed', style: TextStyle(color: Colors.grey))
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildItemCard(item);
                            },
                          ),
                        const SizedBox(height: 24),

                        // Reviews
                        Text('Reviews (${_reviews.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_reviews.isEmpty)
                          const Text('No reviews yet', style: TextStyle(color: Colors.grey))
                        else
                          ..._reviews.map((r) => _buildReviewCard(r)),
                      ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.2),
              backgroundImage: _seller!.avatarUrl.isNotEmpty ? NetworkImage(_seller!.avatarUrl) : null,
              child: _seller!.avatarUrl.isEmpty
                  ? Text(_seller!.name.isNotEmpty ? _seller!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_seller!.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${_seller!.rating.toStringAsFixed(1)} (${_seller!.totalRatings} reviews)',
                          style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                  if (_seller!.location?.city.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(_seller!.location!.city, style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${_items.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Listings', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${_seller!.completedBookings}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Completed', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(' ${_seller!.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('Rating', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)));
      },
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[800],
                ),
                child: item.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Center(child: Text(item.categoryIcon, style: const TextStyle(fontSize: 40))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${item.pricePerDay.toInt()}/day',
                      style: TextStyle(color: AppTheme.accentCyan, fontSize: 13)),
                  if (item.isBoosted)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Promoted', style: TextStyle(color: Colors.amber, fontSize: 10)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(review.reviewer?.name.isNotEmpty == true
                      ? review.reviewer!.name[0].toUpperCase()
                      : '?'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(review.reviewer?.name ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                )),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment, style: TextStyle(color: Colors.grey[300])),
            ],
          ],
        ),
      ),
    );
  }
}
