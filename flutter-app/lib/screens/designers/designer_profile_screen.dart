import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../modules/designers/providers/designers_provider.dart';
import '../../routes.dart';

class DesignerProfileScreen extends ConsumerWidget {
  final String? id;
  const DesignerProfileScreen({super.key, this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No Designer ID provided.')),
      );
    }

    final asyncProfile = ref.watch(designerProfileProvider(id!));

    return asyncProfile.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF8C4A3E))),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading designer: $err')),
      ),
      data: (designer) {
        final coverUrl = designer.coverUrl.isNotEmpty ? designer.coverUrl : 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=600&q=80';
        final avatarUrl = designer.avatarUrl.isNotEmpty ? designer.avatarUrl : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80';
        final portfolio = [
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=300&q=80',
          'https://images.unsplash.com/photo-1600607687644-aac4c3eac7f4?w=300&q=80',
          'https://images.unsplash.com/photo-1593696140826-c58b021acf8b?w=300&q=80',
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300&q=80',
        ];
        final reviewsList = [
          {
            'client': 'Elena Vance',
            'rating': 5,
            'text': 'Aria completely transformed our living room. She understood our vision immediately and brought in warmth we didn\'t know was missing.',
            'date': '2 months ago',
          },
          {
            'client': 'Marcus Taylor',
            'rating': 5,
            'text': 'Incredible attention to detail. The materials she selected feel so premium.',
            'date': '4 months ago',
          },
        ];

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
        body: CustomScrollView(
          slivers: [
            // Elegant Sliver App Bar with Cover Image
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : textEspresso,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 10)],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Designer UI not implemented yet')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete Designer UI not implemented yet')),
                    );
                  },
                ),
              ],
            ),

            // Profile Content
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and Header Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: NetworkImage(avatarUrl),
                              onBackgroundImageError: (_, __) {},
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: terracotta,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: terracotta.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            designer.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            designer.specialty,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 20, color: Color(0xFFC89758)),
                              const SizedBox(width: 4),
                              Text(
                                '${designer.rating} (${designer.reviews} reviews)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Icon(Icons.location_on_outlined, size: 18, color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973)),
                              const SizedBox(width: 4),
                              Text(
                                designer.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // About Section
                          Text(
                            'About',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            designer.about,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Portfolio Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Portfolio',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(foregroundColor: terracotta),
                                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: portfolio.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  portfolio[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          // Reviews Section
                          Text(
                            'Recent Reviews',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...reviewsList.map((review) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF221915) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        review['client'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          review['rating'] as int,
                                          (index) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC89758)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review['text'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    review['date'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18110E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8),
              ),
            ),
          ),
          child: ElevatedButton(
            onPressed: () {
              // Initiate quote request
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: terracotta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Request Quote',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    });
  }
}
