import { useEffect, useState } from "react";
import { listQuotes, createQuote, updateQuote, updateQuoteStatus, acceptQuote, deleteQuote, draftQuoteFromAgent } from "../api/quotesApi";
import StatusBadge from "../components/StatusBadge";
import QuoteFormModal, { type QuoteFormPayload } from "../components/QuoteFormModal";
import AiDraftModal, { type AiDraftPayload } from "../components/AiDraftModal";
import type { Quote } from "../types";
import "../styles/theme.css";

const STATUS_OPTIONS = ["Draft", "Submitted", "ClientReview", "RevisionRequested", "Accepted", "Rejected"];
const PAGE_SIZE = 10;

function formatMoney(value: number | undefined) {
  const num = Number(value);
  if (isNaN(num)) return "LKR 0.00";
  return `LKR ${num.toLocaleString(undefined, { minimumFractionDigits: 2 })}`;
}

function getStatusStr(s: any): string {
  if (!s) return "";
  return typeof s === "string" ? s : s.value ?? s.name ?? "";
}

interface QuotesPageProps {
  onGoToContracts?: () => void;
}

export default function QuotesPage({ onGoToContracts }: QuotesPageProps = {}) {
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingQuote, setEditingQuote] = useState<Quote | null>(null);
  const [aiModalOpen, setAiModalOpen] = useState(false);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const result = await listQuotes({ status: statusFilter || undefined, search: search || undefined, page, pageSize: PAGE_SIZE });
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
      designerId: payload.designerId ?? crypto.randomUUID(),
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

  async function handleAdvance(quote: Quote) {
    if (!quote?.id) return;
    const transitions: Record<string, string> = {
      Draft: "Submitted",
      Submitted: "ClientReview",
    };
    const status = quote?.status ? (typeof quote.status === "string" ? quote.status : quote.status.value ?? quote.status.name ?? "") : "";
    const next = transitions[status];
    if (!next) return;
    await updateQuoteStatus(quote.id, next);
    refresh();
  }

  async function handleAccept(quote: Quote) {
    if (!quote?.id) return;
    try {
      await acceptQuote(quote.id);
      await refresh();
      if (onGoToContracts) {
        onGoToContracts();
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to accept quote.");
    }
  }

  async function handleReject(quote: Quote) {
    if (!quote?.id) return;
    await updateQuoteStatus(quote.id, "Rejected");
    refresh();
  }

  async function handleDelete(quote: Quote) {
    if (!quote?.id) return;
    if (!window.confirm("Delete this draft quote? This can't be undone.")) return;
    await deleteQuote(quote.id);
    refresh();
  }

  async function handleAiDraft(payload: AiDraftPayload) {
    await draftQuoteFromAgent(payload);
    setAiModalOpen(false);
    refresh();
  }

  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <div className="qc-page">
      <div className="qc-page__header">
        <div>
          <div className="qc-page__title">Quotes</div>
          <div className="qc-page__subtitle">Draft, review, and turn accepted quotes into contracts.</div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="qc-btn qc-btn--ghost" onClick={() => setAiModalOpen(true)}>Generate with AI</button>
          <button className="qc-btn qc-btn--primary" onClick={() => setModalOpen(true)}>New quote</button>
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
        <table className="qc-table">
          <thead>
            <tr>
              <th>Scope</th>
              <th>Status</th>
              <th>Items</th>
              <th>Total</th>
              <th>Updated</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan={6} className="qc-table-empty">Loading quotes…</td></tr>
            )}
            {!loading && error && (
              <tr><td colSpan={6} className="qc-table-empty" style={{ color: "var(--qc-danger)" }}>{error}</td></tr>
            )}
            {!loading && !error && (!quotes || quotes.length === 0) && (
              <tr><td colSpan={6} className="qc-table-empty">No quotes yet. Create one to get started.</td></tr>
            )}
            {!loading && !error && quotes?.map((q) => {
              const statusStr = getStatusStr(q.status);
              return (
                <tr key={q.id}>
                  <td>
                    <div style={{ fontWeight: 500 }}>{q.scopeSummary || "Untitled scope"}</div>
                    {q.isAiGenerated && (
                      <div style={{ fontSize: 11.5, color: "var(--qc-muted)" }}>AI-drafted, not yet revised</div>
                    )}
                  </td>
                  <td><StatusBadge status={q.status} /></td>
                  <td>{q.items?.length ?? 0}</td>
                  <td className="qc-money">{formatMoney(q.totalCost)}</td>
                  <td style={{ color: "var(--qc-muted)", fontSize: 12.5 }}>
                    {q.updatedAt ? new Date(q.updatedAt).toLocaleDateString() : "—"}
                  </td>
                  <td>
                    <div style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                      {(statusStr === "Draft" || statusStr === "RevisionRequested") && (
                        <button className="qc-btn qc-btn--ghost" onClick={() => setEditingQuote(q)}>Edit</button>
                      )}
                      {statusStr === "Draft" && (
                        <button className="qc-btn qc-btn--ghost" onClick={() => handleAdvance(q)}>Submit</button>
                      )}
                      {(statusStr === "Submitted" || statusStr === "ClientReview") && (
                        <>
                          <button className="qc-btn qc-btn--primary" onClick={() => handleAccept(q)}>Accept</button>
                          <button className="qc-btn qc-btn--danger" onClick={() => handleDelete(q)}>Delete</button>
                        </>
                      )}
                      {statusStr === "Accepted" && onGoToContracts && (
                        <button className="qc-btn qc-btn--ghost" onClick={onGoToContracts}>View Contract</button>
                      )}
                      {statusStr === "Draft" && (
                        <button className="qc-btn qc-btn--danger" onClick={() => handleDelete(q)}>Delete</button>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        <div className="qc-pagination">
          <span>{totalCount} quote{totalCount === 1 ? "" : "s"}</span>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <button className="qc-btn qc-btn--ghost" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
            <span>Page {page} of {totalPages}</span>
            <button className="qc-btn qc-btn--ghost" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
          </div>
        </div>
      </div>

      {modalOpen && (
        <QuoteFormModal onSubmit={handleCreate} onClose={() => setModalOpen(false)} />
      )}
      {editingQuote && (
        <QuoteFormModal
          key={`${editingQuote.id}-${editingQuote.updatedAt || ""}`}
          initialQuote={editingQuote}
          onSubmit={handleEdit}
          onClose={() => setEditingQuote(null)}
        />
      )}
      {aiModalOpen && (
        <AiDraftModal onSubmit={handleAiDraft} onClose={() => setAiModalOpen(false)} />
      )}
    </div>
  );
}