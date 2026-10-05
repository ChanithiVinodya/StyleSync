import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes.dart';
import '../../modules/designers/providers/designers_provider.dart';
import '../../modules/designers/models/designer_profile.dart';

class BrowseDesignersScreen extends ConsumerStatefulWidget {
  const BrowseDesignersScreen({super.key});

  @override
  ConsumerState<BrowseDesignersScreen> createState() => _BrowseDesignersScreenState();
}

class _BrowseDesignersScreenState extends ConsumerState<BrowseDesignersScreen> {
  final List<String> _filters = [
    'All',
    'Warm Minimalism',
    'Japandi Woodwork',
    'Organic Modern',
    'Travertine & Brass',
    'Parisian Haussmann',
  ];
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEspresso = const Color(0xFF231713);
    final terracotta = const Color(0xFF8C4A3E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18110E) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text('Designers', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: isDark ? Colors.white : textEspresso),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : textEspresso),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = index),
                  child: Chip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : textEspresso),
                      ),
                    ),
                    backgroundColor: isSelected ? terracotta : (isDark ? const Color(0xFF221915) : Colors.white),
                    side: BorderSide(
                      color: isSelected ? terracotta : (isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Designers List
          Expanded(
            child: ref.watch(designersListProvider).when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8C4A3E))),
              error: (err, stack) => Center(child: Text('Error loading designers', style: TextStyle(color: isDark ? Colors.white : textEspresso))),
              data: (designers) {
                if (designers.isEmpty) {
                  return Center(child: Text('No designers available.', style: TextStyle(color: isDark ? Colors.white : textEspresso)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                  itemCount: designers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final d = designers[index];
                    final portfolioImages = [
                      d.coverUrl.isNotEmpty ? d.coverUrl : 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=300&q=80',
                      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=300&q=80',
                      'https://images.unsplash.com/photo-1600607687644-aac4c3eac7f4?w=300&q=80',
                    ];

                    return GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.designerProfilePath(d.id)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221915) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF382C27) : const Color(0xFFEDE3D8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Portfolio Preview (3 Images)
                            SizedBox(
                              height: 140,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Image.network(
                                        portfolioImages[0],
                                        fit: BoxFit.cover,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Image.network(
                                              portfolioImages[1],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Expanded(
                                            child: Image.network(
                                              portfolioImages[2],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Designer Info
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: NetworkImage(d.avatarUrl.isNotEmpty ? d.avatarUrl : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80'),
                                    onBackgroundImageError: (_, __) {},
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              d.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: terracotta.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${d.matchRate}% Match',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: terracotta,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d.specialty,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC89758)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${d.rating} (${d.reviews})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.location_on_outlined, size: 14, color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973)),
                                            const SizedBox(width: 4),
                                            Text(
                                              d.location,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
