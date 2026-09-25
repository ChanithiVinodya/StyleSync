import { useState, useEffect } from 'react';
import { fetchAllRequests } from '../services/api';
import type { ProjectRequest } from '../services/api';
import { Search, Filter, RefreshCw, ChevronRight, ChevronLeft, Eye, FileText } from 'lucide-react';

// ─── Types ────────────────────────────────────────────────────────────────

interface RequestListAdminProps {
  onViewDetail: (req: ProjectRequest) => void;
}

interface StatusBadge {
  emoji: string;
  class: string;
  label: string;
}

// ─── Component ────────────────────────────────────────────────────────────

export default function RequestListAdmin({ onViewDetail }: RequestListAdminProps) {
  const [requests, setRequests] = useState<ProjectRequest[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Pagination State
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(6);

  const loadRequests = async (): Promise<void> => {
    setLoading(true);
    try {
      const data = await fetchAllRequests(statusFilter, searchQuery);
      setRequests(data);
      setCurrentPage(1); // Reset to page 1 on filter/search change
    } catch (err) {
      console.error('Error loading requests:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadRequests();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  // Client-side Search & Filtering
  const filtered = requests.filter((r) => {
    const query = searchQuery.toLowerCase();
    const matchesSearch =
      r.roomType.toLowerCase().includes(query) ||
      r.description.toLowerCase().includes(query) ||
      String(r.id).toLowerCase().includes(query) ||
      (r.clientId && r.clientId.toLowerCase().includes(query));

    const matchesStatus = !statusFilter || r.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  // Pagination Logic
  const totalItems = filtered.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const startIndex = (currentPage - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, totalItems);
  const paginatedRequests = filtered.slice(startIndex, endIndex);

  const getStatusBadge = (st: string): StatusBadge => {
    switch (st) {
      case 'Draft':
        return { emoji: '📝', class: 'badge-draft', label: 'Draft' };
      case 'Submitted':
        return { emoji: '📤', class: 'badge-submitted', label: 'Submitted' };
      case 'AIAnalysis':
        return { emoji: '🤖', class: 'badge-submitted', label: 'AI Analysis' };
      case 'ProposalReady':
        return { emoji: '🟢', class: 'badge-proposal', label: 'Proposal Ready' };
      case 'AwaitingApproval':
        return { emoji: '⏳', class: 'badge-submitted', label: 'Awaiting Approval' };
      case 'Approved':
        return { emoji: '✅', class: 'badge-proposal', label: 'Approved' };
      default:
        return { emoji: '📌', class: 'badge-draft', label: st };
    }
  };

  return (
    <div style={{ padding: '24px', maxWidth: '1200px', margin: '0 auto' }}>
      {/* Header Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.6rem', fontWeight: '800', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span>🏢</span> Staff Management Dashboard
          </h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginTop: '4px' }}>
            Monitor room makeover requests, inspect AI Style Analysis outputs, and track project lifecycles.
          </p>
        </div>

        <div style={{ background: 'rgba(99, 102, 241, 0.15)', border: '1px solid rgba(99, 102, 241, 0.3)', padding: '8px 16px', borderRadius: '20px', fontSize: '0.85rem', fontWeight: '700', color: '#a5b4fc' }}>
          Total Requests: {totalItems}
        </div>
      </div>

      {/* Control Bar */}
      <div
        className="glass-panel"
        style={{
          padding: '20px',
          marginBottom: '24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: '16px',
          flexWrap: 'wrap',
        }}
      >
        {/* Search Input */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1, minWidth: '280px' }}>
          <Search size={20} style={{ color: '#818cf8' }} />
          <input
            type="text"
            className="input-field"
            placeholder="🔎 Search by room type, client ID, or description..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setCurrentPage(1);
            }}
          />
        </div>

        {/* Filter by Status */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Filter size={18} style={{ color: '#f59e0b' }} />
            <span style={{ fontSize: '0.85rem', fontWeight: '600' }}>Status:</span>
          </div>

          <select
            className="input-field"
            style={{ width: '190px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">🔽 All Statuses</option>
            <option value="Draft">📝 Draft</option>
            <option value="Submitted">📤 Submitted</option>
            <option value="AIAnalysis">🤖 AI Analysis</option>
            <option value="ProposalReady">🟢 Proposal Ready</option>
            <option value="AwaitingApproval">⏳ Awaiting Approval</option>
            <option value="Approved">✅ Approved</option>
          </select>

          <button className="btn-secondary" onClick={() => void loadRequests()} title="Refresh Requests">
            <RefreshCw size={16} /> Refresh
          </button>
        </div>
      </div>

      {/* Request Grid */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '60px', color: 'var(--text-muted)' }}>
          Loading requests from ASP.NET Core backend...
        </div>
      ) : paginatedRequests.length === 0 ? (
        <div className="glass-panel" style={{ textAlign: 'center', padding: '60px', color: 'var(--text-muted)' }}>
          <FileText size={48} style={{ color: '#64748b', marginBottom: '12px' }} />
          <p style={{ fontSize: '1.1rem', fontWeight: '600' }}>No matching room makeover requests found.</p>
          <p style={{ fontSize: '0.85rem', marginTop: '4px' }}>Try adjusting your search query or status filter.</p>
        </div>
      ) : (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '24px', marginBottom: '24px' }}>
            {paginatedRequests.map((req) => {
              const badge = getStatusBadge(req.status);
              // Backend stores budget in budgetMin/budgetMax and dimensions in specialRequirements
              const raw = req as unknown as Record<string, unknown>;
              const budget = (raw.budgetMin ?? raw.budgetMax ?? req.budgetLkr) as number | undefined;
              const specReq = (raw.specialRequirements ?? '') as string;
              const dimMatch = specReq.match(/Dimensions:\s*(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)/i);
              const dims = dimMatch
                ? { l: dimMatch[1], w: dimMatch[2], h: dimMatch[3] }
                : { l: req.lengthFeet, w: req.widthFeet, h: req.heightFeet };
              // Format enum name: LivingRoom → Living Room
              const roomLabel = req.roomType.replace(/([A-Z])/g, ' $1').trim();
              return (
                <div key={req.id} className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', transition: 'transform 0.2s', border: '1px solid rgba(255,255,255,0.12)' }}>
                  <div>
                    {/* Status Badge & Room Type */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                      <div>
                        <h3 style={{ fontSize: '1.2rem', fontWeight: '800' }}>🏠 {roomLabel}</h3>
                        <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                          Client: {req.clientId || 'default'} | ID: {req.id}
                        </span>
                      </div>
                      <span className={`badge ${badge.class}`}>
                        {badge.emoji} {badge.label}
                      </span>
                    </div>

                    {/* Specs & Budget */}
                    <div style={{ display: 'flex', gap: '16px', fontSize: '0.88rem', color: '#cbd5e1', marginBottom: '16px', background: 'rgba(255,255,255,0.04)', padding: '10px 14px', borderRadius: '8px' }}>
                      {dims.l && dims.w && dims.h
                        ? <span>📏 {dims.l} × {dims.w} × {dims.h} ft</span>
                        : <span>📏 Dimensions not set</span>}
                      <span>💰 LKR {budget != null && !isNaN(Number(budget)) ? Number(budget).toLocaleString() : 'N/A'}</span>
                    </div>

                    {/* Description excerpt */}
                    <p style={{ fontSize: '0.9rem', color: '#94a3b8', marginBottom: '16px', fontStyle: 'italic', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                      {req.description ? `"${req.description}"` : 'No description provided'}
                    </p>

                    {/* Style Analysis Preview */}
                    {req.styleAnalysis ? (
                      <div style={{ background: 'linear-gradient(135deg, rgba(99,102,241,0.15) 0%, rgba(168,85,247,0.15) 100%)', padding: '12px 14px', borderRadius: '10px', border: '1px solid rgba(99,102,241,0.3)', marginBottom: '16px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                          <span style={{ fontWeight: '700', color: '#a5b4fc', fontSize: '0.85rem' }}>
                            🤖 AI Style: {req.styleAnalysis.primaryStyle}
                          </span>
                          <span style={{ color: '#fcd34d', fontWeight: '800', fontSize: '0.82rem' }}>
                            {req.styleAnalysis.confidenceScore}% confidence
                          </span>
                        </div>
                        <span style={{ fontSize: '0.78rem', color: '#cbd5e1' }}>
                          Accent: 🤍 {req.styleAnalysis.secondaryStyle}
                        </span>
                      </div>
                    ) : (
                      <div style={{ background: 'rgba(255,255,255,0.03)', padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        📝 Draft request (Submit to run AI Style Analysis)
                      </div>
                    )}
                  </div>

                  {/* View Button */}
                  <button
                    className="btn-primary"
                    style={{ width: '100%', justifyContent: 'center' }}
                    onClick={() => onViewDetail(req)}
                  >
                    <Eye size={16} /> 👁️ View Request &amp; AI Analysis <ChevronRight size={16} />
                  </button>
                </div>
              );
            })}
          </div>

          {/* Pagination Bar */}
          <div
            className="glass-panel"
            style={{
              padding: '16px 24px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: '16px',
            }}
          >
            <div style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>
              Showing <strong style={{ color: 'white' }}>{totalItems > 0 ? startIndex + 1 : 0}</strong> to{' '}
              <strong style={{ color: 'white' }}>{endIndex}</strong> of{' '}
              <strong style={{ color: 'white' }}>{totalItems}</strong> requests
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Items per page:</span>
              <select
                className="input-field"
                style={{ width: '80px', padding: '6px 10px' }}
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value));
                  setCurrentPage(1);
                }}
              >
                <option value={3}>3</option>
                <option value={6}>6</option>
                <option value={12}>12</option>
                <option value={24}>24</option>
              </select>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <button
                className="btn-secondary"
                style={{ padding: '8px 14px', opacity: currentPage === 1 ? 0.4 : 1, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((prev) => Math.max(prev - 1, 1))}
              >
                <ChevronLeft size={16} /> Previous
              </button>

              <span style={{ padding: '0 8px', fontSize: '0.88rem', fontWeight: '700', color: '#a5b4fc' }}>
                Page {currentPage} of {totalPages}
              </span>

              <button
                className="btn-secondary"
                style={{ padding: '8px 14px', opacity: currentPage === totalPages ? 0.4 : 1, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((prev) => Math.min(prev + 1, totalPages))}
              >
                Next <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
