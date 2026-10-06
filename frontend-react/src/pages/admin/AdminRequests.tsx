import React, { useState, useEffect, useMemo } from 'react';
import { useSearchParams, useNavigate, Link } from 'react-router-dom';
import { useRequests } from '../../features/requests/hooks';
import { REQUEST_STATUSES, ROOM_TYPES, RequestListQuery, RequestStatus, RoomType } from '../../features/requests/types';
import { Search, ChevronUp, ChevronDown, Flag, X, ArrowRight, AlertCircle, RefreshCw, LayoutDashboard } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';
import { useAuth } from '../../auth/AuthContext';

export const AdminRequests: React.FC = () => {
  const { user } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  // Parsing searchParams into query object
  const query = useMemo<RequestListQuery>(() => {
    const q: RequestListQuery = {};
    if (searchParams.has('search')) q.search = searchParams.get('search')!;
    if (searchParams.has('status')) q.status = searchParams.getAll('status') as RequestStatus[];
    if (searchParams.has('roomType')) q.roomType = searchParams.getAll('roomType') as RoomType[];
    if (searchParams.has('minBudget')) q.minBudget = Number(searchParams.get('minBudget'));
    if (searchParams.has('maxBudget')) q.maxBudget = Number(searchParams.get('maxBudget'));
    if (searchParams.has('createdFrom')) q.createdFrom = searchParams.get('createdFrom')!;
    if (searchParams.has('createdTo')) q.createdTo = searchParams.get('createdTo')!;
    if (searchParams.has('isFlagged')) q.isFlagged = searchParams.get('isFlagged') === 'true';
    if (searchParams.has('sortBy')) q.sortBy = searchParams.get('sortBy') as RequestListQuery['sortBy'];
    if (searchParams.has('sortDir')) q.sortDir = searchParams.get('sortDir') as RequestListQuery['sortDir'];
    q.page = Number(searchParams.get('page')) || 1;
    q.pageSize = Number(searchParams.get('pageSize')) || 10;
    return q;
  }, [searchParams]);

  // Client-side guard for budget
  const minB = query.minBudget ?? 0;
  const maxB = query.maxBudget ?? Infinity;
  const hasBudgetError = minB > maxB;

  // We only fetch if there's no budget error
  const safeQuery = hasBudgetError ? { ...query, minBudget: undefined, maxBudget: undefined } : query;
  
  const { data, loading, error, fetchRequests } = useRequests(safeQuery);

  // Debounced search state
  const currentSearchParam = query.search || '';
  const [searchInput, setSearchInput] = useState(currentSearchParam);

  useEffect(() => {
    setSearchInput(currentSearchParam);
  }, [currentSearchParam]);

  useEffect(() => {
    const handler = setTimeout(() => {
      if (searchInput !== currentSearchParam) {
        updateFilter('search', searchInput || undefined);
      }
    }, 400);
    return () => clearTimeout(handler);
  }, [searchInput, currentSearchParam]);

  const updateFilter = React.useCallback((key: string, value: string | string[] | boolean | undefined) => {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev);
      if (value === undefined || value === '' || value === false) {
        next.delete(key);
      } else if (Array.isArray(value)) {
        next.delete(key);
        value.forEach(v => next.append(key, v));
      } else {
        next.set(key, String(value));
      }
      next.set('page', '1');
      return next;
    });
  }, [setSearchParams]);

  const handleSort = (field: string) => {
    setSearchParams(prev => {
      const next = new URLSearchParams(prev);
      if (query.sortBy === field) {
        next.set('sortDir', query.sortDir === 'asc' ? 'desc' : 'asc');
      } else {
        next.set('sortBy', field);
        next.set('sortDir', 'asc');
      }
      return next;
    });
  };

  const clearAll = () => {
    setSearchParams(new URLSearchParams());
  };

  const formatCurrency = (val: number) => new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR' }).format(val);
  const formatDate = (val: string) => new Date(val).toLocaleDateString();

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10 font-sans">
      <div className="max-w-7xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Project Requests</h1>
              <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Manage and track makeover requests</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link to={user?.role === 'Admin' ? '/admin/dashboard' : user?.role === 'Designer' ? '/designer' : '/client'} className="flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition">
              <LayoutDashboard size={14} /> Back to Dashboard
            </Link>
          </div>
        </div>

        {/* Controls */}
        <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-5 shadow-xs space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Search */}
            <div className="relative flex-1">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                className="block w-full pl-10 pr-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm focus:ring-2 focus:ring-amber-500 focus:border-amber-500 outline-none"
                placeholder="Search reference or description..."
                value={searchInput}
                onChange={e => setSearchInput(e.target.value)}
              />
            </div>

            {/* Status Multiselect (Native basic fallback or select multiple) */}
            <select
              multiple
              className="block w-full px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm outline-none"
              value={query.status || []}
              onChange={e => {
                const vals = Array.from(e.target.selectedOptions, option => option.value);
                updateFilter('status', vals.length > 0 ? vals : undefined);
              }}
            >
              {REQUEST_STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
            </select>

            {/* Room Type Multiselect */}
            <select
              multiple
              className="block w-full px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm outline-none"
              value={query.roomType || []}
              onChange={e => {
                const vals = Array.from(e.target.selectedOptions, option => option.value);
                updateFilter('roomType', vals.length > 0 ? vals : undefined);
              }}
            >
              {ROOM_TYPES.map(rt => <option key={rt} value={rt}>{rt}</option>)}
            </select>
            
            <div className="flex gap-2">
              <input type="number" placeholder="Min Budget" 
                className="w-1/2 px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm"
                value={query.minBudget || ''} onChange={e => updateFilter('minBudget', e.target.value)} />
              <input type="number" placeholder="Max Budget" 
                className="w-1/2 px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm"
                value={query.maxBudget || ''} onChange={e => updateFilter('maxBudget', e.target.value)} />
            </div>

            <div className="flex gap-2 lg:col-span-2">
              <input type="date" className="w-1/2 px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm"
                value={query.createdFrom || ''} onChange={e => updateFilter('createdFrom', e.target.value)} />
              <input type="date" className="w-1/2 px-3 py-2 border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl bg-[#FAF8F5] dark:bg-[#12100E] text-sm"
                value={query.createdTo || ''} onChange={e => updateFilter('createdTo', e.target.value)} />
            </div>

            <div className="flex items-center gap-2">
              <label className="flex items-center gap-2 cursor-pointer text-sm">
                <input type="checkbox" className="rounded text-amber-600 focus:ring-amber-500 bg-[#FAF8F5] dark:bg-[#12100E]"
                  checked={query.isFlagged || false} onChange={e => updateFilter('isFlagged', e.target.checked)} />
                Flagged Only
              </label>
            </div>

            <div className="flex items-center">
               <button onClick={clearAll} className="flex items-center gap-1 text-sm font-semibold text-rose-600 hover:text-rose-700">
                 <X size={16} /> Clear All Filters
               </button>
            </div>
          </div>
          
          {hasBudgetError && (
            <div className="text-sm text-amber-600 bg-amber-50 dark:bg-amber-950/30 p-2 rounded-lg flex items-center gap-2">
              <AlertCircle size={16} /> Min budget cannot exceed max budget. Filters paused.
            </div>
          )}
        </div>

        {/* Error State */}
        {error && !hasBudgetError && (
          <div className="p-4 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900 rounded-2xl flex items-center justify-between text-rose-800 dark:text-rose-300">
            <div className="flex items-center gap-3">
              <AlertCircle size={20} />
              <div>
                <p className="font-bold">{error.title}</p>
                <p className="text-sm opacity-90">{error.detail || 'Failed to fetch requests'}</p>
              </div>
            </div>
            <button data-testid="retry-btn" onClick={() => fetchRequests(safeQuery)} className="p-2 hover:bg-rose-100 dark:hover:bg-rose-900 rounded-lg transition">
              <RefreshCw size={18} />
            </button>
          </div>
        )}

        {/* Table */}
        <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl overflow-hidden shadow-xs relative">
           <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#E7E1D7] dark:border-[#2E2824] text-[11px] font-bold uppercase tracking-wider text-[#78716C] bg-[#FAF8F5] dark:bg-[#141210]">
                <th tabIndex={0} role="button" onKeyDown={e => e.key === 'Enter' && handleSort('createdAt')} className="py-4 px-6 cursor-pointer hover:text-amber-600 outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded" onClick={() => handleSort('createdAt')}>
                  Reference {query.sortBy === 'createdAt' && (query.sortDir === 'asc' ? <ChevronUp className="inline w-3 h-3" /> : <ChevronDown className="inline w-3 h-3" />)}
                </th>
                <th className="py-4 px-6">Thumbnail</th>
                <th className="py-4 px-6">Client</th>
                <th tabIndex={0} role="button" onKeyDown={e => e.key === 'Enter' && handleSort('roomSize')} className="py-4 px-6 cursor-pointer hover:text-amber-600 outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded" onClick={() => handleSort('roomSize')}>
                  Room Type {query.sortBy === 'roomSize' && (query.sortDir === 'asc' ? <ChevronUp className="inline w-3 h-3" /> : <ChevronDown className="inline w-3 h-3" />)}
                </th>
                <th tabIndex={0} role="button" onKeyDown={e => e.key === 'Enter' && handleSort('budget')} className="py-4 px-6 cursor-pointer hover:text-amber-600 outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded" onClick={() => handleSort('budget')}>
                  Budget {query.sortBy === 'budget' && (query.sortDir === 'asc' ? <ChevronUp className="inline w-3 h-3" /> : <ChevronDown className="inline w-3 h-3" />)}
                </th>
                <th tabIndex={0} role="button" onKeyDown={e => e.key === 'Enter' && handleSort('status')} className="py-4 px-6 cursor-pointer hover:text-amber-600 outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded" onClick={() => handleSort('status')}>
                  Status {query.sortBy === 'status' && (query.sortDir === 'asc' ? <ChevronUp className="inline w-3 h-3" /> : <ChevronDown className="inline w-3 h-3" />)}
                </th>
                <th tabIndex={0} role="button" onKeyDown={e => e.key === 'Enter' && handleSort('updatedAt')} className="py-4 px-6 cursor-pointer hover:text-amber-600 outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded" onClick={() => handleSort('updatedAt')}>
                  Updated {query.sortBy === 'updatedAt' && (query.sortDir === 'asc' ? <ChevronUp className="inline w-3 h-3" /> : <ChevronDown className="inline w-3 h-3" />)}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E7E1D7] dark:divide-[#2E2824] text-xs text-[#44403C] dark:text-[#D6D3D1]">
              {loading && !data && Array.from({ length: query.pageSize || 10 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                   <td className="py-4 px-6"><div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-20"></div></td>
                   <td className="py-4 px-6"><div className="h-10 w-10 bg-gray-200 dark:bg-gray-800 rounded-lg"></div></td>
                   <td className="py-4 px-6"><div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-24"></div></td>
                   <td className="py-4 px-6"><div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-24"></div></td>
                   <td className="py-4 px-6"><div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-16"></div></td>
                   <td className="py-4 px-6"><div className="h-6 bg-gray-200 dark:bg-gray-800 rounded-full w-24"></div></td>
                   <td className="py-4 px-6"><div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-20"></div></td>
                </tr>
              ))}
              {data?.items.length === 0 && !loading && (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#78716C]">
                    No requests match your filters.
                  </td>
                </tr>
              )}
              {data?.items.map(req => (
                <tr key={req.id} onClick={() => navigate(`/admin/requests/${req.id}`)} className="cursor-pointer hover:bg-[#FAF8F5]/60 dark:hover:bg-[#201C19]/60 transition group">
                  <td className="py-4 px-6 font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                    <div className="flex items-center gap-2">
                      {req.referenceCode}
                      {req.isFlagged && <Flag className="w-3 h-3 text-rose-500 fill-rose-500" />}
                    </div>
                  </td>
                  <td className="py-4 px-6">
                    {req.roomPhotoUrl ? (
                      <img src={req.roomPhotoUrl} alt="Room" className="w-10 h-10 object-cover rounded-lg" />
                    ) : (
                      <div className="w-10 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg flex items-center justify-center text-gray-400">?</div>
                    )}
                  </td>
                  <td className="py-4 px-6">{req.clientDisplayName || 'Unknown Client'}</td>
                  <td className="py-4 px-6">{req.roomType}</td>
                  <td className="py-4 px-6 font-medium">{formatCurrency(req.budget)}</td>
                  <td className="py-4 px-6">
                    <span className="px-2.5 py-1 text-[11px] font-semibold rounded-full bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525]">
                      {req.status}
                    </span>
                  </td>
                  <td className="py-4 px-6 flex items-center justify-between">
                    <span>{formatDate(req.updatedAt)}</span>
                    <ArrowRight className="w-4 h-4 text-amber-500 opacity-0 group-hover:opacity-100 transition-opacity" />
                  </td>
                </tr>
              ))}
            </tbody>
           </table>
           
           {/* Pagination Footer */}
           {data && (
             <div className="flex items-center justify-between px-6 py-4 border-t border-[#E7E1D7] dark:border-[#2E2824] bg-[#FAF8F5]/50 dark:bg-[#141210]/50">
               <div className="flex items-center gap-4 text-xs text-[#78716C]">
                 <span>Total: {data.totalCount}</span>
                 <select 
                   value={query.pageSize}
                   onChange={e => updateFilter('pageSize', e.target.value)}
                   className="bg-transparent border border-[#E7E1D7] dark:border-[#2E2824] rounded px-2 py-1 outline-none cursor-pointer"
                 >
                   <option value="10">10 / page</option>
                   <option value="25">25 / page</option>
                   <option value="50">50 / page</option>
                 </select>
               </div>
               <div className="flex items-center gap-2">
                 <button 
                   disabled={data.page <= 1}
                   onClick={() => updateFilter('page', String(data.page - 1))}
                   className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-[#E7E1D7] dark:border-[#2E2824] disabled:opacity-50 hover:bg-white dark:hover:bg-[#201C19] transition"
                 >
                   Prev
                 </button>
                 <span className="text-xs font-medium px-2">Page {data.page} of {data.totalPages || 1}</span>
                 <button 
                   disabled={data.page >= data.totalPages}
                   onClick={() => updateFilter('page', String(data.page + 1))}
                   className="px-3 py-1.5 text-xs font-semibold rounded-lg border border-[#E7E1D7] dark:border-[#2E2824] disabled:opacity-50 hover:bg-white dark:hover:bg-[#201C19] transition"
                 >
                   Next
                 </button>
               </div>
             </div>
           )}
           
           {loading && data && (
             <div className="absolute inset-0 bg-white/40 dark:bg-black/40 flex items-center justify-center backdrop-blur-[1px]">
               <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-amber-500"></div>
             </div>
           )}
        </div>
      </div>
    </div>
  );
};
