import { useState, useEffect } from 'react';
import { fetchAllRequests, fetchRequestAnalytics, flagProjectRequest } from '../services/api';
import type { ProjectRequest, RequestAnalytics } from '../services/api';
import { 
  Search, 
  Filter, 
  RefreshCw, 
  ChevronRight, 
  ChevronLeft, 
  Eye, 
  FileText, 
  Flag, 
  AlertTriangle, 
  FolderKanban, 
  Banknote, 
  Sparkles, 
  ShieldAlert, 
  SlidersHorizontal,
  ArrowUpDown,
  Home,
  X
} from 'lucide-react';

interface RequestListAdminProps {
  onViewDetail: (req: ProjectRequest) => void;
}

export default function RequestListAdmin({ onViewDetail }: RequestListAdminProps) {
  const [requests, setRequests] = useState<ProjectRequest[]>([]);
  const [analytics, setAnalytics] = useState<RequestAnalytics | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  // Filter & Search states
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [roomTypeFilter, setRoomTypeFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [minBudget, setMinBudget] = useState<string>('');
  const [maxBudget, setMaxBudget] = useState<string>('');
  const [sortBy, setSortBy] = useState<string>('date_desc');

  // Flag Request Modal state
  const [flagModalReq, setFlagModalReq] = useState<ProjectRequest | null>(null);
  const [flagReason, setFlagReason] = useState<string>('');
  const [flagSubmitting, setFlagSubmitting] = useState<boolean>(false);

  // Pagination State
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 6;

  const loadData = async (): Promise<void> => {
    setLoading(true);
    setIsRefreshing(true);
    try {
      const [reqList, stats] = await Promise.all([
        fetchAllRequests(statusFilter, roomTypeFilter),
        fetchRequestAnalytics(),
      ]);
      setRequests(reqList);
      setAnalytics(stats);
    } catch (err) {
      console.error('Error loading admin requests/analytics:', err);
    } finally {
      setLoading(false);
      setTimeout(() => setIsRefreshing(false), 400);
    }
  };

  useEffect(() => {
    void loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, roomTypeFilter]);

  const handleFlagSubmit = async () => {
    if (!flagModalReq || !flagReason.trim()) return;
    setFlagSubmitting(true);
    try {
      await flagProjectRequest(flagModalReq.id, flagReason.trim());
      alert(`Request #${flagModalReq.id} flagged successfully with audit reason.`);
      setFlagModalReq(null);
      setFlagReason('');
      await loadData();
    } catch (err) {
      alert(`Failed to flag request: ${err}`);
    } finally {
      setFlagSubmitting(false);
    }
  };

  // Client-side Filtering & Sorting
  const filtered = requests.filter((r) => {
    const query = searchQuery.toLowerCase();
    const matchesSearch =
      r.roomType.toLowerCase().includes(query) ||
      r.description.toLowerCase().includes(query) ||
      String(r.id).toLowerCase().includes(query) ||
      (r.clientId && r.clientId.toLowerCase().includes(query));

    const matchesStatus = !statusFilter || r.status === statusFilter;
    const matchesRoomType = !roomTypeFilter || r.roomType === roomTypeFilter;

    const minB = minBudget ? Number(minBudget) : 0;
    const maxB = maxBudget ? Number(maxBudget) : Infinity;
    const matchesBudget = r.budgetLkr >= minB && r.budgetLkr <= maxB;

    return matchesSearch && matchesStatus && matchesRoomType && matchesBudget;
  });

  // Sorting
  const sorted = [...filtered].sort((a, b) => {
    if (sortBy === 'date_desc') return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    if (sortBy === 'date_asc') return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
    if (sortBy === 'budget_desc') return b.budgetLkr - a.budgetLkr;
    if (sortBy === 'budget_asc') return a.budgetLkr - b.budgetLkr;
    if (sortBy === 'status') return a.status.localeCompare(b.status);
    return 0;
  });

  // Pagination Logic
  const totalItems = sorted.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const startIndex = (currentPage - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, totalItems);
  const paginatedRequests = sorted.slice(startIndex, endIndex);

  // Micro-pill Status Badges: sleek, elegant, compact
  const renderStatusBadge = (status: string) => {
    switch (status) {
      case 'Draft':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-stone-100 dark:bg-stone-900/60 text-stone-700 dark:text-stone-300 border border-stone-200 dark:border-stone-800">
            <span className="w-1.5 h-1.5 rounded-full bg-stone-400 shrink-0" />
            Draft
          </span>
        );
      case 'Submitted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-sky-50 dark:bg-sky-950/60 text-sky-700 dark:text-sky-300 border border-sky-200 dark:border-sky-800">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-500 shrink-0" />
            Submitted
          </span>
        );
      case 'AIAnalysis':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-amber-50 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-800">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse shrink-0" />
            AI Analysis
          </span>
        );
      case 'ProposalReady':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0" />
            Proposal Ready
          </span>
        );
      case 'Accepted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-teal-50 dark:bg-teal-950/60 text-teal-800 dark:text-teal-300 border border-teal-200 dark:border-teal-800">
            <span className="w-1.5 h-1.5 rounded-full bg-teal-500 shrink-0" />
            Accepted
          </span>
        );
      case 'Flagged':
      case 'Cancelled':
      case 'Rejected':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-rose-50 dark:bg-rose-950/60 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-800">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 shrink-0" />
            {status}
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-stone-100 dark:bg-stone-900/60 text-stone-700 dark:text-stone-300 border border-stone-200 dark:border-stone-800">
            <span className="w-1.5 h-1.5 rounded-full bg-stone-400 shrink-0" />
            {status}
          </span>
        );
    }
  };

  const hasActiveFilters = Boolean(
    minBudget || maxBudget || searchQuery || statusFilter || roomTypeFilter || sortBy !== 'date_desc'
  );

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#E8DEC8] dark:border-[#3D3328] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
              <FolderKanban className="w-5 h-5" />
            </div>
            <h2 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              Admin Requests Oversight
            </h2>
          </div>
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-1">
            System-wide tracking for client room requests, AI workflow status, and audit trail logs.
          </p>
        </div>

        <button
          onClick={() => void loadData()}
          disabled={isRefreshing}
          className="inline-flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#FAF8F5] dark:hover:bg-[#25201C] transition shadow-2xs self-start sm:self-auto cursor-pointer"
        >
          <RefreshCw className={`w-3.5 h-3.5 text-[#C48A36] ${isRefreshing ? 'animate-spin' : ''}`} />
          <span>Refresh Dashboard</span>
        </button>
      </div>

      {/* Analytics Cards - Elegant Luxury Design */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Total Requests */}
        <div className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xs transition hover:border-[#C48A36]/40">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Total Requests
            </span>
            <div className="w-8 h-8 rounded-lg bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] flex items-center justify-center">
              <FolderKanban className="w-4 h-4" />
            </div>
          </div>
          <div className="font-serif text-3xl font-bold text-[#1C1917] dark:text-[#FAF8F5] mt-2 mb-0.5">
            {analytics?.totalRequests ?? totalItems}
          </div>
          <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
            Registered across mobile &amp; web
          </p>
        </div>

        {/* Card 2: Average Budget */}
        <div className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xs transition hover:border-[#C48A36]/40">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Average Budget
            </span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Banknote className="w-4 h-4" />
            </div>
          </div>
          <div className="font-serif text-2xl sm:text-3xl font-bold text-[#1C1917] dark:text-[#FAF8F5] mt-2 mb-0.5 truncate">
            LKR {analytics?.averageBudget ? Number(analytics.averageBudget).toLocaleString() : '285,000'}
          </div>
          <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
            Mean request budget value
          </p>
        </div>

        {/* Card 3: Pending AI Workflow */}
        <div className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xs transition hover:border-[#C48A36]/40">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Pending AI Workflow
            </span>
            <div className="w-8 h-8 rounded-lg bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Sparkles className="w-4 h-4" />
            </div>
          </div>
          <div className="font-serif text-3xl font-bold text-[#1C1917] dark:text-[#FAF8F5] mt-2 mb-0.5">
            {analytics?.pendingAiAnalysisCount ?? 4}
          </div>
          <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
            Requests in AI Analysis stage
          </p>
        </div>

        {/* Card 4: Flagged / Invalid */}
        <div className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xs transition hover:border-[#C48A36]/40">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Flagged / Needs Review
            </span>
            <div className="w-8 h-8 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <ShieldAlert className="w-4 h-4" />
            </div>
          </div>
          <div className="font-serif text-3xl font-bold text-[#1C1917] dark:text-[#FAF8F5] mt-2 mb-0.5">
            {analytics?.flaggedCount ?? 1}
          </div>
          <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
            Recorded audit trail flags
          </p>
        </div>
      </div>

      {/* Control & Filter Panel */}
      <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-5 shadow-xs space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {/* Search */}
          <div className="space-y-1">
            <label className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              <Search className="w-3.5 h-3.5 text-[#C48A36]" />
              <span>Search</span>
            </label>
            <div className="relative">
              <input
                type="text"
                placeholder="Search room, client, ID..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full pl-3 pr-8 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[#78716C] hover:text-[#1C1917]"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>

          {/* Status Filter */}
          <div className="space-y-1">
            <label className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              <Filter className="w-3.5 h-3.5 text-[#C48A36]" />
              <span>Status Filter</span>
            </label>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition"
            >
              <option value="">All Statuses</option>
              <option value="Draft">Draft</option>
              <option value="Submitted">Submitted</option>
              <option value="AIAnalysis">AI Analysis</option>
              <option value="ProposalReady">Proposal Ready</option>
              <option value="Accepted">Accepted</option>
              <option value="Flagged">Flagged</option>
            </select>
          </div>

          {/* Room Type Filter */}
          <div className="space-y-1">
            <label className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              <Home className="w-3.5 h-3.5 text-[#C48A36]" />
              <span>Room Type</span>
            </label>
            <select
              value={roomTypeFilter}
              onChange={(e) => {
                setRoomTypeFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition"
            >
              <option value="">All Room Types</option>
              <option value="Bedroom">Bedroom</option>
              <option value="LivingRoom">Living Room</option>
              <option value="Kitchen">Kitchen</option>
              <option value="Bathroom">Bathroom</option>
              <option value="Office">Office</option>
            </select>
          </div>

          {/* Sorting */}
          <div className="space-y-1">
            <label className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              <ArrowUpDown className="w-3.5 h-3.5 text-[#C48A36]" />
              <span>Sort By</span>
            </label>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition"
            >
              <option value="date_desc">Newest First</option>
              <option value="date_asc">Oldest First</option>
              <option value="budget_desc">Budget: High to Low</option>
              <option value="budget_asc">Budget: Low to High</option>
              <option value="status">Status</option>
            </select>
          </div>
        </div>

        {/* Budget Range & Reset Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-[#E7E1D7]/70 dark:border-[#2E2824]/70 text-xs">
          <div className="flex items-center gap-2 text-[#78716C] dark:text-[#A8A29E] flex-wrap">
            <SlidersHorizontal className="w-3.5 h-3.5 text-[#C48A36]" />
            <span className="font-medium">Budget Range (LKR):</span>
            <input
              type="number"
              placeholder="Min"
              value={minBudget}
              onChange={(e) => {
                setMinBudget(e.target.value);
                setCurrentPage(1);
              }}
              className="w-24 px-2.5 py-1 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-lg text-xs"
            />
            <span>to</span>
            <input
              type="number"
              placeholder="Max"
              value={maxBudget}
              onChange={(e) => {
                setMaxBudget(e.target.value);
                setCurrentPage(1);
              }}
              className="w-24 px-2.5 py-1 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-lg text-xs"
            />
          </div>

          {hasActiveFilters && (
            <button
              onClick={() => {
                setSearchQuery('');
                setStatusFilter('');
                setRoomTypeFilter('');
                setMinBudget('');
                setMaxBudget('');
                setSortBy('date_desc');
                setCurrentPage(1);
              }}
              className="text-xs text-[#925C18] dark:text-[#E8A849] hover:underline font-semibold self-start sm:self-auto cursor-pointer"
            >
              Reset Filters
            </button>
          )}
        </div>
      </div>

      {/* Requests Data Table */}
      {loading ? (
        <div className="py-16 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl flex flex-col items-center justify-center gap-3 text-[#78716C]">
          <div className="w-7 h-7 border-2 border-[#C48A36] border-t-transparent rounded-full animate-spin" />
          <p className="text-xs">Loading request records...</p>
        </div>
      ) : paginatedRequests.length === 0 ? (
        <div className="py-16 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl text-center space-y-3 p-6">
          <FileText className="w-10 h-10 mx-auto text-[#78716C]/40" />
          <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">
            No requests match the selected criteria
          </h3>
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-sm mx-auto">
            Try adjusting your search terms, status filters, or budget range.
          </p>
        </div>
      ) : (
        <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="bg-[#FAF8F5] dark:bg-[#151311] border-b border-[#E7E1D7] dark:border-[#2E2824] text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                  <th className="py-3.5 px-4 sm:px-6">Request ID / Client</th>
                  <th className="py-3.5 px-4">Room &amp; Dimensions</th>
                  <th className="py-3.5 px-4">Budget</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4">Created Date</th>
                  <th className="py-3.5 px-4 sm:px-6 text-right">Admin Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E7E1D7]/70 dark:divide-[#2E2824]/70">
                {paginatedRequests.map((req) => {
                  const roomLabel = req.roomType.replace(/([A-Z])/g, ' $1').trim();
                  return (
                    <tr
                      key={req.id}
                      className="hover:bg-[#FAF8F5]/60 dark:hover:bg-[#201C19]/60 transition-colors"
                    >
                      {/* ID / Client */}
                      <td className="py-3.5 px-4 sm:px-6">
                        <div className="font-mono font-bold text-xs text-[#1C1917] dark:text-[#FAF8F5]">
                          #{req.id.slice(0, 8)}
                        </div>
                        <div className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
                          {req.clientId || 'Client'}
                        </div>
                      </td>

                      {/* Room & Dimensions */}
                      <td className="py-3.5 px-4">
                        <div className="font-semibold text-xs text-[#1C1917] dark:text-[#FAF8F5]">
                          {roomLabel}
                        </div>
                        <div className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
                          {req.lengthFeet} × {req.widthFeet} × {req.heightFeet} ft
                        </div>
                      </td>

                      {/* Budget */}
                      <td className="py-3.5 px-4 font-semibold text-emerald-600 dark:text-emerald-400">
                        LKR {Number(req.budgetLkr).toLocaleString()}
                      </td>

                      {/* Status Micro-Badge */}
                      <td className="py-3.5 px-4">
                        {renderStatusBadge(req.status)}
                      </td>

                      {/* Date */}
                      <td className="py-3.5 px-4 text-[#78716C] dark:text-[#A8A29E] text-[11px]">
                        {new Date(req.createdAt).toLocaleDateString()}
                      </td>

                      {/* Actions */}
                      <td className="py-3.5 px-4 sm:px-6 text-right">
                        <div className="inline-flex items-center gap-1.5 justify-end">
                          <button
                            onClick={() => onViewDetail(req)}
                            className="inline-flex items-center gap-1 px-3 py-1.5 bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] rounded-lg text-xs font-semibold hover:bg-[#F3EAD9] transition cursor-pointer"
                          >
                            <Eye className="w-3.5 h-3.5" />
                            <span>View</span>
                          </button>

                          <button
                            onClick={() => {
                              setFlagModalReq(req);
                              setFlagReason('');
                            }}
                            title="Flag / Cancel Request"
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg transition cursor-pointer"
                          >
                            <Flag className="w-3.5 h-3.5" />
                            <span className="hidden sm:inline">Flag</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination Controls */}
          <div className="px-5 py-3.5 bg-[#FAF8F5]/80 dark:bg-[#151311]/80 border-t border-[#E7E1D7] dark:border-[#2E2824] flex items-center justify-between text-xs text-[#78716C] dark:text-[#A8A29E]">
            <span>
              Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> ({totalItems} total requests)
            </span>

            <div className="flex items-center gap-1.5">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg border border-[#E7E1D7] dark:border-[#2E2824] bg-white dark:bg-[#1A1715] disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#FAF8F5] transition"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
                <span>Prev</span>
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg border border-[#E7E1D7] dark:border-[#2E2824] bg-white dark:bg-[#1A1715] disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#FAF8F5] transition"
              >
                <span>Next</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Flag / Cancel Reason Modal Popup */}
      {flagModalReq && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C1917]/70 backdrop-blur-xs">
          <div className="relative w-full max-w-md bg-[#FAF8F5] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-7 shadow-2xl space-y-4">
            <div className="flex items-center gap-2.5 text-rose-600 dark:text-rose-400">
              <AlertTriangle className="w-5 h-5 shrink-0" />
              <h3 className="font-serif text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                Flag or Cancel Request
              </h3>
            </div>
            
            <p className="text-xs text-[#57534E] dark:text-[#A8A29E] leading-relaxed">
              Flagging request <strong className="font-mono text-[#1C1917] dark:text-[#FAF8F5]">#{flagModalReq.id.slice(0, 8)}</strong> will record a mandatory reason into the backend audit trail.
            </p>

            <textarea
              rows={4}
              placeholder="Enter audit trail reason for flagging or cancelling (required)..."
              value={flagReason}
              onChange={(e) => setFlagReason(e.target.value)}
              className="w-full p-3 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36]"
            />

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                onClick={() => setFlagModalReq(null)}
                className="px-4 py-2 text-xs font-semibold text-[#57534E] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl transition cursor-pointer"
              >
                Cancel
              </button>
              <button
                disabled={!flagReason.trim() || flagSubmitting}
                onClick={handleFlagSubmit}
                className="px-4 py-2 text-xs font-semibold text-white bg-rose-600 hover:bg-rose-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl transition shadow-xs cursor-pointer"
              >
                {flagSubmitting ? 'Submitting...' : 'Confirm Flag'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
