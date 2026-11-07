import 'package:flutter/material.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArtisanDirectoryPage extends StatefulWidget {
  const ArtisanDirectoryPage({super.key});

  @override
  State<ArtisanDirectoryPage> createState() => _ArtisanDirectoryPageState();
}

class _ArtisanDirectoryPageState extends State<ArtisanDirectoryPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> artisansFuture;

  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    artisansFuture = fetchArtisans();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchArtisans() async {
    final response = await supabase
        .from('artisan_profiles')
        .select(
          'user_id, public_name, bio, craft, district, state, whatsapp_number',
        )
        .order('public_name');

    return List<Map<String, dynamic>>.from(response);
  }

  void openArtisan(Map<String, dynamic> artisan) {
    final route =
        '/?artisan=${Uri.encodeComponent(artisan['user_id'].toString())}';

    debugPrint('NAVIGATING TO: $route');

    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: _buildAppBar(context),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: artisansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text('Unable to load artisans.', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        artisansFuture = fetchArtisans();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final artisans = snapshot.data ?? [];

          final filteredArtisans = artisans.where((artisan) {
            final query = searchQuery.trim().toLowerCase();

            if (query.isEmpty) return true;

            final searchableText = [
              artisan['public_name'],
              artisan['craft'],
              artisan['district'],
              artisan['state'],
            ].where((value) => value != null).join(' ').toLowerCase();

            return searchableText.contains(query);
          }).toList();

          return Column(
            children: [
              // Header band
              _buildHeroSection(artisans.length),

              // Search field
              _buildSearchBar(),

              // Grid
              Expanded(
                child: filteredArtisans.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(filteredArtisans),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.textBody,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Artisan Directory', style: AppTextStyles.navBrand),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildHeroSection(int count) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meet the makers',
                      style: AppTextStyles.headingLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discover skilled artisans across India and explore '
                      'their handcrafted creations.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      'Artisans',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: TextField(
            controller: searchController,
            style: AppTextStyles.bodyMedium,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, craft, or location…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 36,
              color: AppColors.primaryMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text('No matching artisans', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Try a different name, craft, or location.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> artisans) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1000
            ? 3
            : width >= 600
            ? 2
            : 1;

        final padding = width < 500 ? 16.0 : 24.0;
        final spacing = width < 500 ? 12.0 : 18.0;

        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: columns == 1 ? 2.6 : 1.85,
          ),
          itemCount: artisans.length,
          itemBuilder: (context, index) {
            final artisan = artisans[index];

            final location = [artisan['district'], artisan['state']]
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');

            return _ArtisanCard(
              artisan: artisan,
              location: location,
              onTap: () => openArtisan(artisan),
            );
          },
        );
      },
    );
  }
}

// ───────────────────────────────────────────────
//  Artisan Card
// ───────────────────────────────────────────────

class _ArtisanCard extends StatefulWidget {
  final Map<String, dynamic> artisan;
  final String location;
  final VoidCallback onTap;

  const _ArtisanCard({
    required this.artisan,
    required this.location,
    required this.onTap,
  });

  @override
  State<_ArtisanCard> createState() => _ArtisanCardState();
}

class _ArtisanCardState extends State<_ArtisanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final artisan = widget.artisan;
    final name = artisan['public_name'] ?? 'Artisan';
    final craft = artisan['craft'] as String?;
    final bio = artisan['bio'] as String?;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColors.primaryMuted : AppColors.border,
            ),
            color: AppColors.surfaceCard,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + avatar row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ArtisanAvatar(radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                        ),
                        if (craft != null) ...[
                          const SizedBox(height: 4),
                          CraftBadge(label: craft),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Bio
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
              ],

              const Spacer(),

              // Footer: location + CTA
              Row(
                children: [
                  if (widget.location.isNotEmpty) ...[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  AnimatedSlide(
                    offset: _hovered ? const Offset(0.2, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View profile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryMuted,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.primaryMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
