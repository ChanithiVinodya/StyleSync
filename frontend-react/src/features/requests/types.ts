export const REQUEST_STATUSES = [
  'Draft',
  'Submitted',
  'AIAnalysis',
  'ProposalReady',
  'AwaitingApproval',
  'Approved',
  'DesignerAssigned',
  'InProgress',
  'Completed',
  'Rejected',
  'Cancelled'
] as const;

export type RequestStatus = typeof REQUEST_STATUSES[number];

export const ROOM_TYPES = [
  'LivingRoom',
  'Kitchen',
  'Bedroom',
  'Bathroom',
  'DiningRoom'
] as const;

export type RoomType = typeof ROOM_TYPES[number];

export type PaletteMode = 'Preset' | 'Generated';

export interface PalettePreset {
  id: string;
  name: string;
  colours: string[];
}

export interface RequestSummary {
  id: string;
  referenceCode: string;
  roomType: RoomType;
  budget: number;
  status: RequestStatus;
  isFlagged: boolean;
  createdAt: string;
  updatedAt: string;
  roomPhotoUrl?: string | null;
  clientDisplayName?: string | null;
}

export interface PaletteColour {
  hex: string;
  position: number;
}

export interface MoodboardImage {
  id: string;
  url: string;
  sortOrder: number;
}

export interface StatusHistoryEntry {
  fromStatus?: RequestStatus | null;
  toStatus: RequestStatus;
  changedAt: string;
  note: string;
}

export interface RequestDetail {
  id: string;
  referenceCode: string;
  clientId: string;
  roomType: RoomType;
  roomSizeSqFt: number;
  budget: number;
  description: string;
  status: RequestStatus;
  isFlagged: boolean;
  flagReason?: string | null;
  cancelReason?: string | null;
  createdAt: string;
  updatedAt: string;
  submittedAt?: string | null;
  roomPhotoUrl?: string | null;
  paletteMode?: PaletteMode | null;
  palettePresetId?: string | null;
  paletteBaseHex?: string | null;
  palette: PaletteColour[];
  moodboards: MoodboardImage[];
  statusHistory: StatusHistoryEntry[];
  preferredDesignerId?: string | null;
  designerDisplayName?: string | null;
  designerEmail?: string | null;
}

export interface PagedResult<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface RequestListQuery {
  search?: string;
  status?: RequestStatus[];
  roomType?: RoomType[];
  minBudget?: number;
  maxBudget?: number;
  createdFrom?: string; // ISO date string
  createdTo?: string;   // ISO date string
  isFlagged?: boolean;
  sortBy?: 'createdAt' | 'updatedAt' | 'budget' | 'status' | 'roomSize';
  sortDir?: 'asc' | 'desc';
  page?: number;
  pageSize?: number;
}

export interface AnalyticsQuery {
  createdFrom?: string;
  createdTo?: string;
}

export interface AnalyticsStatusCount {
  status: RequestStatus;
  count: number;
}

export interface AnalyticsRoomTypeCount {
  roomType: RoomType;
  count: number;
}

export interface AnalyticsRoomTypeBudget {
  roomType: RoomType;
  averageBudget: number | null;
}

export interface RequestAnalytics {
  byStatus: AnalyticsStatusCount[];
  byRoomType: AnalyticsRoomTypeCount[];
  averageBudget: number | null;
  averageBudgetByRoomType: AnalyticsRoomTypeBudget[];
  totalRequests: number;
  flaggedCount: number;
}

export interface ApiProblemError {
  field: string;
  code: string;
  message: string;
}

export interface ApiProblem {
  title: string;
  status: number;
  errors?: ApiProblemError[];
  detail?: string;
}
