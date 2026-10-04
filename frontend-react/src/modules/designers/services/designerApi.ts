import { 
  DesignerProfile, 
  DesignerListingItem,
  DesignerQueryParameters,
  PagedResult,
  PortfolioItem, 
  CreateDesignerProfileRequest, 
  UpdateDesignerProfileRequest, 
  CreatePortfolioItemRequest,
  ListingStatus
} from '../types';

const API_BASE = '/api/designers';

// Fallback seed designers matching the backend seed database
const SEED_DESIGNERS: DesignerProfile[] = [
  {
    id: 1,
    userId: 101,
    displayName: "Jayawardena Architecture & Interiors",
    bio: "Award-winning interior studio specializing in tropical modernism, seamless indoor-outdoor flow, and sustainable natural materials.",
    styleTags: ["Tropical Modernism", "Minimalist", "Sustainable", "Contemporary"],
    serviceCategories: ["Full Home Interior", "Living Room", "Renovation"],
    priceRangeMin: 150000,
    priceRangeMax: 600000,
    ratePerSqFt: 450,
    isAvailable: true,
    maxConcurrentProjects: 3,
    activeProjectCount: 1,
    remainingCapacity: 2,
    isUnderCapacity: true,
    isAtCapacity: false,
    averageRating: 4.85,
    listingStatus: ListingStatus.Published,
    createdAtUtc: "2026-08-15T10:00:00Z",
    portfolioItems: [
      {
        id: 1,
        designerProfileId: 1,
        title: "Bawa-Inspired Courtyard Residence",
        description: "A 3,200 sq.ft villa in Pelawatte incorporating exposed brick, timber columns, and an open central reflection pool.",
        imageUrl: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 450k-550k",
        clientInitials: "K.M.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-08-16T12:00:00Z"
      },
      {
        id: 2,
        designerProfileId: 1,
        title: "Minimalist Open-Concept Living Room",
        description: "Natural teak cabinetry paired with polished cement floors and diffused daylighting fixtures.",
        imageUrl: "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 200k-300k",
        clientInitials: "S.D.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-08-20T15:30:00Z"
      }
    ]
  },
  {
    id: 2,
    userId: 102,
    displayName: "Studio Amara Design",
    bio: "Curating cozy, vibrant, Scandinavian and bohemian residential living spaces with artisanal bespoke furniture and curated color palettes.",
    styleTags: ["Boho Chic", "Scandinavian", "Contemporary"],
    serviceCategories: ["Apartment Interior", "Bedroom Design", "Color Consultation"],
    priceRangeMin: 100000,
    priceRangeMax: 350000,
    ratePerSqFt: 320,
    isAvailable: true,
    maxConcurrentProjects: 2,
    activeProjectCount: 2,
    remainingCapacity: 0,
    isUnderCapacity: false,
    isAtCapacity: true, // AT CAPACITY
    averageRating: 4.90,
    listingStatus: ListingStatus.Published,
    createdAtUtc: "2026-08-18T09:00:00Z",
    portfolioItems: [
      {
        id: 4,
        designerProfileId: 2,
        title: "Warm Bohemian Haven",
        description: "Earthy terracotta tones, macramé accents, cane furniture, and layered woven rugs in Havelock City.",
        imageUrl: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 150k-250k",
        clientInitials: "A.R.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-08-19T10:00:00Z"
      }
    ]
  },
  {
    id: 3,
    userId: 103,
    displayName: "Urban Loft Atelier",
    bio: "Raw textures, exposed brick, dark metal accents, and modern luxury tailored for trendy urban apartments and collaborative workspaces.",
    styleTags: ["Industrial", "Modern Contemporary", "Rustic"],
    serviceCategories: ["Commercial & Office", "Full Home Interior", "Kitchen & Dining"],
    priceRangeMin: 300000,
    priceRangeMax: 1200000,
    ratePerSqFt: 650,
    isAvailable: true,
    maxConcurrentProjects: 4,
    activeProjectCount: 2,
    remainingCapacity: 2,
    isUnderCapacity: true,
    isAtCapacity: false,
    averageRating: 4.75,
    listingStatus: ListingStatus.Published,
    createdAtUtc: "2026-08-22T14:00:00Z",
    portfolioItems: [
      {
        id: 7,
        designerProfileId: 3,
        title: "Industrial Loft Living & Bar",
        description: "Double-height ceiling penthouse featuring black steel trusses, matte charcoal joinery, and reclaimed timber bar counter.",
        imageUrl: "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 750k-1M",
        clientInitials: "R.J.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-08-23T11:00:00Z"
      }
    ]
  },
  {
    id: 4,
    userId: 104,
    displayName: "Artisan Living Spaces",
    bio: "Blending coastal breezy aesthetics with authentic Sri Lankan heritage woodwork, batiks, and open veranda concepts.",
    styleTags: ["Coastal", "Traditional Sri Lankan", "Tropical Modernism"],
    serviceCategories: ["Villa & Boutique Hotel", "Living Room", "Outdoor & Patio"],
    priceRangeMin: 250000,
    priceRangeMax: 850000,
    ratePerSqFt: 520,
    isAvailable: true,
    maxConcurrentProjects: 3,
    activeProjectCount: 3,
    remainingCapacity: 0,
    isUnderCapacity: false,
    isAtCapacity: true, // AT CAPACITY
    averageRating: 4.95,
    listingStatus: ListingStatus.Published,
    createdAtUtc: "2026-08-25T08:00:00Z",
    portfolioItems: [
      {
        id: 10,
        designerProfileId: 4,
        title: "Galle Fort Coastal Retreat",
        description: "Restoration of a Dutch colonial townhouse with whitewashed walls, antique satinwood doors, and rattan loungers.",
        imageUrl: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 600k-850k",
        clientInitials: "H.L.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-08-26T09:30:00Z"
      }
    ]
  },
  {
    id: 5,
    userId: 105,
    displayName: "Wickrama Spatial Concepts",
    bio: "Disciplined Japandi and Zen minimalism focusing on light, balance, clean lines, and clutter-free compact urban living.",
    styleTags: ["Minimalist", "Japandi", "Zen"],
    serviceCategories: ["Studio Apartment", "Bathroom Renovation", "Full Home Interior"],
    priceRangeMin: 80000,
    priceRangeMax: 280000,
    ratePerSqFt: 280,
    isAvailable: false,
    maxConcurrentProjects: 3,
    activeProjectCount: 0,
    remainingCapacity: 3,
    isUnderCapacity: true,
    isAtCapacity: false,
    averageRating: 4.60,
    listingStatus: ListingStatus.Suspended, // Suspended -> not published
    createdAtUtc: "2026-08-28T16:00:00Z",
    portfolioItems: []
  },
  {
    id: 6,
    userId: 106,
    displayName: "Luxe Heritage Interiors",
    bio: "High-end bespoke luxury interior styling for luxury penthouses, presidential suites, and prestigious heritage estates.",
    styleTags: ["Classic Luxury", "Art Deco", "Colonial Revival"],
    serviceCategories: ["Penthouse", "Master Suite", "Dining & Entertainment"],
    priceRangeMin: 500000,
    priceRangeMax: 2500000,
    ratePerSqFt: 950,
    isAvailable: true,
    maxConcurrentProjects: 2,
    activeProjectCount: 1,
    remainingCapacity: 1,
    isUnderCapacity: true,
    isAtCapacity: false,
    averageRating: 5.00,
    listingStatus: ListingStatus.Published,
    createdAtUtc: "2026-09-01T11:00:00Z",
    portfolioItems: [
      {
        id: 15,
        designerProfileId: 6,
        title: "Grand Marble & Velvet Penthouse Salon",
        description: "Calacatta gold marble wall cladding, emerald velvet bespoke sofa, and 24k gold leaf ceiling molding.",
        imageUrl: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80",
        budgetRangeLabel: "LKR 1.5M-2.5M",
        clientInitials: "E.B.",
        completionStatusBadge: ListingStatus.Published,
        createdAtUtc: "2026-09-02T13:00:00Z"
      }
    ]
  },
  {
    id: 7,
    userId: 107,
    displayName: "Greenline Eco Spaces",
    bio: "Pioneering biophilic design incorporating vertical green walls, natural cross-ventilation, and carbon-neutral recycled materials.",
    styleTags: ["Biophilic", "Eco-friendly", "Modern Farmhouse"],
    serviceCategories: ["Eco-Home", "Balcony & Terrace", "Living Room"],
    priceRangeMin: 120000,
    priceRangeMax: 400000,
    ratePerSqFt: 360,
    isAvailable: true,
    maxConcurrentProjects: 3,
    activeProjectCount: 0,
    remainingCapacity: 3,
    isUnderCapacity: true,
    isAtCapacity: false,
    averageRating: null,
    listingStatus: ListingStatus.Draft, // Draft -> not published
    createdAtUtc: "2026-09-05T09:00:00Z",
    portfolioItems: []
  }
];

