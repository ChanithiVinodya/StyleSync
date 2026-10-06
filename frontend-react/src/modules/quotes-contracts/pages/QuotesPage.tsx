import { useEffect, useState } from "react";
import { 
  listQuotes, 
  createQuote, 
  updateQuote, 
  stage1Decision, 
  stage2Decision, 
  exportQuote, 
  draftQuoteFromAgent 
} from "../api/quotesApi";
import StatusBadge from "../components/StatusBadge";
import QuoteFormModal, { type QuoteFormPayload } from "../components/QuoteFormModal";
import AiDraftModal, { type AiDraftPayload } from "../components/AiDraftModal";
import type { Quote, QuoteItem, QuoteVersion } from "../types";
import { useAuth } from "../../../auth/AuthContext";
import "../styles/theme.css";

const STATUS_OPTIONS = [
  "Draft", 
  "Stage1Pending", 
  "Stage1RevisionRequested", 
  "Stage1Released", 
  "Stage2Approved", 
  "Stage2ChangesRequested", 
  "Stage2Rejected"
];
const PAGE_SIZE = 10;

function formatMoney(value: number | undefined) {
  const num = Number(value);
  if (isNaN(num)) return "LKR 0.00";
  return `LKR ${num.toLocaleString(undefined, { minimumFractionDigits: 2 })}`;
}

interface QuotesPageProps {
  onGoToContracts?: () => void;
}

