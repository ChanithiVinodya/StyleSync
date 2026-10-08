import { apiClient } from '../../shared/api/client';
import {
  RequestListQuery,
  PagedResult,
  RequestSummary,
  RequestDetail,
  RequestAnalytics,
  AnalyticsQuery,
  ApiProblem,
  PalettePreset
} from './types';
import { AxiosError } from 'axios';

export class ApiError extends Error {
  public problem: ApiProblem;

  constructor(problem: ApiProblem) {
    super(problem.title || 'API Error');
    this.name = 'ApiError';
    this.problem = problem;
  }
}

function handleApiError(error: unknown): never {
  if (error instanceof AxiosError && error.response && error.response.data) {
    const data = error.response.data as Partial<ApiProblem> & { message?: string };
    const problem: ApiProblem = {
      title: data.title || data.message || 'Unknown API Error',
      status: data.status || error.response.status,
      errors: data.errors,
      detail: data.detail
    };
    throw new ApiError(problem);
  }
  throw error;
}

export const requestApi = {
  listRequests: async (query?: RequestListQuery): Promise<PagedResult<RequestSummary>> => {
    try {
      const params = new URLSearchParams();
      if (query) {
        Object.entries(query).forEach(([key, value]) => {
          if (value !== undefined && value !== null && value !== '') {
            if (Array.isArray(value)) {
              value.forEach(v => params.append(key, String(v)));
            } else if (value instanceof Date) {
              params.append(key, value.toISOString());
            } else {
              params.append(key, String(value));
            }
          }
        });
      }
      
      const response = await apiClient.get<PagedResult<RequestSummary>>('/requests', { params });
      return response.data;
    } catch (error) {
      return handleApiError(error);
    }
  },

  getRequest: async (id: string): Promise<RequestDetail> => {
    try {
      const response = await apiClient.get<RequestDetail>(`/requests/${id}`);
      return response.data;
    } catch (error) {
      return handleApiError(error);
    }
  },

  cancelRequest: async (id: string, reason: string): Promise<void> => {
    try {
      await apiClient.post(`/requests/${id}/cancel`, { reason });
    } catch (error) {
      return handleApiError(error);
    }
  },

  flagRequest: async (id: string, reason: string, isFlagged: boolean): Promise<void> => {
    try {
      await apiClient.post(`/requests/${id}/flag`, { reason, isFlagged });
    } catch (error) {
      return handleApiError(error);
    }
  },

  approveRequest: async (id: string): Promise<void> => {
    try {
      await apiClient.post(`/requests/${id}/approve`);
    } catch (error) {
      return handleApiError(error);
    }
  },

  getRequestAnalytics: async (query?: AnalyticsQuery): Promise<RequestAnalytics> => {
    try {
      const params = new URLSearchParams();
      if (query?.createdFrom) params.append('createdFrom', query.createdFrom);
      if (query?.createdTo) params.append('createdTo', query.createdTo);
      
      const response = await apiClient.get<RequestAnalytics>('/requests/analytics', { params });
      return response.data;
    } catch (error) {
      return handleApiError(error);
    }
  },

  listPalettePresets: async (): Promise<PalettePreset[]> => {
    try {
      const response = await apiClient.get<PalettePreset[]>('/palettes/presets');
      return response.data;
    } catch (error) {
      return handleApiError(error);
    }
  }
};
