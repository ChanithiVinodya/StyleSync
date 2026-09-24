import { useState, useEffect, useCallback } from 'react';
import {
  ProjectRequest,
  fetchAllRequests,
  createProjectRequest,
  submitRequestForAI,
  CreateRequestPayload,
} from '../services/api';

interface UseProjectRequestsOptions {
  status?: string;
  roomType?: string;
  autoFetch?: boolean;
}

interface UseProjectRequestsReturn {
  requests: ProjectRequest[];
  isLoading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  create: (payload: CreateRequestPayload) => Promise<ProjectRequest>;
  submitForAI: (id: string) => Promise<ProjectRequest>;
}

/**
 * Custom hook that encapsulates all project-request data fetching logic.
 * Automatically fetches on mount when `autoFetch` is true (default).
 */
export function useProjectRequests({
  status = '',
  roomType = '',
  autoFetch = true,
}: UseProjectRequestsOptions = {}): UseProjectRequestsReturn {
  const [requests, setRequests] = useState<ProjectRequest[]>([]);
  const [isLoading, setIsLoading] = useState(autoFetch);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await fetchAllRequests(status, roomType);
      setRequests(data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load requests';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [status, roomType]);

  useEffect(() => {
    if (autoFetch) {
      refresh();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoFetch]);

  const create = useCallback(
    async (payload: CreateRequestPayload): Promise<ProjectRequest> => {
      const newRequest = await createProjectRequest(payload);
      setRequests((prev) => [newRequest, ...prev]);
      return newRequest;
    },
    []
  );

  const submitForAI = useCallback(
    async (id: string): Promise<ProjectRequest> => {
      const updated = await submitRequestForAI(id);
      setRequests((prev) =>
        prev.map((r) => (r.id === id ? updated : r))
      );
      return updated;
    },
    []
  );

  return { requests, isLoading, error, refresh, create, submitForAI };
}
