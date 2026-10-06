export type StatusLike = string | { value?: string; name?: string } | undefined | null;

export type QuoteStatus = 
  | "Draft"
  | "Stage1Pending"
  | "Stage1RevisionRequested"
  | "Stage1Rejected"
  | "Stage1Released"
  | "Stage2Approved"
  | "Stage2ChangesRequested"
  | "Stage2Rejected"
  // Legacy aliases
  | "Submitted"
  | "ClientReview"
  | "RevisionRequested"
  | "Accepted"
  | "Rejected";

export type ContractStatus = 
  | "PendingSignature"
  | "Active"
  | "Completed"
  | "Cancelled"
  | "Draft";

export interface QuoteItem {
  id?: string;
  description: string;
  category: string;
  quantity: number;
  unitCost: number;
  lineTotal?: number;
  totalCost?: number;
}

export interface QuoteVersionItem {
  id: string;
  description: string;
  category: string;
  quantity: number;
  unitCost: number;
  lineTotal: number;
}

export interface QuoteVersion {
  id: string;
  versionNumber: number;
  authorId: string;
  authorRole: string;
  materialsSubtotal: number;
  laborSubtotal: number;
  designFee: number;
  contingencyAmount: number;
  taxAmount: number;
  totalCost: number;
  notes?: string;
  createdAt: string;
  items: QuoteVersionItem[];
}

export interface DesignerRecommendation {
  userId: string;
  profileId: number;
  displayName: string;
  email?: string;
  matchScore: number;
  styleTagOverlapPct: number;
  budgetRangeOverlapPct: number;
  pastRatingNormalized: number;
  availabilityBonus: number;
  averageRating?: number;
  styleTags: string[];
  priceRangeMin: number;
  priceRangeMax: number;
  featuredImageUrl?: string;
  bio?: string;
  matchReason?: string;
}

export interface Quote {
  id: string;
  projectRequestId: string;
  designerId: string;
  scopeSummary: string;
  notes?: string;
  isAiGenerated: boolean;
  status: StatusLike;
  totalCost: number;
  items: QuoteItem[];
  currentVersion?: QuoteVersion;
  versions?: QuoteVersion[];
  contractId?: string;
  createdAt?: string;
  updatedAt?: string;
  designerDisplayName?: string;
  designerEmail?: string;
  clientDisplayName?: string;
  clientEmail?: string;
  projectReferenceCode?: string;
  description?: string;
  recommendedDesigners?: DesignerRecommendation[];
}

export interface Contract {
  id: string;
  quoteId?: string;
  projectRequestId?: string;
  designerId?: string;
  clientId?: string;
  status: string;
  totalAmount: number;
  terms?: string;
  termsSummary?: string;
  startDate?: string;
  endDate?: string;
  signedAt?: string;
  createdAt?: string;
  updatedAt?: string;
  quote?: Quote;
  designerDisplayName?: string;
  designerEmail?: string;
  clientDisplayName?: string;
  clientEmail?: string;
  projectReferenceCode?: string;
  description?: string;
  recommendedDesigners?: DesignerRecommendation[];
}

export interface AgentQuoteItemDraft {
  description: string;
  category: string;
  quantity: number;
  unitCost: number;
}

export interface AgentBudgetScopeResponse {
  scopeSummary?: string;
  scope_summary?: string;
  items: AgentQuoteItemDraft[];
  notes?: string;
  estimatedTotal?: number;
  estimated_total?: number;
  withinBudget?: boolean;
  within_budget?: boolean;
  source?: string;
}

export interface PagedResult<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
}
