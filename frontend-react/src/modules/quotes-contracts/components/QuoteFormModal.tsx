import { useState, useEffect, type FormEvent } from "react";
import type { Quote, QuoteItem } from "../types";
import { computeQuotationBreakdown } from "../api/quotesApi";

const CATEGORIES = ["Materials", "Labor", "Design", "Furniture", "Other"];

const emptyItem = (): QuoteItem => ({ description: "", category: "Materials", quantity: 1, unitCost: 0 });

function TrashIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
      <path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2m2 0-1 13a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1L6 7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function PlusIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 5v14M5 12h14" strokeLinecap="round" />
    </svg>
  );
}

export interface QuoteFormPayload {
  scopeSummary: string;
  notes: string;
  items: QuoteItem[];
  projectRequestId?: string;
  designerId?: string;
  isAiGenerated?: boolean;
}

interface QuoteFormModalProps {
  initialQuote?: Quote | null;
  projectRequestId?: string;
  designerId?: string;
  maxBudget?: number;
  onSubmit: (payload: QuoteFormPayload) => Promise<void>;
  onClose: () => void;
}

const normalizeCategory = (cat?: string): string => {
  if (!cat) return "Other";
  const match = CATEGORIES.find((c) => c.toLowerCase() === String(cat).toLowerCase());
  return match ?? "Other";
};

