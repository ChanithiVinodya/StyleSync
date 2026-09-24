import { authStorage } from '../auth/authService';

const API_BASE = 'http://localhost:5000/api/v1/project-requests';

/** Build auth headers from the stored JWT token */
function authHeaders(): Record<string, string> {
  const token = authStorage.getToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

// ─── Shared Domain Interfaces ──────────────────────────────────────────────

export interface Photo {
  id: string;
  photoUrl: string;
  storageKey: string;
}

export interface StyleAnalysis {
  id: string;
  primaryStyle: string;
  secondaryStyle: string;
  confidenceScore: number;
  recommendedColors: string[];
  detectedFeatures: string[];
  analysisSummary: string;
  conceptRenderUrl: string;
  analyzedAt: string;
}

export interface ProjectRequest {
  id: string;
  clientId: string;
  roomType: string;
  lengthFeet: number;
  widthFeet: number;
  heightFeet: number;
  budgetLkr: number;
  preferredStyles: string[];
  description: string;
  status: string;
  createdAt: string;
  photos: Photo[];
  styleAnalysis?: StyleAnalysis;
}

export interface CreateRequestPayload {
  roomType: string;
  lengthFeet: number;
  widthFeet: number;
  heightFeet: number;
  budgetLkr: number;
  preferredStyles: string[];
  description: string;
  photoUrls: string[];
  submitImmediately: boolean;
}

// ─── API Functions ─────────────────────────────────────────────────────────

export async function fetchAllRequests(
  status = '',
  roomType = ''
): Promise<ProjectRequest[]> {
  try {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (roomType) params.append('roomType', roomType);

    const res = await fetch(`${API_BASE}?${params.toString()}`, {
      headers: { ...authHeaders() },
    });
    if (!res.ok) throw new Error('Failed to fetch requests');
    return (await res.json()) as ProjectRequest[];
  } catch (err) {
    console.warn('Backend API connection fallback:', err);
    // Initial sample fallback data for demo if API server is booting up
    return [
      {
        id: '11111111-1111-1111-1111-111111111111',
        clientId: 'client-nimali',
        roomType: 'Bedroom',
        lengthFeet: 15,
        widthFeet: 12,
        heightFeet: 10,
        budgetLkr: 250000,
        preferredStyles: ['Modern', 'Minimalist'],
        description:
          "I want a simple room. I like white and light brown colours. I don't want too much furniture.",
        status: 'ProposalReady',
        createdAt: new Date().toISOString(),
        photos: [
          {
            id: 'photo-1',
            photoUrl:
              'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop',
            storageKey: 'sample/bedroom-1.jpg',
          },
          {
            id: 'photo-2',
            photoUrl:
              'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?q=80&w=800&auto=format&fit=crop',
            storageKey: 'sample/bedroom-2.jpg',
          },
          {
            id: 'photo-3',
            photoUrl:
              'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?q=80&w=800&auto=format&fit=crop',
            storageKey: 'sample/bedroom-3.jpg',
          },
          {
            id: 'photo-4',
            photoUrl:
              'https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=800&auto=format&fit=crop',
            storageKey: 'sample/bedroom-4.jpg',
          },
        ],
        styleAnalysis: {
          id: 'analysis-1',
          primaryStyle: 'Modern',
          secondaryStyle: 'Minimalist',
          confidenceScore: 93.4,
          recommendedColors: [
            '#FFFFFF (White)',
            '#D7C4B7 (Light Brown)',
            '#F5F5F7 (Warm Grey)',
          ],
          detectedFeatures: [
            'Visual Feature Extraction (1 Uploaded Photo)',
            'Clean Architectural Lines',
            'Uncluttered Spatial Flow',
            'Soft Natural Daylight',
          ],
          analysisSummary:
            'Our AI Style Analysis Agent analyzed 1 uploaded room photo and evaluated client preferences for your Bedroom. The space is ideal for a Modern design direction with subtle Minimalist accents, yielding a calculated 93.4% compatibility score.',
          conceptRenderUrl:
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop',
          analyzedAt: new Date().toISOString(),
        },
      },
    ];
  }
}

export async function createProjectRequest(
  payload: CreateRequestPayload
): Promise<ProjectRequest> {
  const res = await fetch(API_BASE, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...authHeaders(),
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error('Failed to create project request');
  return (await res.json()) as ProjectRequest;
}

export async function submitRequestForAI(id: string): Promise<ProjectRequest> {
  const res = await fetch(`${API_BASE}/${id}/submit`, {
    method: 'POST',
    headers: { ...authHeaders() },
  });
  if (!res.ok) throw new Error('Failed to submit request for AI analysis');
  return (await res.json()) as ProjectRequest;
}