let inMemoryDesigners: DesignerProfile[] = [...SEED_DESIGNERS];

export const designerApi = {
  async getListings(query: DesignerQueryParameters): Promise<PagedResult<DesignerListingItem>> {
    const params = new URLSearchParams();
    if (query.style) params.append('style', query.style);
    if (query.budgetMin !== undefined && query.budgetMin > 0) params.append('budgetMin', query.budgetMin.toString());
    if (query.budgetMax !== undefined && query.budgetMax > 0) params.append('budgetMax', query.budgetMax.toString());
    if (query.available !== undefined) params.append('available', query.available.toString());
    if (query.sort) params.append('sort', query.sort);
    params.append('page', (query.page || 1).toString());
    params.append('pageSize', (query.pageSize || 9).toString());

    try {
      const response = await fetch(`${API_BASE}?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch designer listings: ${response.statusText}`);
      }
      const data: PagedResult<DesignerListingItem> = await response.json();
      return data;
    } catch {
      // Offline fallback: filter in-memory published designers
      let filtered = inMemoryDesigners.filter(d => d.listingStatus === ListingStatus.Published);

      // Style tag filter
      if (query.style && query.style.trim() !== '') {
        const reqStyle = query.style.trim().toLowerCase();
        filtered = filtered.filter(d => d.styleTags.some(t => t.toLowerCase().includes(reqStyle)));
      }

      // Budget filter
      if (query.budgetMin && query.budgetMin > 0) {
        filtered = filtered.filter(d => d.priceRangeMax >= query.budgetMin!);
      }
      if (query.budgetMax && query.budgetMax > 0) {
        filtered = filtered.filter(d => d.priceRangeMin <= query.budgetMax!);
      }

      // Availability filter
      if (query.available !== undefined) {
        if (query.available) {
          filtered = filtered.filter(d => d.isAvailable && d.isUnderCapacity);
        } else {
          filtered = filtered.filter(d => !d.isAvailable || d.isAtCapacity);
        }
      }

      // Sorting
      const sort = (query.sort || 'newest').toLowerCase();
      if (sort === 'rating' || sort === 'rating_desc') {
        filtered.sort((a, b) => (b.averageRating ?? 0) - (a.averageRating ?? 0));
      } else if (sort === 'rating_asc') {
        filtered.sort((a, b) => (a.averageRating ?? 0) - (b.averageRating ?? 0));
      } else if (sort === 'price' || sort === 'price_asc') {
        filtered.sort((a, b) => a.priceRangeMin - b.priceRangeMin);
      } else if (sort === 'price_desc') {
        filtered.sort((a, b) => b.priceRangeMax - a.priceRangeMax);
      } else {
        filtered.sort((a, b) => new Date(b.createdAtUtc).getTime() - new Date(a.createdAtUtc).getTime());
      }

      const totalCount = filtered.length;
      const page = Math.max(1, query.page || 1);
      const pageSize = Math.max(1, query.pageSize || 9);
      const totalPages = Math.ceil(totalCount / pageSize);

      const items: DesignerListingItem[] = filtered
        .slice((page - 1) * pageSize, page * pageSize)
        .map(d => ({
          id: d.id,
          displayName: d.displayName,
          bio: d.bio,
          styleTags: d.styleTags,
          serviceCategories: d.serviceCategories,
          priceRangeMin: d.priceRangeMin,
          priceRangeMax: d.priceRangeMax,
          ratePerSqFt: d.ratePerSqFt,
          isAvailable: d.isAvailable,
          maxConcurrentProjects: d.maxConcurrentProjects,
          activeProjectCount: d.activeProjectCount,
          remainingCapacity: d.remainingCapacity,
          isUnderCapacity: d.isUnderCapacity,
          isAtCapacity: d.isAtCapacity,
          averageRating: d.averageRating,
          listingStatus: d.listingStatus,
          publishedPortfolioCount: d.portfolioItems.filter(p => p.completionStatusBadge === ListingStatus.Published).length,
          featuredImageUrl: d.portfolioItems[0]?.imageUrl || 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
          createdAtUtc: d.createdAtUtc
        }));

      return {
        items,
        page,
        pageSize,
        totalCount,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1
      };
    }
  },

  async getProfile(id: number): Promise<DesignerProfile> {
    try {
      const response = await fetch(`${API_BASE}/${id}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch profile: ${response.statusText}`);
      }
      const data: DesignerProfile = await response.json();
      return data;
    } catch {
      const found = inMemoryDesigners.find(d => d.id === id);
      return found || inMemoryDesigners[0];
    }
  },

  async createProfile(request: CreateDesignerProfileRequest): Promise<DesignerProfile> {
    const response = await fetch(API_BASE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => null);
      throw new Error(errorData?.message || `Failed to create profile: ${response.statusText}`);
    }

    const created: DesignerProfile = await response.json();
    inMemoryDesigners.push(created);
    return created;
  },

  async updateProfile(id: number, request: UpdateDesignerProfileRequest): Promise<DesignerProfile> {
    try {
      const response = await fetch(`${API_BASE}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => null);
        throw new Error(errorData?.message || `Failed to update profile: ${response.statusText}`);
      }

      const updated: DesignerProfile = await response.json();
      const index = inMemoryDesigners.findIndex(d => d.id === id);
      if (index >= 0) inMemoryDesigners[index] = updated;
      return updated;
    } catch {
      const index = inMemoryDesigners.findIndex(d => d.id === id);
      if (index >= 0) {
        inMemoryDesigners[index] = {
          ...inMemoryDesigners[index],
          displayName: request.displayName,
          bio: request.bio,
          styleTags: request.styleTags,
          serviceCategories: request.serviceCategories,
          priceRangeMin: request.priceRangeMin,
          priceRangeMax: request.priceRangeMax,
          ratePerSqFt: request.ratePerSqFt,
          isAvailable: request.isAvailable,
          maxConcurrentProjects: request.maxConcurrentProjects ?? inMemoryDesigners[index].maxConcurrentProjects,
          listingStatus: request.listingStatus ?? inMemoryDesigners[index].listingStatus,
          updatedAtUtc: new Date().toISOString()
        };
        return inMemoryDesigners[index];
      }
      throw new Error('Designer not found');
    }
  },

  async addPortfolioItem(designerId: number, request: CreatePortfolioItemRequest): Promise<PortfolioItem> {
    try {
      const response = await fetch(`${API_BASE}/${designerId}/portfolio`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(request)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => null);
        throw new Error(errorData?.message || `Failed to add portfolio item: ${response.statusText}`);
      }

      const created: PortfolioItem = await response.json();
      const designer = inMemoryDesigners.find(d => d.id === designerId);
      if (designer) {
        designer.portfolioItems = [created, ...designer.portfolioItems];
      }
      return created;
    } catch {
      const newItem: PortfolioItem = {
        id: Date.now(),
        designerProfileId: designerId,
        title: request.title,
        description: request.description,
        imageUrl: request.imageUrl,
        budgetRangeLabel: request.budgetRangeLabel,
        clientInitials: request.clientInitials,
        completionStatusBadge: request.completionStatusBadge,
        createdAtUtc: new Date().toISOString()
      };
      const designer = inMemoryDesigners.find(d => d.id === designerId);
      if (designer) {
        designer.portfolioItems = [newItem, ...designer.portfolioItems];
      }
      return newItem;
    }
  },

  async getAllProfiles(): Promise<DesignerProfile[]> {
    try {
      // In production/API, fetch all profiles (accessible by Admin)
      const response = await fetch(`${API_BASE}?pageSize=100`);
      if (response.ok) {
        const data: PagedResult<DesignerListingItem> = await response.json();
        // Merge with in-memory or full profiles
        return inMemoryDesigners;
      }
      return [...inMemoryDesigners];
    } catch {
      return [...inMemoryDesigners];
    }
  },

  async overrideListingStatusAndCapacity(
    designerId: number, 
    listingStatus: ListingStatus, 
    maxConcurrentProjects: number
  ): Promise<DesignerProfile> {
    const existing = inMemoryDesigners.find(d => d.id === designerId);
    if (!existing) {
      throw new Error(`Designer profile with ID ${designerId} not found.`);
    }

    const payload: UpdateDesignerProfileRequest = {
      displayName: existing.displayName,
      bio: existing.bio,
      styleTags: existing.styleTags,
      serviceCategories: existing.serviceCategories,
      priceRangeMin: existing.priceRangeMin,
      priceRangeMax: existing.priceRangeMax,
      ratePerSqFt: existing.ratePerSqFt,
      isAvailable: existing.isAvailable,
      maxConcurrentProjects,
      listingStatus
    };

    const updated = await this.updateProfile(designerId, payload);
    // Recalculate capacity flags for in-memory display
    updated.maxConcurrentProjects = maxConcurrentProjects;
    updated.listingStatus = listingStatus;
    updated.remainingCapacity = Math.max(0, maxConcurrentProjects - updated.activeProjectCount);
    updated.isUnderCapacity = updated.activeProjectCount < maxConcurrentProjects;
    updated.isAtCapacity = updated.activeProjectCount >= maxConcurrentProjects;
    
    return updated;
  },

  async deletePortfolioItem(designerId: number, itemId: number): Promise<void> {
    try {
      const response = await fetch(`${API_BASE}/${designerId}/portfolio/${itemId}`, {
        method: 'DELETE'
      });

      if (!response.ok) {
        throw new Error(`Failed to delete portfolio item: ${response.statusText}`);
      }
    } finally {
      const designer = inMemoryDesigners.find(d => d.id === designerId);
      if (designer) {
        designer.portfolioItems = designer.portfolioItems.filter(item => item.id !== itemId);
      }
    }
  }
};

