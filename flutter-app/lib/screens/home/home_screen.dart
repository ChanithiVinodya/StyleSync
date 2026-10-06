import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/designers/designer_filter_provider.dart';
import '../../config/style_constants.dart';
import '../../shared/widgets/main_bottom_nav_bar.dart';
import '../../routes.dart';
import '../designers/browse_designers_screen.dart';
import '../requests/my_requests_screen.dart';
import '../../modules/quotes_contracts/quotes_contracts_page.dart';
import '../progress/project_timeline_screen.dart';
import '../splash/splash_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  bool _isLoading = false;
  int _searchPlaceholderIndex = 0;
  late AnimationController _shimmerController;

  final List<String> _searchPlaceholders = [
    "Try 'Curved bouclé sofa nook'...",
    "Try 'Japandi travertine table'...",
    "Try 'Warm minimalist lighting'...",
    "Try 'Walnut dining credenza'...",
  ];

  final Map<String, dynamic> _mockDashboardSummary = {
    'clientName': 'Elena',
    'pendingRequests': 2,
    'quotesAwaiting': 1,
    'projectsInProgress': 1,
  };

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Living Room',
      'assetPath': 'assets/images/living room.jpg',
      'fallbackUrl': 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Dining',
      'assetPath': 'assets/images/dinning room.jpg',
      'fallbackUrl': 'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Bedroom',
      'assetPath': null,
      'fallbackUrl': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Kitchen',
      'assetPath': 'assets/images/kitchen1.jpg',
      'fallbackUrl': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80',
    },
  ];

  final List<Map<String, dynamic>> _mockMatchedDesigners = [
    {
      'id': 'des-101',
      'name': 'Aria Sterling',
      'specialty': 'Warm Minimalist & Japandi',
      'matchRate': '98%',
      'rating': '4.95',
      'reviews': '48',
      'avatarUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'des-102',
      'name': 'Julian Thorne',
      'specialty': 'Modern Organic & Terracotta',
      'matchRate': '95%',
      'rating': '4.92',
      'reviews': '36',
      'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'des-103',
      'name': 'Elena Rostova',
      'specialty': 'Architectural Renovation',
      'matchRate': '92%',
      'rating': '4.88',
      'reviews': '52',
      'avatarUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
    },
  ];

  /// Resilient image loader that prioritizes local hardcoded assets and seamlessly falls back if web server has not reloaded
  Widget _buildSafeImage({
    String? assetPath,
    String? fallbackUrl,
    String? imagePath,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    Widget? errorWidget,
  }) {
    String? effectiveAsset = assetPath;
    String? effectiveUrl = fallbackUrl;

    if (imagePath != null && imagePath.isNotEmpty) {
      final clean = imagePath.trim();
      if (clean.startsWith('http://') || clean.startsWith('https://')) {
        effectiveUrl ??= clean;
      } else {
        effectiveAsset ??= clean.startsWith('/') ? clean.substring(1) : clean;
      }
    }

    if (effectiveAsset != null && effectiveAsset.isNotEmpty) {
      final cleanAsset = effectiveAsset.startsWith('/') ? effectiveAsset.substring(1) : effectiveAsset;
      return Image.asset(
        cleanAsset,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) {
          if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
            return Image.network(
              effectiveUrl,
              fit: fit,
              alignment: alignment,
              errorBuilder: (_, __, ___) => _defaultImageFallback(errorWidget),
            );
          }
          return _defaultImageFallback(errorWidget);
        },
      );
    } else if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      return Image.network(
        effectiveUrl,
        fit: fit,
        alignment: alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1C1411).withValues(alpha: 0.15),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8C4A3E),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _defaultImageFallback(errorWidget);
        },
      );
    }

    return _defaultImageFallback(errorWidget);
  }

  Widget _defaultImageFallback(Widget? errorWidget) {
    return errorWidget ??
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E2824), Color(0xFF1A1715)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.style_outlined, color: Color(0xFFD48270), size: 24),
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _showFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1715) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Filter Style & Designers',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Warm Minimalism', true),
                  _buildFilterChip('Japandi Woodwork', false),
                  _buildFilterChip('Organic Modern', false),
                  _buildFilterChip('Travertine & Brass', false),
                  _buildFilterChip('Parisian Haussmann', false),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _onBottomNavTapped(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF231713),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8C4A3E) : const Color(0xFFF4ECE4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF231713),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const bgSand = Color(0xFFFAF7F2);
    const darkBg = Color(0xFF120C0A);
    const textEspresso = Color(0xFF231713);
    const terracotta = Color(0xFF8C4A3E);
    const honeyAmber = Color(0xFFC89758);

    return Scaffold(
      backgroundColor: isDark ? darkBg : bgSand,
      body: SafeArea(
        child: Stack(
          children: [
            // Persistent Tab Body using IndexedStack
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Tab 0: Luxury Home Feed
                  _buildHomeFeed(isDark, textEspresso, terracotta, honeyAmber),

                  // Tab 1: Designers Screen
                  _buildTabWrapper(const BrowseDesignersScreen()),

                  // Tab 2: Requests Screen
                  _buildTabWrapper(const MyRequestsScreen()),

                  // Tab 3: Quotes Screen
                  _buildTabWrapper(const QuotesContractsPage()),

                  // Tab 4: Progress Screen
                  _buildTabWrapper(const ProjectTimelineScreen()),
                ],
              ),
            ),

            // Persistent Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MainBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onBottomNavTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWrapper(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 78),
      child: child,
    );
  }

  // ==========================================
  // HOME DASHBOARD FEED
  // ==========================================
  Widget _buildHomeFeed(bool isDark, Color textEspresso, Color terracotta, Color honeyAmber) {
    return RefreshIndicator(
      color: terracotta,
      onRefresh: () async {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(milliseconds: 700));
        setState(() {
          _isLoading = false;
          _searchPlaceholderIndex = (_searchPlaceholderIndex + 1) % _searchPlaceholders.length;
        });
      },
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 350),
        crossFadeState: _isLoading ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Brand Header & Action Icons
              _buildHeader(isDark, textEspresso, terracotta, honeyAmber),
              const SizedBox(height: 18),

              // 2. Greeting Row
              _buildGreetingRow(isDark, textEspresso),
              const SizedBox(height: 16),

              // 3. Search & Style Discovery Bar
              _buildSearchBar(isDark, textEspresso),
              const SizedBox(height: 22),

              // 4. Unboxed Architectural Hero Section (Full-bleed seamless gradient)
              _buildUnboxedHero(context, isDark, textEspresso, terracotta),
              const SizedBox(height: 32),

              // 5. Categories Section (Horizontal Snapping)
              _buildCategoriesSection(isDark, textEspresso, terracotta),
              const SizedBox(height: 32),

              // 5b. Styles Section (Directly below Categories)
              _buildStylesSection(isDark, textEspresso, terracotta),
              const SizedBox(height: 32),

              // 6. Project Activity Carousel (Status & Metrics)
              _buildProjectActivitySection(context, isDark, textEspresso, terracotta),
              const SizedBox(height: 30),

              // 7. Quick-Access Shortcut Cards (Dual Grid)
              _buildShortcutGrid(context, isDark, textEspresso, terracotta),
              const SizedBox(height: 30),

              // 8. Matched Designers Carousel
              _buildMatchedDesignersSection(context, isDark, textEspresso, terracotta),
              const SizedBox(height: 20),
            ],
          ),
        ),
        secondChild: _buildSkeletonLoading(isDark),
      ),
    );
  }

  // ==========================================
  // SECTION 1: HEADER & ACTIONS
  // ==========================================
  Widget _buildHeader(bool isDark, Color textEspresso, Color terracotta, Color honeyAmber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand Monogram & Title
        Expanded(
          child: Row(
            children: [
              // Luxury Squircle Logo with Splash Screen Two-Tone Monogram
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1715) : const Color(0xFFEFE7DC),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E2824)
                        : const Color(0xFFD5C6B1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(28, 28),
                    painter: MonogramHandwritingPainter(
                      progress: 1.0,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'StyleSync',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? const Color(0xFFFAF8F5) : textEspresso,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'DESIGN MARKETPLACE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Action Buttons: Notifications & Profile
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircularIconButton(
              icon: Icons.notifications_none_rounded,
              badgeCount: '3',
              badgeColor: terracotta,
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8C4A3E),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildSafeImage(
                        imagePath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: const Color(0xFF8C4A3E),
                          child: const Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E4334),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF12100E) : Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.person, size: 8, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required String? badgeCount,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1715) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 19,
              color: isDark ? const Color(0xFFFAF8F5) : const Color(0xFF231713),
            ),
          ),
          if (badgeCount != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF12100E) : Colors.white, width: 1.5),
                ),
                child: Text(
                  badgeCount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 2: GREETING ROW
  // ==========================================
  Widget _buildGreetingRow(bool isDark, Color textEspresso) {
    final authUser = ref.watch(currentUserProvider);
    final String clientName = authUser?.name.isNotEmpty == true
        ? authUser!.name.trim().split(' ').first
        : _mockDashboardSummary['clientName'];

    return Row(
      children: [
        Text(
          'Good afternoon, ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
          ),
        ),
        Text(
          clientName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFFAF8F5) : textEspresso,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          '✨',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 3: SEARCH & DISCOVERY BAR
  // ==========================================
  Widget _buildSearchBar(bool isDark, Color textEspresso) {
    return GestureDetector(
      onTap: _showFilterModal,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1715) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _searchPlaceholders[_searchPlaceholderIndex],
                  key: ValueKey<int>(_searchPlaceholderIndex),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF85756E) : const Color(0xFF8A7973),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                size: 19,
                color: isDark ? const Color(0xFFD48270) : const Color(0xFF8C4A3E),
              ),
              onPressed: _showFilterModal,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4: UNBOXED ARCHITECTURAL HERO (SEAMLESS FULL-BLEED)
  // ==========================================
  Widget _buildUnboxedHero(BuildContext context, bool isDark, Color textEspresso, Color terracotta) {
    final bgColor = isDark ? const Color(0xFF161311) : const Color(0xFFF7F1EA);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 255),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: bgColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Full-width background image aligned to the right
            Positioned.fill(
              child: _buildSafeImage(
                imagePath: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),

            // Continuous horizontal gradient across the entire container (eliminates all vertical lines)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      bgColor,
                      bgColor.withValues(alpha: 0.98),
                      bgColor.withValues(alpha: 0.85),
                      bgColor.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.38, 0.55, 0.78, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle vertical bottom scrim for text legibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      bgColor.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Where your space\nfinds its style.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: isDark ? const Color(0xFFFAF8F5) : textEspresso,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos. Get matched with a designer.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // CTA Button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.newRequest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF231713),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start a request',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Social Proof: 3 Overlapping Avatars + Micro metric
                  Row(
                    children: [
                      SizedBox(
                        width: 58,
                        height: 24,
                        child: Stack(
                          children: [
                            _buildMiniAvatar('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80', 0),
                            _buildMiniAvatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80', 16),
                            _buildMiniAvatar('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80', 32),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Matched in ~24h  •  1,400+ styled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                          ),
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildMiniAvatar(String url, double leftOffset) {
    return Positioned(
      left: leftOffset,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipOval(
          child: _buildSafeImage(
            imagePath: url,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: const Color(0xFF8C4A3E),
              child: const Icon(Icons.person, size: 12, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable visual card for Categories & Styles horizontal carousels
  Widget _buildVisualDiscoveryCard({
    required String title,
    String? assetPath,
    String? fallbackUrl,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 142,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSafeImage(
                assetPath: assetPath,
                fallbackUrl: fallbackUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF231713),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: CATEGORIES CAROUSEL
  // ==========================================
  Widget _buildCategoriesSection(bool isDark, Color textEspresso, Color terracotta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Curated furniture and spaces for every room',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal scrolling track
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildVisualDiscoveryCard(
                title: cat['title'] as String,
                assetPath: cat['assetPath'] as String?,
                fallbackUrl: cat['fallbackUrl'] as String?,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.newRequest,
                    arguments: cat['title'] as String,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 5B: STYLES CAROUSEL
  // ==========================================
  Widget _buildStylesSection(bool isDark, Color textEspresso, Color terracotta) {
    const styles = AppStyleConstants.homeStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header matching Categories exactly
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Styles',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find designers who match your taste',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ref.read(designerFilterProvider.notifier).resetFilters();
                _onBottomNavTapped(1);
              },
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: terracotta,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 16, color: terracotta),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal scrolling track reusing exact same card treatment
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: styles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final styleItem = styles[index];
              return _buildVisualDiscoveryCard(
                title: styleItem.title,
                assetPath: styleItem.assetPath,
                fallbackUrl: styleItem.fallbackUrl,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.newRequest,
                    arguments: {
                      'styleTags': [styleItem.title],
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 6: PROJECT ACTIVITY CAROUSEL
  // ==========================================
  Widget _buildProjectActivitySection(BuildContext context, bool isDark, Color textEspresso, Color terracotta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Pulsing Live Beacon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Project Activity',
              style: GoogleFonts.playfairDisplay(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                  SizedBox(width: 5),
                  Text(
                    'Live Activity',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Activity Cards Track
        SizedBox(
          height: 155,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildActivityCard(
                context: context,
                isDark: isDark,
                statusTag: 'Under Review',
                tagColor: const Color(0xFFC89758),
                metric: '2',
                title: 'Requests Pending',
                subtitle: 'Reviewing photos & measurements',
                progressText: '65% matched',
                progressValue: 0.65,
                onTap: () => _onBottomNavTapped(2),
              ),
              const SizedBox(width: 14),
              _buildActivityCard(
                context: context,
                isDark: isDark,
                statusTag: 'Action Needed',
                tagColor: const Color(0xFF8C4A3E),
                metric: '1',
                title: 'Quotes Awaiting',
                subtitle: 'Tribeca Suite • \$14,500 package',
                progressText: 'Ready for signature',
                progressValue: 0.90,
                onTap: () => _onBottomNavTapped(3),
              ),
              const SizedBox(width: 14),
              _buildActivityCard(
                context: context,
                isDark: isDark,
                statusTag: 'On Track',
                tagColor: const Color(0xFF10B981),
                metric: '1',
                title: 'Active Commission',
                subtitle: 'Phase 2 of 4 • Living room styling',
                progressText: 'Milestone due Oct 12',
                progressValue: 0.50,
                onTap: () => _onBottomNavTapped(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required bool isDark,
    required String statusTag,
    required Color tagColor,
    required String metric,
    required String title,
    required String subtitle,
    required String progressText,
    required double progressValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 245,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1715) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusTag,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: tagColor,
                    ),
                  ),
                ),
                Text(
                  metric,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tagColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFAF5F0) : const Color(0xFF231713),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFB5A49B) : const Color(0xFF6E5D53),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF8C4A3E)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 4.5,
                    backgroundColor: isDark ? const Color(0xFF2E2824) : const Color(0xFFEFE7DE),
                    valueColor: AlwaysStoppedAnimation<Color>(tagColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 7: QUICK-ACCESS SHORTCUT GRID
  // ==========================================
  Widget _buildShortcutGrid(BuildContext context, bool isDark, Color textEspresso, Color terracotta) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onBottomNavTapped(3),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1715) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.draw_outlined, size: 22, color: terracotta),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89758).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Sign Ready',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC89758),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contract Status',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Awaiting signature',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Review doc',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: terracotta,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: terracotta),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: () => _onBottomNavTapped(4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1715) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.timeline_rounded, size: 22, color: terracotta),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Thu 2 PM',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Project Timeline',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Next: Site visit & review',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Track phases',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: terracotta,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: terracotta),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 8: MATCHED DESIGNERS CAROUSEL
  // ==========================================
  Widget _buildMatchedDesignersSection(BuildContext context, bool isDark, Color textEspresso, Color terracotta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Designers',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Curated matches based on your room aesthetics',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _onBottomNavTapped(1),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: terracotta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _mockMatchedDesigners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final d = _mockMatchedDesigners[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.designerProfilePath(d['id'])),
                child: Container(
                  width: 165,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1715) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E2824) : const Color(0xFFEDE3D8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E2824) : const Color(0xFFE8DFD5),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildSafeImage(
                                imagePath: d['avatarUrl'],
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: const Color(0xFF8C4A3E),
                                  child: Center(
                                    child: Text(
                                      d['name'][0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8C4A3E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d['matchRate'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            d['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFAF5F0) : textEspresso,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d['specialty'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF9B8B82) : const Color(0xFF8A7973),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC89758)),
                          const SizedBox(width: 3),
                          Text(
                            '${d['rating']} (${d['reviews']})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFFAF5F0) : const Color(0xFF231713),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  // ==========================================
  // SECTION 10: 1:1 SHIMMER SKELETON ENGINE
  // ==========================================
  Widget _buildSkeletonLoading(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1715),
                  const Color(0xFF2E2824),
                  const Color(0xFF1A1715),
                ]
              : [
                  const Color(0xFFEFE7DE),
                  const Color(0xFFFAF7F2),
                  const Color(0xFFEFE7DE),
                ],
          stops: [
            math.max(0.0, _shimmerController.value - 0.3),
            _shimmerController.value,
            math.min(1.0, _shimmerController.value + 0.3),
          ],
        );

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _skeletonBox(44, 44, 13, shimmerGradient),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _skeletonBox(90, 16, 6, shimmerGradient),
                          const SizedBox(height: 6),
                          _skeletonBox(120, 10, 4, shimmerGradient),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _skeletonCircle(38, shimmerGradient),
                      const SizedBox(width: 8),
                      _skeletonCircle(38, shimmerGradient),
                      const SizedBox(width: 8),
                      _skeletonCircle(40, shimmerGradient),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Greeting Skeleton
              _skeletonBox(180, 20, 6, shimmerGradient),
              const SizedBox(height: 16),

              // Search Bar Skeleton
              _skeletonBox(double.infinity, 52, 30, shimmerGradient),
              const SizedBox(height: 22),

              // Hero Skeleton
              _skeletonBox(double.infinity, 250, 26, shimmerGradient),
              const SizedBox(height: 32),

              // Categories Skeleton
              _skeletonBox(140, 22, 6, shimmerGradient),
              const SizedBox(height: 14),
              Row(
                children: [
                  _skeletonBox(140, 195, 22, shimmerGradient),
                  const SizedBox(width: 14),
                  _skeletonBox(140, 195, 22, shimmerGradient),
                ],
              ),
              const SizedBox(height: 32),

              // Project Activity Skeleton
              _skeletonBox(160, 22, 6, shimmerGradient),
              const SizedBox(height: 14),
              _skeletonBox(240, 155, 22, shimmerGradient),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBox(double width, double height, double radius, Gradient gradient) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
      ),
    );
  }

  Widget _skeletonCircle(double size, Gradient gradient) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}
