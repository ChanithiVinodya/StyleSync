import { describe, it, expect, vi, beforeEach } from 'vitest';
import { requestApi } from './api';
import { apiClient } from '../../shared/api/client';
import { RequestListQuery } from './types';

// Mock the api client
vi.mock('../../shared/api/client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

describe('requestApi', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('listRequests', () => {
    it('should serialize query params correctly, including arrays, dates, and omitting empties', async () => {
      // Setup mock response
      const mockResponse = { data: { items: [], totalCount: 0, page: 1, pageSize: 10, totalPages: 0 } };
      const mockGet = apiClient.get as import('vitest').Mock;
      mockGet.mockResolvedValue(mockResponse);

      const dateFrom = new Date('2026-01-01T10:00:00Z');
      
      const query: RequestListQuery = {
        search: 'beautiful',
        status: ['Draft', 'Submitted'],
        roomType: undefined, // omitted
        minBudget: 1000,
        maxBudget: undefined, // omitted
        createdFrom: dateFrom.toISOString(),
        isFlagged: true,
      };

      await requestApi.listRequests(query);

      expect(apiClient.get).toHaveBeenCalledTimes(1);
      
      // Get the arguments passed to apiClient.get
      const args = mockGet.mock.calls[0];
      expect(args[0]).toBe('/requests');
      
      const config = args[1];
      expect(config).toBeDefined();
      
      const params = config.params as URLSearchParams;
      expect(params).toBeInstanceOf(URLSearchParams);

      // Verify serialization
      expect(params.get('search')).toBe('beautiful');
      
      // status array should be appended multiple times
      const statusParams = params.getAll('status');
      expect(statusParams).toHaveLength(2);
      expect(statusParams).toContain('Draft');
      expect(statusParams).toContain('Submitted');

      // omitted values shouldn't be present
      expect(params.has('roomType')).toBe(false);
      expect(params.has('maxBudget')).toBe(false);

      expect(params.get('minBudget')).toBe('1000');
      expect(params.get('createdFrom')).toBe(dateFrom.toISOString());
      expect(params.get('isFlagged')).toBe('true');
    });
  });
});
