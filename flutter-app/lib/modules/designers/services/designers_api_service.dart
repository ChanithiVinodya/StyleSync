import 'dart:convert';
import '../../../shared/api/api_client.dart';
import '../models/designer_summary.dart';
import '../models/designer_profile.dart';
import '../models/portfolio_item.dart';
import '../models/paged_result.dart';

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
      return _filterFallbackListings(params);
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
      final found = _fallbackProfiles.firstWhere(
        (p) => p.id == id,
        orElse: () => _fallbackProfiles.first,
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
      final profile = _fallbackProfiles.firstWhere(
        (p) => p.id == id,
        orElse: () => _fallbackProfiles.first,
      );
      return profile.portfolioItems;
    }
  }

  PagedResult<DesignerSummary> _filterFallbackListings(
      DesignerQueryParameters query) {
    var filtered = _fallbackProfiles
        .where((p) => p.listingStatus == ListingStatus.published)
        .toList();

    // Style filter
    if (query.style != null &&
        query.style!.isNotEmpty &&
        query.style != 'All') {
      final reqStyle = query.style!.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.styleTags.any((t) => t.toLowerCase().contains(reqStyle)))
          .toList();
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
    final sort = query.sort ?? 'newest';
    if (sort == 'rating' || sort == 'rating_desc') {
      filtered.sort((a, b) =>
          (b.averageRating ?? 0.0).compareTo(a.averageRating ?? 0.0));
    } else if (sort == 'price_asc') {
      filtered.sort((a, b) => a.priceRangeMin.compareTo(b.priceRangeMin));
    } else if (sort == 'price_desc') {
      filtered.sort((a, b) => b.priceRangeMax.compareTo(a.priceRangeMax));
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

  static final List<DesignerProfile> _fallbackProfiles = [
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
      ],
    ),
    DesignerProfile(
      id: 7,
      userId: 107,
      displayName: 'Greenline Eco Spaces',
      bio:
          'Pioneering biophilic design incorporating vertical green walls, natural cross-ventilation, and carbon-neutral recycled materials.',
      styleTags: const ['Biophilic', 'Eco-friendly', 'Modern Farmhouse'],
      serviceCategories: const ['Eco-Home', 'Living Room'],
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
      portfolioItems: const [],
    ),
  ];
}
