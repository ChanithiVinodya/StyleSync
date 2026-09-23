export enum ListingStatus {
  Draft = 0,
  Published = 1,
  Suspended = 2,
  Archived = 3,
}

export interface PortfolioItem {
  id: number;
  designerProfileId: number;
  title: string;
  description: string;
  imageUrl: string;
  budgetRangeLabel: string;
  clientInitials: string;
  completionStatusBadge: ListingStatus;
  createdAtUtc: string;
  updatedAtUtc?: string | null;
}

export interface DesignerProfile {
  id: number;
  userId: number;
  displayName: string;
  bio: string;
  styleTags: string[];
  serviceCategories: string[];
  priceRangeMin: number;
  priceRangeMax: number;
  ratePerSqFt: number;
  isAvailable: boolean;
  maxConcurrentProjects: number;
  activeProjectCount: number;
  remainingCapacity: number;
  isUnderCapacity: boolean;
  isAtCapacity: boolean;
  averageRating: number | null;
  listingStatus: ListingStatus;
  createdAtUtc: string;
  updatedAtUtc?: string | null;
  portfolioItems: PortfolioItem[];
}

export interface CreateDesignerProfileRequest {
  displayName: string;
  bio: string;
  styleTags: string[];
  serviceCategories: string[];
  priceRangeMin: number;
  priceRangeMax: number;
  ratePerSqFt: number;
  isAvailable: boolean;
  maxConcurrentProjects?: number;
}

export interface UpdateDesignerProfileRequest {
  displayName: string;
  bio: string;
  styleTags: string[];
  serviceCategories: string[];
  priceRangeMin: number;
  priceRangeMax: number;
  ratePerSqFt: number;
  isAvailable: boolean;
  maxConcurrentProjects?: number;
  listingStatus?: ListingStatus;
}

export interface CreatePortfolioItemRequest {
  title: string;
  description: string;
  imageUrl: string;
  budgetRangeLabel: string;
  clientInitials: string;
  completionStatusBadge: ListingStatus;
}

export interface DesignerProfileFormState {
  displayName: string;
  bio: string;
  styleTags: string[];
  serviceCategories: string[];
  priceRangeMin: string;
  priceRangeMax: string;
  ratePerSqFt: string;
  isAvailable: boolean;
  maxConcurrentProjects: string;
  listingStatus: ListingStatus;
}

export interface FormValidationErrors {
  displayName?: string;
  bio?: string;
  styleTags?: string;
  serviceCategories?: string;
  priceRangeMin?: string;
  priceRangeMax?: string;
  ratePerSqFt?: string;
  maxConcurrentProjects?: string;
  general?: string;
}

export interface PortfolioItemFormState {
  title: string;
  description: string;
  imageUrl: string;
  budgetRangeLabel: string;
  clientInitials: string;
  completionStatusBadge: ListingStatus;
}

export interface PortfolioItemValidationErrors {
  title?: string;
  description?: string;
  imageUrl?: string;
  budgetRangeLabel?: string;
  clientInitials?: string;
  general?: string;
}
