import '../../../shared/api/api_client.dart';
import '../models/designer_summary.dart';
import '../models/designer_profile.dart';
import '../models/portfolio_item.dart';
import '../models/paged_result.dart';
import '../models/match_score_breakdown.dart';

class DesignersApiService {
  final ApiClient apiClient;

  DesignersApiService({ApiClient? client}) : apiClient = client ?? ApiClient();

  /// Fetches paginated public designer listings matching the exact backend endpoint:
  /// GET /api/designers?style=&budgetMin=&budgetMax=&available=&sort=&page=&pageSize=
  Future<PagedResult<DesignerSummary>> getListings(
      DesignerQueryParameters params) async {
    final query = params.toQueryParameters();
    final uri = Uri(
      path: '/designers',
      queryParameters: query.isNotEmpty ? query : null,
    );

    try {
      final responseData = await apiClient.get(uri.toString());
      if (responseData is Map<String, dynamic>) {
        return PagedResult<DesignerSummary>.fromJson(
          responseData,
          (itemJson) => DesignerSummary.fromJson(itemJson),
        );
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      // Offline fallback: filter in-memory fallback seed designers
      return filterFallbackListings(params);
    }
  }

  /// Fetches a single designer's full profile:
  /// GET /api/designers/{id}
  Future<DesignerProfile> getProfile(int id) async {
    try {
      final responseData = await apiClient.get('/designers/$id');
      if (responseData is Map<String, dynamic>) {
        return DesignerProfile.fromJson(responseData);
      }
      throw Exception('Unexpected profile format');
    } catch (e) {
      final found = fallbackProfiles.firstWhere(
        (p) => p.id == id,
        orElse: () => fallbackProfiles.first,
      );
      return found;
    }
  }

  /// Fetches portfolio items for gallery view:
  /// GET /api/designers/{id}/portfolio
  Future<List<PortfolioItem>> getPortfolioItems(int id) async {
    try {
      final responseData = await apiClient.get('/designers/$id/portfolio');
      if (responseData is List<dynamic>) {
        return responseData
            .map((item) => PortfolioItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Unexpected portfolio format');
    } catch (e) {
      final profile = fallbackProfiles.firstWhere(
        (p) => p.id == id,
        orElse: () => fallbackProfiles.first,
      );
      return profile.portfolioItems;
    }
  }

  /// Fetches the deterministic match-score breakdown for a single designer:
  /// GET /api/designers/{id}/match-score?styleTags=&budgetMin=&budgetMax=
  Future<MatchScoreBreakdownResponse> getMatchScoreBreakdown({
    required int designerId,
    required List<String> styleTags,
    required double budgetMin,
    required double budgetMax,
  }) async {
    final queryParams = <String, String>{};
    for (int i = 0; i < styleTags.length; i++) {
      queryParams['styleTags'] = styleTags.join(',');
    }
    if (budgetMin > 0) {
      queryParams['budgetMin'] = budgetMin.toInt().toString();
    }
    if (budgetMax > 0) {
      queryParams['budgetMax'] = budgetMax.toInt().toString();
    }

    final uri = Uri(
      path: '/designers/$designerId/match-score',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final responseData = await apiClient.get(uri.toString());
      if (responseData is Map<String, dynamic>) {
        return MatchScoreBreakdownResponse.fromJson(responseData);
      }
      throw Exception('Unexpected match score format');
    } catch (e) {
      // Deterministic offline calculation
      final profile = fallbackProfiles.firstWhere(
        (p) => p.id == designerId,
        orElse: () => fallbackProfiles.first,
      );

      // 1. Style tag overlap
      double styleOverlap = 1.0;
      if (styleTags.isNotEmpty) {
        final matches = styleTags
            .where((t) => profile.styleTags
                .any((pt) => pt.toLowerCase() == t.toLowerCase()))
            .length;
        styleOverlap = matches / styleTags.length;
      }

      // 2. Budget range overlap
      double budgetOverlap = 1.0;
      final requestedSpan = budgetMax - budgetMin;
      if (requestedSpan > 0) {
        final overlapStart = profile.priceRangeMin > budgetMin
            ? profile.priceRangeMin
            : budgetMin;
        final overlapEnd = profile.priceRangeMax < budgetMax
            ? profile.priceRangeMax
            : budgetMax;
        final overlapSpan =
            overlapEnd > overlapStart ? (overlapEnd - overlapStart) : 0.0;
        budgetOverlap = (overlapSpan / requestedSpan).clamp(0.0, 1.0);
      }

      // 3. Past rating normalized
      final ratingNormalized = profile.averageRating != null
          ? (profile.averageRating! / 5.0).clamp(0.0, 1.0)
          : 0.5;

      // 4. Availability bonus
      final availabilityBonus =
          (profile.isAvailable && profile.isUnderCapacity) ? 1.0 : 0.0;

      final totalScore = (styleOverlap * 0.40) +
          (budgetOverlap * 0.30) +
          (ratingNormalized * 0.20) +
          (availabilityBonus * 0.10);

      return MatchScoreBreakdownResponse(
        designerId: designerId,
        styleTagOverlapPct: double.parse(styleOverlap.toStringAsFixed(4)),
        budgetRangeOverlapPct: double.parse(budgetOverlap.toStringAsFixed(4)),
        pastRatingNormalized: double.parse(ratingNormalized.toStringAsFixed(4)),
        availabilityBonus: double.parse(availabilityBonus.toStringAsFixed(4)),
        matchScore: double.parse(totalScore.toStringAsFixed(4)),
        averageRating: profile.averageRating,
      );
    }
  }

  static PagedResult<DesignerSummary> filterFallbackListings(
      DesignerQueryParameters query) {
    var filtered = fallbackProfiles
        .where((p) => p.listingStatus == ListingStatus.published)
        .toList();

    // Style & Category filter
    if (query.style != null &&
        query.style!.isNotEmpty &&
        query.style != 'All') {
      final reqStyle = query.style!.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.styleTags.any((t) => t.toLowerCase().contains(reqStyle)) ||
              p.serviceCategories
                  .any((c) => c.toLowerCase().contains(reqStyle)))
          .toList();
    }

    // Keyword Search filter (name, style, bio, services, portfolio titles)
    if (query.search != null && query.search!.trim().isNotEmpty) {
      final terms = query.search!
          .toLowerCase()
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();
      filtered = filtered.where((p) {
        return terms.every((term) =>
            p.displayName.toLowerCase().contains(term) ||
            p.styleTags.any((t) => t.toLowerCase().contains(term)) ||
            p.serviceCategories.any((c) => c.toLowerCase().contains(term)) ||
            p.bio.toLowerCase().contains(term) ||
            p.portfolioItems.any((pi) =>
                pi.title.toLowerCase().contains(term)));
      }).toList();
    }

    // Budget range filter
    if (query.budgetMin != null && query.budgetMin! > 0) {
      filtered =
          filtered.where((p) => p.priceRangeMax >= query.budgetMin!).toList();
    }
    if (query.budgetMax != null && query.budgetMax! > 0) {
      filtered =
          filtered.where((p) => p.priceRangeMin <= query.budgetMax!).toList();
    }

    // Availability filter
    if (query.available != null) {
      if (query.available == true) {
        filtered = filtered
            .where((p) => p.isAvailable && p.isUnderCapacity)
            .toList();
      } else {
        filtered = filtered
            .where((p) => !p.isAvailable || p.isAtCapacity)
            .toList();
      }
    }

    // Sort
    final sort = (query.sort ?? 'newest').toLowerCase();
    if (sort == 'rating' || sort == 'rating_desc' || sort == 'rating_high_low' || sort == 'rating_high_to_low') {
      filtered.sort((a, b) {
        if (a.averageRating == null && b.averageRating == null) return 0;
        if (a.averageRating == null) return 1; // null ratings at end
        if (b.averageRating == null) return -1;
        final cmp = b.averageRating!.compareTo(a.averageRating!);
        return cmp != 0 ? cmp : b.createdAtUtc.compareTo(a.createdAtUtc);
      });
    } else if (sort == 'rating_asc' || sort == 'rating_low_high' || sort == 'rating_low_to_high') {
      filtered.sort((a, b) {
        if (a.averageRating == null && b.averageRating == null) return 0;
        if (a.averageRating == null) return 1; // null ratings at end
        if (b.averageRating == null) return -1;
        final cmp = a.averageRating!.compareTo(b.averageRating!);
        return cmp != 0 ? cmp : a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    } else if (sort == 'price' || sort == 'price_asc' || sort == 'price_low_high' || sort == 'price_low_to_high' || sort == 'rate_asc' || sort == 'rate_low_high' || sort == 'rate_low_to_high') {
      filtered.sort((a, b) {
        final aRate = a.ratePerSqFt > 0 ? a.ratePerSqFt : a.priceRangeMin;
        final bRate = b.ratePerSqFt > 0 ? b.ratePerSqFt : b.priceRangeMin;
        final cmp = aRate.compareTo(bRate);
        if (cmp != 0) return cmp;
        final minCmp = a.priceRangeMin.compareTo(b.priceRangeMin);
        return minCmp != 0 ? minCmp : a.priceRangeMax.compareTo(b.priceRangeMax);
      });
    } else if (sort == 'price_desc' || sort == 'price_high_low' || sort == 'price_high_to_low' || sort == 'rate_desc' || sort == 'rate_high_low' || sort == 'rate_high_to_low') {
      filtered.sort((a, b) {
        final aRate = a.ratePerSqFt > 0 ? a.ratePerSqFt : a.priceRangeMax;
        final bRate = b.ratePerSqFt > 0 ? b.ratePerSqFt : b.priceRangeMax;
        final cmp = bRate.compareTo(aRate);
        if (cmp != 0) return cmp;
        final maxCmp = b.priceRangeMax.compareTo(a.priceRangeMax);
        return maxCmp != 0 ? maxCmp : b.priceRangeMin.compareTo(a.priceRangeMin);
      });
    } else if (sort == 'budget_asc' || sort == 'budget_low_high' || sort == 'budget_low_to_high') {
      filtered.sort((a, b) {
        final cmp = a.priceRangeMin.compareTo(b.priceRangeMin);
        return cmp != 0 ? cmp : a.priceRangeMax.compareTo(b.priceRangeMax);
      });
    } else if (sort == 'budget_desc' || sort == 'budget_high_low' || sort == 'budget_high_to_low') {
      filtered.sort((a, b) {
        final cmp = b.priceRangeMax.compareTo(a.priceRangeMax);
        return cmp != 0 ? cmp : b.priceRangeMin.compareTo(a.priceRangeMin);
      });
    } else if (sort == 'oldest' || sort == 'created_asc') {
      filtered.sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
    } else {
      filtered.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    }

    final totalCount = filtered.length;
    final page = query.page > 0 ? query.page : 1;
    final pageSize = query.pageSize > 0 ? query.pageSize : 10;
    final totalPages = (totalCount / pageSize).ceil();

    final startIndex = (page - 1) * pageSize;
    final pagedItems = (startIndex < totalCount)
        ? filtered.skip(startIndex).take(pageSize).toList()
        : <DesignerProfile>[];

    final summaryItems = pagedItems.map((p) {
      return DesignerSummary(
        id: p.id,
        displayName: p.displayName,
        bio: p.bio,
        styleTags: p.styleTags,
        serviceCategories: p.serviceCategories,
        priceRangeMin: p.priceRangeMin,
        priceRangeMax: p.priceRangeMax,
        ratePerSqFt: p.ratePerSqFt,
        isAvailable: p.isAvailable,
        maxConcurrentProjects: p.maxConcurrentProjects,
        activeProjectCount: p.activeProjectCount,
        remainingCapacity: p.remainingCapacity,
        isUnderCapacity: p.isUnderCapacity,
        isAtCapacity: p.isAtCapacity,
        averageRating: p.averageRating,
        listingStatus: p.listingStatus,
        publishedPortfolioCount: p.portfolioItems
            .where((i) => i.completionStatusBadge == ListingStatus.published)
            .length,
        featuredImageUrl: p.portfolioItems.isNotEmpty
            ? p.portfolioItems.first.imageUrl
            : 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
        createdAtUtc: p.createdAtUtc,
      );
    }).toList();

    return PagedResult<DesignerSummary>(
      items: summaryItems,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages > 0 ? totalPages : 1,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }

  static final List<DesignerProfile> fallbackProfiles = [
    DesignerProfile(
      id: 1,
      userId: 101,
      displayName: 'Jayawardena Architecture & Interiors',
      bio:
          'Award-winning interior studio specializing in tropical modernism, seamless indoor-outdoor flow, and sustainable natural materials.',
      styleTags: const [
        'Tropical Modernism',
        'Minimalist',
        'Sustainable',
        'Contemporary'
      ],
      serviceCategories: const [
        'Full Home Interior',
        'Living Room',
        'Renovation'
      ],
      priceRangeMin: 150000.0,
      priceRangeMax: 600000.0,
      ratePerSqFt: 450.0,
      isAvailable: true,
      maxConcurrentProjects: 3,
      activeProjectCount: 1,
      remainingCapacity: 2,
      isUnderCapacity: true,
      isAtCapacity: false,
      averageRating: 4.85,
      listingStatus: ListingStatus.published,
      createdAtUtc: DateTime.parse('2026-08-15T10:00:00Z'),
      portfolioItems: [
        PortfolioItem(
          id: 1,
          designerProfileId: 1,
          title: 'Bawa-Inspired Courtyard Residence',
          description:
              'A 3,200 sq.ft villa in Pelawatte incorporating exposed brick, timber columns, and an open central reflection pool.',
          imageUrl:
              'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 450k-550k',
          clientInitials: 'K.M.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-08-16T12:00:00Z'),
        ),
        PortfolioItem(
          id: 2,
          designerProfileId: 1,
          title: 'Minimalist Open-Concept Living Room',
          description:
              'Natural teak cabinetry paired with polished cement floors and diffused daylighting fixtures.',
          imageUrl:
              'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 200k-300k',
          clientInitials: 'S.D.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-08-20T15:30:00Z'),
        ),
      ],
    ),
    DesignerProfile(
      id: 2,
      userId: 102,
      displayName: 'Studio Amara Design',
      bio:
          'Curating cozy, vibrant, Scandinavian and bohemian residential living spaces with artisanal bespoke furniture and curated color palettes.',
      styleTags: const ['Boho Chic', 'Scandinavian', 'Contemporary'],
      serviceCategories: const [
        'Apartment Interior',
        'Bedroom Design',
        'Color Consultation'
      ],
      priceRangeMin: 100000.0,
      priceRangeMax: 350000.0,
      ratePerSqFt: 320.0,
      isAvailable: true,
      maxConcurrentProjects: 2,
      activeProjectCount: 2,
      remainingCapacity: 0,
      isUnderCapacity: false,
      isAtCapacity: true, // At capacity
      averageRating: 4.90,
      listingStatus: ListingStatus.published,
      createdAtUtc: DateTime.parse('2026-08-18T09:00:00Z'),
      portfolioItems: [
        PortfolioItem(
          id: 4,
          designerProfileId: 2,
          title: 'Warm Bohemian Haven',
          description:
              'Earthy terracotta tones, macramé accents, cane furniture, and layered woven rugs in Havelock City.',
          imageUrl:
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 150k-250k',
          clientInitials: 'A.R.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-08-19T10:00:00Z'),
        ),
      ],
    ),
    DesignerProfile(
      id: 3,
      userId: 103,
      displayName: 'Urban Loft Atelier',
      bio:
          'Raw textures, exposed brick, dark metal accents, and modern luxury tailored for trendy urban apartments and collaborative workspaces.',
      styleTags: const ['Industrial', 'Modern Contemporary', 'Rustic'],
      serviceCategories: const [
        'Commercial & Office',
        'Full Home Interior',
        'Kitchen & Dining'
      ],
      priceRangeMin: 200000.0,
      priceRangeMax: 750000.0,
      ratePerSqFt: 520.0,
      isAvailable: true,
      maxConcurrentProjects: 4,
      activeProjectCount: 1,
      remainingCapacity: 3,
      isUnderCapacity: true,
      isAtCapacity: false,
      averageRating: 4.75,
      listingStatus: ListingStatus.published,
      createdAtUtc: DateTime.parse('2026-08-22T14:00:00Z'),
      portfolioItems: [
        PortfolioItem(
          id: 7,
          designerProfileId: 3,
          title: 'Converted Industrial Penthouse',
          description:
              'Double-height ceilings with black steel loft stairs, exposed concrete pillars, and reclaimed timber dining table.',
          imageUrl:
              'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 500k-700k',
          clientInitials: 'D.P.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-08-23T11:00:00Z'),
        ),
      ],
    ),
    DesignerProfile(
      id: 6,
      userId: 106,
      displayName: 'Luxe Heritage Interiors',
      bio:
          'High-end bespoke luxury interior styling for luxury penthouses, presidential suites, and prestigious heritage estates.',
      styleTags: const ['Classic Luxury', 'Art Deco', 'Colonial Revival'],
      serviceCategories: const [
        'Penthouse',
        'Master Suite',
        'Dining & Entertainment'
      ],
      priceRangeMin: 500000.0,
      priceRangeMax: 2500000.0,
      ratePerSqFt: 950.0,
      isAvailable: true,
      maxConcurrentProjects: 2,
      activeProjectCount: 1,
      remainingCapacity: 1,
      isUnderCapacity: true,
      isAtCapacity: false,
      averageRating: 5.00,
      listingStatus: ListingStatus.published,
      createdAtUtc: DateTime.parse('2026-09-01T11:00:00Z'),
      portfolioItems: [
        PortfolioItem(
          id: 15,
          designerProfileId: 6,
          title: 'Grand Marble & Velvet Penthouse Salon',
          description:
              'Calacatta gold marble wall cladding, emerald velvet bespoke sofa, and 24k gold leaf ceiling molding.',
          imageUrl:
              'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 1.5M-2.5M',
          clientInitials: 'E.B.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-09-02T13:00:00Z'),
        ),
        PortfolioItem(
          id: 16,
          designerProfileId: 6,
          title: 'Art Deco Formal Dining Suite',
          description:
              'Smoked glass 12-seater dining table, fluted walnut panels, and crystal chandelier.',
          imageUrl:
              'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 1M-1.8M',
          clientInitials: 'O.S.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-09-03T14:00:00Z'),
        ),
        PortfolioItem(
          id: 17,
          designerProfileId: 6,
          title: 'Presidential Master Dressing Room',
          description:
              'Integrated backlit glass wardrobes, central island with velvet watch trays, and full-length vanity mirror.',
          imageUrl:
              'https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 800k-1.2M',
          clientInitials: 'A.K.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-09-04T16:00:00Z'),
        ),
      ],
    ),
    DesignerProfile(
      id: 7,
      userId: 107,
      displayName: 'Greenline Eco Spaces',
      bio:
          'Pioneering biophilic design incorporating vertical green walls, natural cross-ventilation, and carbon-neutral recycled materials.',
      styleTags: const ['Biophilic', 'Eco-friendly', 'Modern Farmhouse'],
      serviceCategories: const ['Eco-Home', 'Balcony & Terrace', 'Living Room'],
      priceRangeMin: 120000.0,
      priceRangeMax: 400000.0,
      ratePerSqFt: 360.0,
      isAvailable: true,
      maxConcurrentProjects: 3,
      activeProjectCount: 0,
      remainingCapacity: 3,
      isUnderCapacity: true,
      isAtCapacity: false,
      averageRating: null, // Nullable averageRating
      listingStatus: ListingStatus.published,
      createdAtUtc: DateTime.parse('2026-09-05T09:00:00Z'),
      portfolioItems: [
        PortfolioItem(
          id: 18,
          designerProfileId: 7,
          title: 'Biophilic Eco Living Room & Indoor Garden',
          description:
              'Integrated self-watering green wall, reclaimed rubberwood coffee table, and VOC-free lime plaster.',
          imageUrl:
              'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
          budgetRangeLabel: 'LKR 200k-350k',
          clientInitials: 'L.T.',
          completionStatusBadge: ListingStatus.published,
          createdAtUtc: DateTime.parse('2026-09-06T10:00:00Z'),
        ),
      ],
    ),
  ];
}
