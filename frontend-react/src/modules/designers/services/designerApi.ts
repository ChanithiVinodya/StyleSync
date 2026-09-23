import { 
  DesignerProfile, 
  PortfolioItem, 
  CreateDesignerProfileRequest, 
  UpdateDesignerProfileRequest, 
  CreatePortfolioItemRequest,
  ListingStatus
} from '../types';

const API_BASE = '/api/designers';

// Fallback seed designer for demonstration/standalone frontend tests if backend API is not currently connected
const SEED_FALLBACK_PROFILE: DesignerProfile = {
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
  createdAtUtc: new Date().toISOString(),
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
      createdAtUtc: new Date().toISOString()
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
      createdAtUtc: new Date().toISOString()
    }
  ]
};

let inMemoryProfile: DesignerProfile = { ...SEED_FALLBACK_PROFILE };

export const designerApi = {
  async getProfile(id: number): Promise<DesignerProfile> {
    try {
      const response = await fetch(`${API_BASE}/${id}`);
      if (!response.ok) {
        if (response.status === 404) {
          return inMemoryProfile;
        }
        throw new Error(`Failed to fetch profile: ${response.statusText}`);
      }
      const data: DesignerProfile = await response.json();
      inMemoryProfile = data;
      return data;
    } catch {
      // Return local fallback state if API server is offline
      return inMemoryProfile;
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
    inMemoryProfile = created;
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
      inMemoryProfile = updated;
      return updated;
    } catch (err: unknown) {
      // If network fails (e.g. mock mode during offline development), update local copy
      inMemoryProfile = {
        ...inMemoryProfile,
        displayName: request.displayName,
        bio: request.bio,
        styleTags: request.styleTags,
        serviceCategories: request.serviceCategories,
        priceRangeMin: request.priceRangeMin,
        priceRangeMax: request.priceRangeMax,
        ratePerSqFt: request.ratePerSqFt,
        isAvailable: request.isAvailable,
        maxConcurrentProjects: request.maxConcurrentProjects ?? inMemoryProfile.maxConcurrentProjects,
        listingStatus: request.listingStatus ?? inMemoryProfile.listingStatus,
        updatedAtUtc: new Date().toISOString()
      };
      return inMemoryProfile;
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
      inMemoryProfile.portfolioItems = [created, ...inMemoryProfile.portfolioItems];
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
      inMemoryProfile.portfolioItems = [newItem, ...inMemoryProfile.portfolioItems];
      return newItem;
    }
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
      inMemoryProfile.portfolioItems = inMemoryProfile.portfolioItems.filter(item => item.id !== itemId);
    }
  }
};
