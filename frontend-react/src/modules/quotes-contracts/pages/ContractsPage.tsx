import { useEffect, useState } from "react";
import { listContracts, signContract, cancelContract } from "../api/contractsApi";
import StatusBadge from "../components/StatusBadge";
import type { Contract } from "../types";
import "../styles/theme.css";

const STATUS_OPTIONS = ["Draft", "PendingSignature", "Active", "Completed", "Cancelled"];
const PAGE_SIZE = 10;

function formatMoney(value: number | undefined) {
  const num = Number(value);
  if (isNaN(num)) return "LKR 0.00";
  return `LKR ${num.toLocaleString(undefined, { minimumFractionDigits: 2 })}`;
}

export default function ContractsPage() {
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const result = await listContracts({ status: statusFilter || undefined, page, pageSize: PAGE_SIZE });
      setContracts(result?.items || []);
      setTotalCount(result?.totalCount || 0);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't load contracts.");
      setContracts([]);
      setTotalCount(0);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, statusFilter]);

  async function handleSign(contract: Contract) {
    if (!contract?.id) return;
    await signContract(contract.id, new Date().toISOString());
    refresh();
  }

  async function handleCancel(contract: Contract) {
    if (!contract?.id) return;
    if (!window.confirm("Cancel this contract? It will be kept for the record but marked Cancelled.")) return;
    await cancelContract(contract.id);
    refresh();
  }

  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  return (
    <div className="qc-page">
      <div className="qc-page__header">
        <div>
          <div className="qc-page__title">Contracts</div>
          <div className="qc-page__subtitle">Created automatically once a quote is accepted — never deleted, only cancelled.</div>
        </div>
      </div>

      <div className="qc-toolbar">
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
              <th>Contract</th>
              <th>Status</th>
              <th>Amount</th>
              <th>Signed</th>
              <th>Updated</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan={6} className="qc-table-empty">Loading contracts…</td></tr>
            )}
            {!loading && error && (
              <tr><td colSpan={6} className="qc-table-empty" style={{ color: "var(--qc-danger)" }}>{error}</td></tr>
            )}
            {!loading && !error && (!contracts || contracts.length === 0) && (
              <tr><td colSpan={6} className="qc-table-empty">No contracts yet. Accept a quote to create one.</td></tr>
            )}
            {!loading && !error && contracts?.map((c) => (
              <tr key={c.id}>
                <td>
                  <div style={{ fontWeight: 500 }}>{c.termsSummary || "Interior Design Agreement"}</div>
                  <div style={{ fontFamily: "monospace", fontSize: 11.5, color: "var(--qc-muted)" }}>
                    {c.id ? `${c.id.slice(0, 8)}…` : "—"}
                  </div>
                </td>
                <td><StatusBadge status={c.status} /></td>
                <td className="qc-money">{formatMoney(c.totalAmount)}</td>
                <td style={{ color: "var(--qc-muted)", fontSize: 12.5 }}>
                  {c.signedAt ? new Date(c.signedAt).toLocaleDateString() : "—"}
                </td>
                <td style={{ color: "var(--qc-muted)", fontSize: 12.5 }}>
                  {c.updatedAt ? new Date(c.updatedAt).toLocaleDateString() : "—"}
                </td>
                <td>
                  <div style={{ display: "flex", gap: 6, justifyContent: "flex-end" }}>
                    {(c.status === "Draft" || c.status === "PendingSignature") && (
                      <button className="qc-btn qc-btn--primary" onClick={() => handleSign(c)}>Mark signed</button>
                    )}
                    {c.status !== "Completed" && c.status !== "Cancelled" && (
                      <button className="qc-btn qc-btn--danger" onClick={() => handleCancel(c)}>Cancel</button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="qc-pagination">
          <span>{totalCount} contract{totalCount === 1 ? "" : "s"}</span>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <button className="qc-btn qc-btn--ghost" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>Previous</button>
            <span>Page {page} of {totalPages}</span>
            <button className="qc-btn qc-btn--ghost" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
          </div>
        </div>
      </div>
    </div>
  );
}