export default function QuoteFormModal({ initialQuote, projectRequestId, designerId, maxBudget = 600000, onSubmit, onClose }: QuoteFormModalProps) {
  const isEdit = Boolean(initialQuote);
  const [scopeSummary, setScopeSummary] = useState(initialQuote?.scopeSummary ?? "");
  const [notes, setNotes] = useState(initialQuote?.notes ?? "");
  const [items, setItems] = useState<QuoteItem[]>(
    initialQuote?.items && initialQuote.items.length > 0
      ? initialQuote.items.map((i) => ({
          id: i.id,
          description: i.description ?? "",
          category: normalizeCategory(i.category),
          quantity: i.quantity ?? 1,
          unitCost: i.unitCost ?? 0,
        }))
      : [emptyItem()]
  );
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialQuote) {
      setScopeSummary(initialQuote.scopeSummary ?? "");
      setNotes(initialQuote.notes ?? "");
      if (initialQuote.items && initialQuote.items.length > 0) {
        setItems(
          initialQuote.items.map((i) => ({
            id: i.id,
            description: i.description ?? "",
            category: normalizeCategory(i.category),
            quantity: i.quantity ?? 1,
            unitCost: i.unitCost ?? 0,
          }))
        );
      }
    }
  }, [initialQuote]);

  const breakdown = computeQuotationBreakdown(items);
  const isOverBudget = maxBudget > 0 && breakdown.totalCost > maxBudget;

  function updateItem(index: number, field: keyof QuoteItem, value: string | number) {
    setItems((prev) => prev.map((item, i) => (i === index ? { ...item, [field]: value } : item)));
  }

  function removeItem(index: number) {
    setItems((prev) => (prev.length > 1 ? prev.filter((_, i) => i !== index) : prev));
  }

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (submitting) return;
    setError(null);

    const activeItems = items.filter((i) => i.description.trim() !== "");
    if (activeItems.length === 0) {
      setError("Add at least one line item with a description.");
      return;
    }

    for (const item of activeItems) {
      const q = Number(item.quantity);
      if (isNaN(q) || q < 1) {
        setError(`Quantity for "${item.description}" must be at least 1.`);
        return;
      }
      const c = Number(item.unitCost);
      if (isNaN(c) || c < 0) {
        setError(`Unit cost for "${item.description}" cannot be negative.`);
        return;
      }
    }

    const cleanItems = activeItems.map((i) => ({
      description: i.description.trim(),
      category: normalizeCategory(i.category),
      quantity: Math.max(1, Math.floor(Number(i.quantity))),
      unitCost: Math.max(0, Number(i.unitCost)),
    }));

    const payload: QuoteFormPayload = isEdit
      ? { scopeSummary, notes, items: cleanItems }
      : { projectRequestId, designerId, scopeSummary, notes, items: cleanItems, isAiGenerated: false };

    setSubmitting(true);
    try {
      await onSubmit(payload);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Budget-guard validation failed.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="qc-modal-backdrop" onMouseDown={onClose}>
      <div className="qc-modal qc-modal--lg" onMouseDown={(e) => e.stopPropagation()}>
        <div className="qc-modal__title">{isEdit ? "Revise Quote (Line-Item Editor)" : "New Quote Proposal"}</div>

        <form onSubmit={handleSubmit}>
          <div className="qc-field">
            <label htmlFor="scopeSummary">Scope summary</label>
            <input
              id="scopeSummary"
              className="qc-input"
              style={{ width: "100%" }}
              value={scopeSummary}
              onChange={(e) => setScopeSummary(e.target.value)}
              placeholder="Wall redesign, lighting upgrade, furniture — modern minimalist"
              required
            />
          </div>

          <div className="qc-field">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
              <label style={{ margin: 0 }}>Line items (Materials &amp; Labor)</label>
              <span style={{ fontSize: 11, color: "var(--qc-muted)" }}>
                Budget Ceiling: <strong>LKR {maxBudget.toLocaleString()}</strong>
              </span>
            </div>
            
            <div className="qc-item-row" style={{ fontSize: 12, color: "var(--qc-muted)", marginBottom: 4 }}>
              <span>Description</span>
              <span>Category</span>
              <span>Qty</span>
              <span>Unit cost (LKR)</span>
              <span />
            </div>
            {items.map((item, index) => (
              <div className="qc-item-row" key={index}>
                <input
                  className="qc-input"
                  value={item.description}
                  onChange={(e) => updateItem(index, "description", e.target.value)}
                  placeholder="e.g. Accent lighting fixtures"
                />
                <select
                  className="qc-select"
                  value={item.category}
                  onChange={(e) => updateItem(index, "category", e.target.value)}
                >
                  {CATEGORIES.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
                <input
                  className="qc-input"
                  type="number"
                  min="1"
                  value={item.quantity}
                  onChange={(e) => updateItem(index, "quantity", e.target.value === "" ? "" : Number(e.target.value))}
                />
                <input
                  className="qc-input"
                  type="number"
                  min="0"
                  step="0.01"
                  value={item.unitCost}
                  onChange={(e) => updateItem(index, "unitCost", e.target.value === "" ? "" : Number(e.target.value))}
                />
                <button type="button" className="qc-icon-btn" onClick={() => removeItem(index)} aria-label="Remove item">
                  <TrashIcon />
                </button>
              </div>
            ))}

            <button
              type="button"
              className="qc-btn qc-btn--ghost"
              style={{ marginTop: 6, display: "inline-flex", alignItems: "center", gap: 6 }}
              onClick={() => setItems((prev) => [...prev, emptyItem()])}
            >
              <PlusIcon /> Add item
            </button>
          </div>

          {/* Quotation Engine Live Computation Summary */}
          <div style={{ background: "rgba(196, 138, 54, 0.06)", border: "1px solid rgba(196, 138, 54, 0.2)", borderRadius: 10, padding: 14, marginTop: 12, marginBottom: 12 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: "#C48A36", marginBottom: 8, textTransform: "uppercase" }}>
              ⚡ Quotation Engine Computed Breakdown
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, fontSize: 12 }}>
              <div>Materials: <strong>LKR {breakdown.materialsSubtotal.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
              <div>Labor: <strong>LKR {breakdown.laborSubtotal.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
              <div>Design Fee (10%): <strong>LKR {breakdown.designFee.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
              <div>Contingency (5%): <strong>LKR {breakdown.contingencyAmount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
              <div>Tax / VAT (8%): <strong>LKR {breakdown.taxAmount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
              <div>Computed Total: <strong style={{ color: isOverBudget ? "var(--qc-danger)" : "#C48A36" }}>LKR {breakdown.totalCost.toLocaleString(undefined, { minimumFractionDigits: 2 })}</strong></div>
            </div>
            {isOverBudget && (
              <div style={{ color: "var(--qc-danger)", fontSize: 12, fontWeight: 600, marginTop: 8 }}>
                ⚠️ Over client maximum budget by LKR {(breakdown.totalCost - maxBudget).toLocaleString(undefined, { minimumFractionDigits: 2 })}
              </div>
            )}
          </div>

          <div className="qc-field">
            <label htmlFor="notes">Notes / Revision details</label>
            <textarea
              id="notes"
              className="qc-input"
              style={{ width: "100%", minHeight: 50, resize: "vertical" }}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Internal notes or specific changes made in this revision..."
            />
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 16 }}>
            <div>
              <span style={{ fontSize: 12, color: "var(--qc-muted)" }}>Total: </span>
              <span className="qc-money" style={{ color: isOverBudget ? "var(--qc-danger)" : "#C48A36" }}>
                LKR {breakdown.totalCost.toLocaleString(undefined, { minimumFractionDigits: 2 })}
              </span>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button type="button" className="qc-btn qc-btn--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
              <button type="submit" className="qc-btn qc-btn--primary" disabled={submitting || isOverBudget}>
                {submitting ? "Validating & Saving…" : isEdit ? "Save as New Version" : "Create Quote"}
              </button>
            </div>
          </div>

          {error && <p style={{ color: "var(--qc-danger)", fontSize: 13, marginTop: 10 }}>{error}</p>}
        </form>
      </div>
    </div>
  );
}