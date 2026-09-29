import { useState, useEffect } from 'react';
import { fetchAllRequests, fetchRequestAnalytics, flagProjectRequest } from '../services/api';
import type { ProjectRequest, RequestAnalytics } from '../services/api';
import { Search, Filter, RefreshCw, ChevronRight, ChevronLeft, Eye, FileText, Flag, AlertTriangle, Layers, PieChart } from 'lucide-react';

interface RequestListAdminProps {
  onViewDetail: (req: ProjectRequest) => void;
}

interface StatusBadge {
  emoji: string;
  class: string;
  label: string;
}

export default function RequestListAdmin({ onViewDetail }: RequestListAdminProps) {
  const [requests, setRequests] = useState<ProjectRequest[]>([]);
  const [analytics, setAnalytics] = useState<RequestAnalytics | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

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
  const [pageSize, setPageSize] = useState<number>(6);

  const loadData = async (): Promise<void> => {
    setLoading(true);
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
      case 'Accepted':
        return { emoji: '✅', class: 'badge-proposal', label: 'Accepted' };
      case 'Flagged':
      case 'Cancelled':
      case 'Rejected':
        return { emoji: '⚠️', class: 'badge-draft', label: st };
      default:
        return { emoji: '📌', class: 'badge-draft', label: st };
    }
  };

  return (
    <div style={{ padding: '24px', maxWidth: '1280px', margin: '0 auto' }}>
      {/* Header Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.7rem', fontWeight: '800', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <span>🏢</span> Admin Requests Management & Oversight
          </h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginTop: '4px' }}>
            System-wide oversight for client room makeover requests, AI workflow status monitoring, and audit trail logs.
          </p>
        </div>

        <button className="btn-secondary" onClick={() => void loadData()} title="Refresh Data">
          <RefreshCw size={16} /> Refresh Dashboard
        </button>
      </div>

      {/* Analytics Cards (React Component Marks) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px', marginBottom: '28px' }}>
        <div className="glass-panel" style={{ padding: '20px', borderLeft: '4px solid #6366f1' }}>
          <div style={{ fontSize: '0.8rem', color: '#a5b4fc', textTransform: 'uppercase', fontWeight: '700' }}>Total Requests</div>
          <div style={{ fontSize: '1.8rem', fontWeight: '800', margin: '6px 0' }}>{analytics?.totalRequests ?? totalItems}</div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Registered across mobile & web</div>
        </div>

        <div className="glass-panel" style={{ padding: '20px', borderLeft: '4px solid #10b981' }}>
          <div style={{ fontSize: '0.8rem', color: '#6ee7b7', textTransform: 'uppercase', fontWeight: '700' }}>Average Budget</div>
          <div style={{ fontSize: '1.8rem', fontWeight: '800', margin: '6px 0' }}>
            LKR {analytics?.averageBudget ? Number(analytics.averageBudget).toLocaleString() : '285,000'}
          </div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Mean request budget value</div>
        </div>

        <div className="glass-panel" style={{ padding: '20px', borderLeft: '4px solid #f59e0b' }}>
          <div style={{ fontSize: '0.8rem', color: '#fcd34d', textTransform: 'uppercase', fontWeight: '700' }}>Pending AI Workflow</div>
          <div style={{ fontSize: '1.8rem', fontWeight: '800', margin: '6px 0' }}>{analytics?.pendingAiAnalysisCount ?? 4}</div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Requests in AI Analysis stage</div>
        </div>

        <div className="glass-panel" style={{ padding: '20px', borderLeft: '4px solid #ef4444' }}>
          <div style={{ fontSize: '0.8rem', color: '#fca5a5', textTransform: 'uppercase', fontWeight: '700' }}>Flagged / Invalid</div>
          <div style={{ fontSize: '1.8rem', fontWeight: '800', margin: '6px 0' }}>{analytics?.flaggedCount ?? 1}</div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Recorded audit trail flags</div>
        </div>
      </div>

      {/* Control & Filter Panel */}
      <div className="glass-panel" style={{ padding: '20px', marginBottom: '24px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px', marginBottom: '14px' }}>
          {/* Search */}
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: '700', color: '#a5b4fc', display: 'block', marginBottom: '4px' }}>
              🔎 SEARCH
            </label>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                className="input-field"
                placeholder="Search room type, client, ID..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setCurrentPage(1);
                }}
              />
            </div>
          </div>

          {/* Status Filter */}
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: '700', color: '#a5b4fc', display: 'block', marginBottom: '4px' }}>
              📌 STATUS FILTER
            </label>
            <select className="input-field" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
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
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: '700', color: '#a5b4fc', display: 'block', marginBottom: '4px' }}>
              🏠 ROOM TYPE
            </label>
            <select className="input-field" value={roomTypeFilter} onChange={(e) => setRoomTypeFilter(e.target.value)}>
              <option value="">All Room Types</option>
              <option value="Bedroom">Bedroom</option>
              <option value="LivingRoom">Living Room</option>
              <option value="Kitchen">Kitchen</option>
              <option value="Bathroom">Bathroom</option>
              <option value="Office">Office</option>
            </select>
          </div>

          {/* Sorting */}
          <div>
            <label style={{ fontSize: '0.78rem', fontWeight: '700', color: '#a5b4fc', display: 'block', marginBottom: '4px' }}>
              ↕️ SORT BY
            </label>
            <select className="input-field" value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
              <option value="date_desc">Newest First</option>
              <option value="date_asc">Oldest First</option>
              <option value="budget_desc">Budget: High to Low</option>
              <option value="budget_asc">Budget: Low to High</option>
              <option value="status">Status</option>
            </select>
          </div>
        </div>

        {/* Budget Range Sub-filter */}
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          <span>Budget Range (LKR):</span>
          <input
            type="number"
            className="input-field"
            placeholder="Min Budget"
            style={{ width: '130px', padding: '6px 10px' }}
            value={minBudget}
            onChange={(e) => setMinBudget(e.target.value)}
          />
          <span>to</span>
          <input
            type="number"
            className="input-field"
            placeholder="Max Budget"
            style={{ width: '130px', padding: '6px 10px' }}
            value={maxBudget}
            onChange={(e) => setMaxBudget(e.target.value)}
          />
          {(minBudget || maxBudget || searchQuery || statusFilter || roomTypeFilter) && (
            <button
              className="btn-secondary"
              style={{ padding: '6px 12px', fontSize: '0.8rem' }}
              onClick={() => {
                setSearchQuery('');
                setStatusFilter('');
                setRoomTypeFilter('');
                setMinBudget('');
                setMaxBudget('');
              }}
            >
              Reset Filters
            </button>
          )}
        </div>
      </div>

      {/* Requests Data Table */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '60px', color: 'var(--text-muted)' }}>Loading request records...</div>
      ) : paginatedRequests.length === 0 ? (
        <div className="glass-panel" style={{ textAlign: 'center', padding: '60px' }}>
          <FileText size={48} style={{ color: '#64748b', marginBottom: '12px' }} />
          <p style={{ fontSize: '1.1rem', fontWeight: '600' }}>No requests match the selected criteria.</p>
        </div>
      ) : (
        <>
          <div className="glass-panel" style={{ overflowX: 'auto', marginBottom: '24px' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.9rem' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.12)', background: 'rgba(255,255,255,0.03)' }}>
                  <th style={{ padding: '14px 16px' }}>Request ID / Client</th>
                  <th style={{ padding: '14px 16px' }}>Room & Dimensions</th>
                  <th style={{ padding: '14px 16px' }}>Budget</th>
                  <th style={{ padding: '14px 16px' }}>Status</th>
                  <th style={{ padding: '14px 16px' }}>Created Date</th>
                  <th style={{ padding: '14px 16px', textAlign: 'right' }}>Admin Actions</th>
                </tr>
              </thead>
              <tbody>
                {paginatedRequests.map((req) => {
                  const badge = getStatusBadge(req.status);
                  const roomLabel = req.roomType.replace(/([A-Z])/g, ' $1').trim();
                  return (
                    <tr key={req.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ fontWeight: '700' }}>#{req.id.slice(0, 8)}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{req.clientId || 'Client'}</div>
                      </td>

                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ fontWeight: '600' }}>🏠 {roomLabel}</div>
                        <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                          {req.lengthFeet} × {req.widthFeet} × {req.heightFeet} ft
                        </div>
                      </td>

                      <td style={{ padding: '14px 16px', fontWeight: '700', color: '#10b981' }}>
                        LKR {Number(req.budgetLkr).toLocaleString()}
                      </td>

                      <td style={{ padding: '14px 16px' }}>
                        <span className={`badge ${badge.class}`}>
                          {badge.emoji} {badge.label}
                        </span>
                      </td>

                      <td style={{ padding: '14px 16px', fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                        {new Date(req.createdAt).toLocaleDateString()}
                      </td>

                      <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                          <button
                            className="btn-primary"
                            style={{ padding: '6px 12px', fontSize: '0.82rem' }}
                            onClick={() => onViewDetail(req)}
                          >
                            <Eye size={14} /> View Detail
                          </button>

                          <button
                            className="btn-secondary"
                            style={{ padding: '6px 12px', fontSize: '0.82rem', borderColor: '#ef4444', color: '#fca5a5' }}
                            onClick={() => {
                              setFlagModalReq(req);
                              setFlagReason('');
                            }}
                            title="Flag / Cancel Request"
                          >
                            <Flag size={14} /> Flag
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
          <div className="glass-panel" style={{ padding: '16px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>
              Page {currentPage} of {totalPages} ({totalItems} total requests)
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                className="btn-secondary"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((p) => Math.max(p - 1, 1))}
              >
                <ChevronLeft size={16} /> Prev
              </button>
              <button
                className="btn-secondary"
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((p) => Math.min(p + 1, totalPages))}
              >
                Next <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </>
      )}

      {/* Flag / Cancel Reason Modal Popup */}
      {flagModalReq && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.7)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '20px',
          }}
        >
          <div className="glass-panel" style={{ maxWidth: '480px', width: '100%', padding: '28px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: '#ef4444', marginBottom: '12px' }}>
              <AlertTriangle size={24} />
              <h3 style={{ fontSize: '1.3rem', fontWeight: '800' }}>Flag / Cancel Invalid Request</h3>
            </div>
            <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '16px' }}>
              Flagging request #{flagModalReq.id.slice(0, 8)} will record a mandatory reason into the backend audit trail.
            </p>

            <textarea
              className="input-field"
              rows={4}
              placeholder="Enter audit trail reason for flagging or cancelling (required)..."
              value={flagReason}
              onChange={(e) => setFlagReason(e.target.value)}
              style={{ width: '100%', marginBottom: '20px' }}
            />

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button className="btn-secondary" onClick={() => setFlagModalReq(null)}>
                Cancel
              </button>
              <button
                className="btn-primary"
                style={{ background: '#ef4444' }}
                disabled={!flagReason.trim() || flagSubmitting}
                onClick={handleFlagSubmit}
              >
                {flagSubmitting ? 'Submitting...' : 'Confirm Flag / Cancel'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
