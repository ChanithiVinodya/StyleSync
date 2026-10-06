import { useState, useEffect, useCallback } from 'react';
import { requestApi, ApiError } from './api';
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

export function useRequests(initialQuery?: RequestListQuery) {
  const [data, setData] = useState<PagedResult<RequestSummary> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiProblem | null>(null);

  const fetchRequests = useCallback(async (query?: RequestListQuery) => {
    setLoading(true);
    setError(null);
    try {
      const result = await requestApi.listRequests(query);
      setData(result);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.problem);
      } else {
        setError({ title: 'An unexpected error occurred', status: 500 });
      }
    } finally {
      setLoading(false);
    }
  }, []);

  const queryKey = JSON.stringify(initialQuery);

  useEffect(() => {
    fetchRequests(initialQuery);
  }, [fetchRequests, queryKey, initialQuery]);

  return { data, loading, error, fetchRequests };
}

export function useRequestDetail(id: string) {
  const [data, setData] = useState<RequestDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiProblem | null>(null);

  const fetchRequest = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await requestApi.getRequest(id);
      setData(result);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.problem);
      } else {
        setError({ title: 'An unexpected error occurred', status: 500 });
      }
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    if (id) {
      fetchRequest();
    }
  }, [fetchRequest, id]);

  return { data, loading, error, refetch: fetchRequest };
}

export function useRequestAnalytics(initialQuery?: AnalyticsQuery) {
  const [data, setData] = useState<RequestAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiProblem | null>(null);

  const fetchAnalytics = useCallback(async (query?: AnalyticsQuery) => {
    setLoading(true);
    setError(null);
    try {
      const result = await requestApi.getRequestAnalytics(query);
      setData(result);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.problem);
      } else {
        setError({ title: 'An unexpected error occurred', status: 500 });
      }
    } finally {
      setLoading(false);
    }
  }, []);

  const queryKey = JSON.stringify(initialQuery);

  useEffect(() => {
    fetchAnalytics(initialQuery);
  }, [fetchAnalytics, queryKey, initialQuery]);

  return { data, loading, error, refetch: () => fetchAnalytics(initialQuery) };
}

let cachedPresets: PalettePreset[] | null = null;
let presetsPromise: Promise<PalettePreset[]> | null = null;

export function usePalettePresets() {
  const [data, setData] = useState<PalettePreset[] | null>(cachedPresets);
  const [loading, setLoading] = useState(!cachedPresets);
  const [error, setError] = useState<ApiProblem | null>(null);

  useEffect(() => {
    if (cachedPresets) {
      return;
    }
    
    let isMounted = true;
    
    if (!presetsPromise) {
      presetsPromise = requestApi.listPalettePresets().then(res => {
        cachedPresets = res;
        return res;
      }).catch(err => {
        presetsPromise = null;
        throw err;
      });
    }
    
    presetsPromise.then(res => {
      if (isMounted) {
        setData(res);
        setLoading(false);
      }
    }).catch(err => {
      if (isMounted) {
        if (err instanceof ApiError) {
          setError(err.problem);
        } else {
          setError({ title: 'Failed to load presets', status: 500 });
        }
        setLoading(false);
      }
    });
    
    return () => {
      isMounted = false;
    };
  }, []);

  return { data, loading, error };
}