export default function QuotesPage({ onGoToContracts }: QuotesPageProps = {}) {
  const { user } = useAuth();
  const isAdmin = user?.role === "Admin";
  const isDesigner = user?.role === "Designer";
  const isClient = user?.role === "Client";

  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modals
  const [modalOpen, setModalOpen] = useState(false);
  const [editingQuote, setEditingQuote] = useState<Quote | null>(null);
  const [aiModalOpen, setAiModalOpen] = useState(false);
  const [viewingQuote, setViewingQuote] = useState<Quote | null>(null);
  const [versionHistoryQuote, setVersionHistoryQuote] = useState<Quote | null>(null);
  const [approvingQuote, setApprovingQuote] = useState<Quote | null>(null);
  const [selectedDesignerId, setSelectedDesignerId] = useState<string>("");

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const result = await listQuotes({ 
        status: statusFilter || undefined, 
        search: search || undefined, 
        page, 
        pageSize: PAGE_SIZE 
      });
      setQuotes(result?.items || []);
      setTotalCount(result?.totalCount || 0);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't load quotes.");
      setQuotes([]);
      setTotalCount(0);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, statusFilter]);

  function handleSearchSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setPage(1);
    refresh();
  }

  async function handleCreate(payload: QuoteFormPayload) {
    await createQuote({
      ...payload,
      projectRequestId: payload.projectRequestId ?? crypto.randomUUID(),
      designerId: payload.designerId ?? user?.id ?? crypto.randomUUID(),
    });
    setModalOpen(false);
    refresh();
  }

  async function handleEdit(payload: QuoteFormPayload) {
    if (!editingQuote?.id) return;
    await updateQuote(editingQuote.id, payload);
    setEditingQuote(null);
    refresh();
  }

  // Stage 1 Decisions (Admin)
  async function handleStage1(quote: Quote, action: "Release" | "SendForRevision" | "Reject") {
    if (!quote?.id) return;
    const notes = prompt(`Enter optional feedback for Stage 1 ${action}:`) ?? undefined;
    try {
      await stage1Decision(quote.id, action, notes);
      await refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Stage 1 decision failed.");
    }
  }

  function handleOpenApproveModal(quote: Quote) {
    setApprovingQuote(quote);
    const topRec = quote.recommendedDesigners?.[0];
    const initialDesigner = topRec ? (topRec.userId || String(topRec.profileId)) : quote.designerId;
    setSelectedDesignerId(initialDesigner);
  }

  // Stage 2 Decisions (Client)
  async function handleStage2(
    quote: Quote, 
    action: "Approve" | "RequestChanges" | "Reject",
    chosenDesignerId?: string
  ) {
    if (!quote?.id) return;
    const feedback = action !== "Approve" ? (prompt("Provide feedback to designer:") ?? undefined) : undefined;
    try {
      await stage2Decision(quote.id, action, feedback, undefined, chosenDesignerId);
      setApprovingQuote(null);
      await refresh();
      if (action === "Approve" && onGoToContracts) {
        onGoToContracts();
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : "Stage 2 decision failed.");
    }
  }

  async function handleExport(quote: Quote, format: "pdf" | "csv") {
    if (!quote?.id) return;
    await exportQuote(quote.id, format);
  }

  async function handleAiDraft(
    payload: AiDraftPayload,
    finalQuote?: { scopeSummary: string; notes: string; items: QuoteItem[] }
  ) {
    if (finalQuote && finalQuote.items.length > 0) {
      await createQuote({
        projectRequestId: payload.projectRequestId ?? crypto.randomUUID(),
        designerId: payload.designerId ?? user?.id ?? crypto.randomUUID(),
        scopeSummary: finalQuote.scopeSummary,
        notes: finalQuote.notes,
        isAiGenerated: true,
        items: finalQuote.items,
      });
    } else {
      await draftQuoteFromAgent(payload);
    }
    setAiModalOpen(false);
    refresh();
  }

  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <div className="qc-page">
      <div className="qc-page__header">
        <div>
          <div className="qc-page__title">
            {isAdmin ? "Admin Governance & Quotes Portal" : isDesigner ? "Designer Quotation Studio" : "Client Quotes & Proposals"}
          </div>
          <div className="qc-page__subtitle">
            {isAdmin 
              ? "Review paused AI proposals awaiting Stage 1 Release, inspect version history, and govern client contracts."
              : isDesigner
              ? "Draft quotes with Quotation Engine, revise line items with budget-guard, and export FF&E specs."
              : "Review itemized cost breakdowns of released quotes, inspect revisions, and approve or request changes."}
          </div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          {!isClient && (
            <>
              <button
                className="qc-btn"
                style={{
                  background: "linear-gradient(135deg, #C48A36 0%, #D97706 100%)",
                  color: "#ffffff",
                  border: "none",
                  fontWeight: 600,
                  boxShadow: "0 2px 8px rgba(196, 138, 54, 0.35)",
                  display: "flex",
                  alignItems: "center",
                  gap: 6
                }}
                onClick={() => setAiModalOpen(true)}
              >
                <span>✨</span> Draft with AI
              </button>
              <button className="qc-btn qc-btn--primary" onClick={() => setModalOpen(true)}>New Quote</button>
            </>
          )}
        </div>
      </div>

      <div className="qc-toolbar">
        <form onSubmit={handleSearchSubmit} style={{ display: "flex", gap: 8 }}>
          <input
            className="qc-input"
            placeholder="Search scope summary…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button type="submit" className="qc-btn qc-btn--ghost">Search</button>
        </form>

        <select
          className="qc-select"
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
        >
          <option value="">All statuses</option>
          {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>

      <div className="qc-table-card">
        <div className="qc-table-responsive">
          <table className="qc-table">
            <thead>
              <tr>
                <th style={{ minWidth: 260 }}>Scope &amp; Version</th>
                <th style={{ width: 120 }}>Status</th>
                <th style={{ width: 80, textAlign: "center" }}>Items</th>
                <th style={{ width: 140 }}>Total Amount</th>
                <th style={{ width: 110 }}>Updated</th>
                <th style={{ textAlign: "right", minWidth: 240, paddingRight: 20 }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={6} className="qc-table-empty">Loading quotes…</td></tr>}
              {!loading && error && <tr><td colSpan={6} className="qc-table-empty" style={{ color: "var(--qc-danger)" }}>{error}</td></tr>}
              {!loading && !error && (!quotes || quotes.length === 0) && (
                <tr><td colSpan={6} className="qc-table-empty">No quotes found in this view.</td></tr>
              )}
              {!loading && !error && quotes?.map((q) => {
                const statusStr = typeof q.status === "string" ? q.status : (q.status as any)?.value ?? "";
                const isStage1Pending = statusStr === "Stage1Pending" || statusStr === "Submitted" || statusStr === "Draft";
                const isReleased = statusStr === "Stage1Released" || statusStr === "ClientReview";
                const currentVer = q.currentVersion;
                const versionCount = (q.versions?.length || 0) > 0 ? q.versions!.length : 1;

                return (
                  <tr key={q.id}>
                    <td>
                      <div style={{ fontWeight: 600, fontSize: 13.5 }}>{q.scopeSummary || "Interior Design Proposal"}</div>
                      <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 4 }}>
                        <span style={{ fontFamily: "monospace", fontSize: 11, color: "var(--qc-muted)" }}>
                          ID: {q.id ? `${q.id.slice(0, 8)}…` : "—"}
                        </span>
                        <span
                          onClick={() => setVersionHistoryQuote(q)}
                          style={{
                            fontSize: 11,
                            background: "rgba(196, 138, 54, 0.12)",
                            color: "#C48A36",
                            padding: "1px 7px",
                            borderRadius: 4,
                            cursor: "pointer",
                            fontWeight: 600
                          }}
                          title="Click to view full version history"
                        >
                          📜 v{currentVer?.versionNumber ?? 1} ({versionCount} {versionCount === 1 ? "version" : "versions"})
                        </span>
                        {q.isAiGenerated && <span className="qc-ai-tag">AI Draft</span>}
                      </div>
                    </td>
                    <td><StatusBadge status={q.status} /></td>
                    <td style={{ textAlign: "center", color: "var(--qc-muted)" }}>{q.items?.length ?? 0}</td>
                    <td className="qc-money">{formatMoney(q.totalCost)}</td>
                    <td style={{ color: "var(--qc-muted)", fontSize: 12.5, whiteSpace: "nowrap" }}>
                      {q.updatedAt ? new Date(q.updatedAt).toLocaleDateString() : "—"}
                    </td>
                    <td style={{ textAlign: "right", paddingRight: 20 }}>
                      <div style={{ display: "flex", gap: 6, justifyContent: "flex-end", alignItems: "center", flexWrap: "wrap" }}>
                        <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => setViewingQuote(q)}>
                          Inspect
                        </button>

                        {/* Export */}
                        <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => handleExport(q, "csv")} title="Export CSV">
                          CSV
                        </button>

                        {/* Designer actions: Revise */}
                        {!isClient && statusStr !== "Stage2Approved" && statusStr !== "Accepted" && (
                          <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => setEditingQuote(q)}>
                            Revise
                          </button>
                        )}

                        {/* Stage 1 Admin Approval Gate */}
                        {isAdmin && isStage1Pending && (
                          <>
                            <button className="qc-btn qc-btn--primary qc-btn--sm" onClick={() => handleStage1(q, "Release")}>
                              Release
                            </button>
                            <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => handleStage1(q, "SendForRevision")}>
                              Request Rev
                            </button>
                            <button className="qc-btn qc-btn--danger qc-btn--sm" onClick={() => handleStage1(q, "Reject")}>
                              Reject
                            </button>
                          </>
                        )}

                        {/* Stage 2 Client Approval Gate */}
                        {isReleased && (
                          <>
                            <button className="qc-btn qc-btn--primary qc-btn--sm" onClick={() => handleOpenApproveModal(q)}>
                              Approve
                            </button>
                            <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => handleStage2(q, "RequestChanges")}>
                              Changes
                            </button>
                            <button className="qc-btn qc-btn--danger qc-btn--sm" onClick={() => handleStage2(q, "Reject")}>
                              Reject
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="qc-pagination">
          <span>{totalCount} quote{totalCount === 1 ? "" : "s"}</span>
          <div style={{ display: "flex", gap: 6 }}>
            <button className="qc-btn qc-btn--ghost qc-btn--sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
            <span style={{ padding: "4px 8px", fontSize: 13 }}>Page {page} of {totalPages}</span>
            <button className="qc-btn qc-btn--ghost qc-btn--sm" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
          </div>
        </div>
      </div>

      {/* Recommended Designer Selection & Quote Approval Modal */}
      {approvingQuote && (
        <div className="qc-modal-backdrop" onMouseDown={() => setApprovingQuote(null)}>
          <div 
            className="qc-modal qc-modal--lg" 
            style={{ maxWidth: 720, maxHeight: "90vh", overflowY: "auto" }}
            onMouseDown={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 14, borderBottom: "1px solid var(--qc-border)", paddingBottom: 12 }}>
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <h2 className="qc-modal__title" style={{ margin: 0, fontSize: 18 }}>Select Designer & Approve Quote</h2>
                  <span style={{ fontSize: 11, background: "rgba(196, 138, 54, 0.15)", color: "#C48A36", padding: "2px 8px", borderRadius: 999, fontWeight: 600 }}>
                    AI Recommendations
                  </span>
                </div>
                <div style={{ fontSize: 12.5, color: "var(--qc-muted)", marginTop: 4 }}>
                  Choose your preferred interior designer from the AI compatibility shortlist to finalize and generate your official contract.
                </div>
              </div>
              <button type="button" className="qc-icon-btn" onClick={() => setApprovingQuote(null)}>✕</button>
            </div>

            {/* Quote Summary Banner */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", background: "var(--qc-surface-sunken)", border: "1px solid var(--qc-border)", borderRadius: 8, padding: "12px 16px", marginBottom: 16 }}>
              <div>
                <div style={{ fontSize: 11, textTransform: "uppercase", fontWeight: 700, color: "var(--qc-muted)" }}>Project Scope</div>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--qc-ink)", marginTop: 2 }}>{approvingQuote.scopeSummary}</div>
                {approvingQuote.projectReferenceCode && (
                  <div style={{ fontSize: 11.5, color: "var(--qc-muted)", fontFamily: "monospace", marginTop: 2 }}>
                    Ref: {approvingQuote.projectReferenceCode}
                  </div>
                )}
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 11, textTransform: "uppercase", fontWeight: 700, color: "var(--qc-muted)" }}>Total Quote Amount</div>
                <div style={{ fontSize: 17, fontWeight: 700, color: "var(--qc-primary)", marginTop: 2 }}>
                  {formatMoney(approvingQuote.totalCost)}
                </div>
              </div>
            </div>

            {/* Recommended Designers List */}
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 10, display: "flex", alignItems: "center", gap: 6 }}>
                <span>✨</span>
                <span>Top Recommended Designers for this Project:</span>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {approvingQuote.recommendedDesigners && approvingQuote.recommendedDesigners.length > 0 ? (
                  approvingQuote.recommendedDesigners.map((rec) => {
                    const isSelected = selectedDesignerId === (rec.userId || String(rec.profileId));
                    return (
                      <div
                        key={rec.profileId || rec.userId}
                        onClick={() => setSelectedDesignerId(rec.userId || String(rec.profileId))}
                        style={{
                          border: isSelected ? "2px solid #C48A36" : "1px solid var(--qc-border)",
                          background: isSelected ? "rgba(196, 138, 54, 0.05)" : "var(--qc-surface)",
                          borderRadius: 10,
                          padding: "12px 14px",
                          cursor: "pointer",
                          transition: "all 0.15s ease",
                        }}
                      >
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
                          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                            <input
                              type="radio"
                              name="recommendedDesigner"
                              checked={isSelected}
                              onChange={() => setSelectedDesignerId(rec.userId || String(rec.profileId))}
                              style={{ cursor: "pointer", accentColor: "#C48A36", width: 16, height: 16 }}
                            />
                            <div>
                              <div style={{ fontWeight: 700, fontSize: 14, color: "var(--qc-ink)" }}>
                                {rec.displayName}
                              </div>
                              {rec.email && (
                                <div style={{ fontSize: 11.5, color: "var(--qc-muted)" }}>{rec.email}</div>
                              )}
                            </div>
                          </div>

                          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                            <span
                              style={{
                                background: "#059669",
                                color: "#ffffff",
                                padding: "2px 8px",
                                borderRadius: 6,
                                fontSize: 11.5,
                                fontWeight: 700,
                              }}
                            >
                              {Math.round(rec.matchScore * 100)}% Match
                            </span>
                            <span style={{ fontSize: 12, fontWeight: 600, color: "#D97706" }}>
                              {rec.averageRating ? `${rec.averageRating.toFixed(1)}★` : "4.9★"}
                            </span>
                          </div>
                        </div>

                        {/* Plain language 4 factors explanation */}
                        <div
                          style={{
                            fontSize: 12,
                            color: "var(--qc-neutral)",
                            background: "var(--qc-surface-sunken)",
                            padding: "6px 10px",
                            borderRadius: 6,
                            marginTop: 6,
                            borderLeft: "3px solid #C48A36",
                          }}
                        >
                          {rec.matchReason || `Compatibility: ${Math.round((rec.styleTagOverlapPct || 0.9) * 100)}% style overlap, verified budget fit, and full active capacity.`}
                        </div>

                        {/* Style tags & price */}
                        {rec.styleTags && rec.styleTags.length > 0 && (
                          <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginTop: 8 }}>
                            {rec.styleTags.map((tag) => (
                              <span key={tag} style={{ fontSize: 10.5, background: "rgba(0,0,0,0.06)", padding: "1px 6px", borderRadius: 4 }}>
                                {tag}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    );
                  })
                ) : (
                  <div style={{ padding: 14, background: "var(--qc-surface-sunken)", borderRadius: 8, fontSize: 13, color: "var(--qc-muted)" }}>
                    No specific shortlist candidates found. Proceed with standard assigned designer.
                  </div>
                )}
              </div>
            </div>

            {/* Modal Action Buttons */}
            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, paddingTop: 12, borderTop: "1px solid var(--qc-border)" }}>
              <button
                type="button"
                className="qc-btn qc-btn--ghost"
                onClick={() => setApprovingQuote(null)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="qc-btn qc-btn--primary"
                onClick={() => handleStage2(approvingQuote, "Approve", selectedDesignerId)}
              >
                ✓ Confirm & Approve Quote
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Quote Inspection Modal */}
      {viewingQuote && (
        <div className="qc-modal-backdrop" onMouseDown={() => setViewingQuote(null)}>
          <div className="qc-modal qc-modal--lg" onMouseDown={(e) => e.stopPropagation()}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 16 }}>
              <div>
                <div className="qc-modal__title" style={{ margin: 0 }}>Quote Inspection</div>
                <div style={{ fontSize: 13, color: "var(--qc-muted)", marginTop: 4 }}>{viewingQuote.scopeSummary}</div>
                {viewingQuote.projectReferenceCode && (
                  <div style={{ fontSize: 11.5, color: "var(--qc-muted)", fontFamily: "monospace", marginTop: 2 }}>
                    Request Code: {viewingQuote.projectReferenceCode}
                  </div>
                )}
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <StatusBadge status={viewingQuote.status} />
                <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => handleExport(viewingQuote, "pdf")}>Export PDF</button>
                <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => setViewingQuote(null)}>Close</button>
              </div>
            </div>

            {/* Project Request Description */}
            {viewingQuote.description && (
              <div style={{ background: "#FAF8F5", border: "1px solid #E7E1D7", borderRadius: 10, padding: 12, marginBottom: 14 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: "var(--qc-muted)", textTransform: "uppercase", marginBottom: 4 }}>
                  Client Project Description
                </div>
                <div style={{ fontSize: 13, color: "var(--qc-ink)" }}>{viewingQuote.description}</div>
              </div>
            )}

            {/* Quotation Engine Breakdown Card */}
            {viewingQuote.currentVersion && (
              <div style={{ background: "#FAF8F5", border: "1px solid #E7E1D7", borderRadius: 10, padding: 14, marginBottom: 16 }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: "#C48A36", marginBottom: 8, textTransform: "uppercase" }}>
                  Engine Calculation Breakdown (v{viewingQuote.currentVersion.versionNumber})
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, fontSize: 13 }}>
                  <div>Materials: <strong>{formatMoney(viewingQuote.currentVersion.materialsSubtotal)}</strong></div>
                  <div>Labor: <strong>{formatMoney(viewingQuote.currentVersion.laborSubtotal)}</strong></div>
                  <div>Design Fee (10%): <strong>{formatMoney(viewingQuote.currentVersion.designFee)}</strong></div>
                  <div>Contingency (5%): <strong>{formatMoney(viewingQuote.currentVersion.contingencyAmount)}</strong></div>
                  <div>Tax / VAT (8%): <strong>{formatMoney(viewingQuote.currentVersion.taxAmount)}</strong></div>
                  <div>Total Cost: <strong style={{ color: "#C48A36", fontSize: 15 }}>{formatMoney(viewingQuote.currentVersion.totalCost)}</strong></div>
                </div>
              </div>
            )}

            <div style={{ fontWeight: 600, fontSize: 13, marginBottom: 8 }}>Itemized Line Items</div>
            <div className="qc-table-responsive" style={{ maxHeight: 240, overflowY: "auto", border: "1px solid #E7E1D7", borderRadius: 8 }}>
              <table className="qc-table">
                <thead>
                  <tr>
                    <th>Description</th>
                    <th>Category</th>
                    <th style={{ textAlign: "center" }}>Qty</th>
                    <th style={{ textAlign: "right" }}>Unit Cost</th>
                    <th style={{ textAlign: "right" }}>Total</th>
                  </tr>
                </thead>
                <tbody>
                  {viewingQuote.items?.map((it, idx) => (
                    <tr key={it.id || idx}>
                      <td>{it.description}</td>
                      <td><span style={{ fontSize: 11, background: "#EFEAE1", padding: "2px 6px", borderRadius: 4 }}>{it.category}</span></td>
                      <td style={{ textAlign: "center" }}>{it.quantity}</td>
                      <td style={{ textAlign: "right" }}>{formatMoney(it.unitCost)}</td>
                      <td style={{ textAlign: "right", fontWeight: 600 }}>{formatMoney((it.quantity || 1) * (it.unitCost || 0))}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginTop: 16 }}>
              <button className="qc-btn qc-btn--primary" onClick={() => setViewingQuote(null)}>Done</button>
            </div>
          </div>
        </div>
      )}

      {/* Quote Version History Modal */}
      {versionHistoryQuote && (
        <div className="qc-modal-backdrop" onMouseDown={() => setVersionHistoryQuote(null)}>
          <div className="qc-modal qc-modal--lg" onMouseDown={(e) => e.stopPropagation()}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
              <div>
                <div className="qc-modal__title" style={{ margin: 0 }}>Quote Version History (Immutable Audit Log)</div>
                <div style={{ fontSize: 12, color: "var(--qc-muted)", marginTop: 4 }}>Quote ID: {versionHistoryQuote.id}</div>
              </div>
              <button className="qc-btn qc-btn--ghost qc-btn--sm" onClick={() => setVersionHistoryQuote(null)}>Close</button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 12, maxHeight: 380, overflowY: "auto" }}>
              {versionHistoryQuote.versions && versionHistoryQuote.versions.length > 0 ? (
                versionHistoryQuote.versions.map((ver) => (
                  <div key={ver.id} style={{ border: "1px solid #E7E1D7", borderRadius: 10, padding: 14, background: "#FAF8F5" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                      <div style={{ fontWeight: 700, fontSize: 14 }}>
                        Version {ver.versionNumber} <span style={{ fontSize: 11, color: "#78716C", fontWeight: 400 }}>by {ver.authorRole}</span>
                      </div>
                      <div style={{ fontSize: 12, color: "var(--qc-muted)" }}>{new Date(ver.createdAt).toLocaleString()}</div>
                    </div>
                    <div style={{ fontSize: 12.5, color: "#57534E", marginBottom: 8 }}>{ver.notes || "No revision notes recorded."}</div>
                    <div style={{ display: "flex", gap: 16, fontSize: 12 }}>
                      <span>Materials: <strong>{formatMoney(ver.materialsSubtotal)}</strong></span>
                      <span>Labor: <strong>{formatMoney(ver.laborSubtotal)}</strong></span>
                      <span>Design Fee: <strong>{formatMoney(ver.designFee)}</strong></span>
                      <span>Total: <strong style={{ color: "#C48A36" }}>{formatMoney(ver.totalCost)}</strong></span>
                      <span>Items: <strong>{ver.items?.length ?? 0}</strong></span>
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ textAlign: "center", color: "var(--qc-muted)", padding: 20 }}>
                  Initial version v1 (Total: {formatMoney(versionHistoryQuote.totalCost)})
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Creation / Revision Modals */}
      {modalOpen && (
        <QuoteFormModal
          onSubmit={handleCreate}
          onClose={() => setModalOpen(false)}
        />
      )}

      {editingQuote && (
        <QuoteFormModal
          initialQuote={editingQuote}
          onSubmit={handleEdit}
          onClose={() => setEditingQuote(null)}
        />
      )}

      {aiModalOpen && (
        <AiDraftModal
          onSubmit={handleAiDraft}
          onClose={() => setAiModalOpen(false)}
        />
      )}
    </div>
  );
}