import { useState, type FormEvent } from "react";
import { previewQuoteFromAgent } from "../api/quotesApi";
import type { AgentBudgetScopeResponse, QuoteItem } from "../types";

export const STYLE_OPTIONS = [
  "Modern",
  "Minimalist",
  "Industrial",
  "Luxury",
  "Traditional",
  "Mid Century Modern",
];

const ROOM_PRESETS = [
  "Bedroom",
  "Living room",
  "Master bedroom",
  "Kitchen",
  "Dining room",
  "Home office",
  "Bathroom",
];

const BUDGET_PRESETS = [
  { label: "150k – 250k", min: 150000, max: 250000 },
  { label: "250k – 500k", min: 250000, max: 500000 },
  { label: "500k – 1.0M", min: 500000, max: 1000000 },
  { label: "1.0M – 2.5M", min: 1000000, max: 2500000 },
];

const PREFERENCE_CHIPS = [
  "Warm recessed lighting",
  "Low-profile oak furniture",
  "Custom built-in storage",
  "Natural textures & linen",
  "Matte black accents",
  "Luxury marble countertops",
];

const CATEGORIES = ["Design", "Labor", "Materials", "Furniture", "Other"];

export interface AiDraftPayload {
  projectRequestId: string;
  designerId: string;
  roomType: string;
  roomSizeSqft: number;
  budgetMin: number;
  budgetMax: number;
  styleProfile: string;
  styleConfidence: number;
  preferences: string | null;
}

interface AiDraftModalProps {
  onSubmit: (
    payload: AiDraftPayload,
    finalQuote?: { scopeSummary: string; notes: string; items: QuoteItem[] }
  ) => Promise<void>;
  onClose: () => void;
}

export default function AiDraftModal({ onSubmit, onClose }: AiDraftModalProps) {
  // Step 1: Input state (PRD Section 8 Budget/Scope Agent inputs)
  const [roomType, setRoomType] = useState("Bedroom");
  const [roomSizeSqft, setRoomSizeSqft] = useState(200);
  const [budgetMin, setBudgetMin] = useState(150000);
  const [budgetMax, setBudgetMax] = useState(250000);
  const [styleProfile, setStyleProfile] = useState(STYLE_OPTIONS[0]);
  const [preferences, setPreferences] = useState("");

  // Step 2: Preview state
  const [currentStep, setCurrentStep] = useState<"configure" | "preview">("configure");
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Draft Data state
  const [draftScope, setDraftScope] = useState("");
  const [draftNotes, setDraftNotes] = useState("");
  const [draftSource, setDraftSource] = useState("llm");
  const [draftItems, setDraftItems] = useState<QuoteItem[]>([]);

  // Helpers
  function formatMoney(value: number) {
    return `LKR ${Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  }

  function handleAddPref(chip: string) {
    setPreferences((prev) => (prev ? `${prev}, ${chip}` : chip));
  }

  // Trigger direct Draft via backend POST /api/quotes/draft-from-agent
  async function handleDirectDraft() {
    setError(null);
    setSubmitting(true);

    const payload: AiDraftPayload = {
      projectRequestId: crypto.randomUUID(),
      designerId: crypto.randomUUID(),
      roomType,
      roomSizeSqft: Number(roomSizeSqft) || 200,
      budgetMin: Number(budgetMin) || 0,
      budgetMax: Number(budgetMax) || 0,
      styleProfile,
      styleConfidence: 0.88,
      preferences: preferences.trim() || null,
    };

    try {
      await onSubmit(payload);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to draft quote with AI.");
    } finally {
      setSubmitting(false);
    }
  }

  // Trigger AI Preview call via backend POST /api/quotes/draft-preview
  async function handleGeneratePreview(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoadingPreview(true);

    const payload: AiDraftPayload = {
      projectRequestId: crypto.randomUUID(),
      designerId: crypto.randomUUID(),
      roomType,
      roomSizeSqft: Number(roomSizeSqft) || 200,
      budgetMin: Number(budgetMin) || 0,
      budgetMax: Number(budgetMax) || 0,
      styleProfile,
      styleConfidence: 0.88,
      preferences: preferences.trim() || null,
    };

    try {
      const result: AgentBudgetScopeResponse = await previewQuoteFromAgent(payload);
      const scopeText = result.scopeSummary || result.scope_summary || `${styleProfile} ${roomType} Redesign`;
      const notesText = result.notes || "";
      const sourceText = result.source || "llm";

      const formattedItems: QuoteItem[] = (result.items || []).map((i: any, idx) => {
        const uCost = Number(i.unitCost ?? i.unit_cost ?? 0);
        const qty = Number(i.quantity ?? 1);
        return {
          id: `ai-item-${idx}-${Date.now()}`,
          description: i.description,
          category: i.category || "Other",
          quantity: qty,
          unitCost: uCost,
          totalCost: qty * uCost,
        };
      });

      setDraftScope(scopeText);
      setDraftNotes(notesText);
      setDraftSource(sourceText);
      setDraftItems(formattedItems);
      setCurrentStep("preview");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate preview from AI agent.");
    } finally {
      setLoadingPreview(false);
    }
  }

  // Item modifications in preview
  function handleItemChange(index: number, field: keyof QuoteItem, value: any) {
    const updated = [...draftItems];
    const item = { ...updated[index], [field]: value };
    if (field === "quantity" || field === "unitCost") {
      item.totalCost = Number(item.quantity || 0) * Number(item.unitCost || 0);
    }
    updated[index] = item;
    setDraftItems(updated);
  }

  function handleAddItem() {
    setDraftItems([
      ...draftItems,
      {
        id: `custom-item-${Date.now()}`,
        description: "",
        category: "Other",
        quantity: 1,
        unitCost: 0,
        totalCost: 0,
      },
    ]);
  }

  function handleRemoveItem(index: number) {
    if (draftItems.length <= 1) return;
    setDraftItems(draftItems.filter((_, i) => i !== index));
  }

  const liveTotal = draftItems.reduce((sum, it) => sum + (Number(it.unitCost) * Number(it.quantity) || 0), 0);
  const isWithinBudget = budgetMax > 0 ? liveTotal >= budgetMin && liveTotal <= budgetMax : true;

  // Final confirmation to commit quote to database
  async function handleFinalSave() {
    setError(null);
    setSubmitting(true);
    try {
      const payload: AiDraftPayload = {
        projectRequestId: crypto.randomUUID(),
        designerId: crypto.randomUUID(),
        roomType,
        roomSizeSqft: Number(roomSizeSqft),
        budgetMin: Number(budgetMin),
        budgetMax: Number(budgetMax),
        styleProfile,
        styleConfidence: 0.88,
        preferences: preferences.trim() || null,
      };

      await onSubmit(payload, {
        scopeSummary: draftScope,
        notes: `${draftNotes} (agent source: ${draftSource})`,
        items: draftItems,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save AI drafted quote.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="qc-modal-backdrop" onMouseDown={onClose}>
      <div
        className={`qc-modal ${currentStep === "preview" ? "qc-modal--lg" : ""}`}
        onMouseDown={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 16 }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
              <div className="qc-modal__title" style={{ margin: 0 }}>
                Budget &amp; Scope AI Agent
              </div>
              <span className="qc-ai-tag">✨ Student 3 Agent</span>
            </div>
            <div style={{ fontSize: 13, color: "var(--qc-muted)" }}>
              {currentStep === "configure"
                ? "Configure room details and client budget to draft an itemized scope and cost breakdown."
                : "Review and refine the draft generated by Claude / rule-based pipeline."}
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="qc-icon-btn"
            style={{ fontSize: 18, lineHeight: 1 }}
            title="Close"
          >
            ✕
          </button>
        </div>

        {/* STEP 1: CONFIGURE */}
        {currentStep === "configure" && (
          <form onSubmit={handleGeneratePreview}>
            {/* Room Type */}
            <div className="qc-field">
              <label htmlFor="roomType">Room Type</label>
              <input
                id="roomType"
                className="qc-input"
                style={{ width: "100%" }}
                value={roomType}
                onChange={(e) => setRoomType(e.target.value)}
                placeholder="e.g. Master Suite, Living Room, Open Kitchen"
                required
              />
              <div className="qc-chip-group">
                {ROOM_PRESETS.map((p) => (
                  <span
                    key={p}
                    className={`qc-chip ${roomType.toLowerCase() === p.toLowerCase() ? "qc-chip--active" : ""}`}
                    onClick={() => setRoomType(p)}
                  >
                    {p}
                  </span>
                ))}
              </div>
            </div>

            {/* Room Size & Style Profile */}
            <div className="qc-field" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              <div>
                <label htmlFor="roomSize">Room Size (sq ft)</label>
                <input
                  id="roomSize"
                  className="qc-input"
                  type="number"
                  min="20"
                  max="10000"
                  style={{ width: "100%" }}
                  value={roomSizeSqft}
                  onChange={(e) => setRoomSizeSqft(Number(e.target.value))}
                  required
                />
              </div>

              <div>
                <label htmlFor="style">Detected Design Style (Student 2 Input)</label>
                <select
                  id="style"
                  className="qc-select"
                  style={{ width: "100%" }}
                  value={styleProfile}
                  onChange={(e) => setStyleProfile(e.target.value)}
                >
                  {STYLE_OPTIONS.map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Budget Min and Max */}
            <div className="qc-field" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
              <div>
                <label htmlFor="budgetMin">Budget Min (LKR)</label>
                <input
                  id="budgetMin"
                  className="qc-input"
                  type="number"
                  step="1000"
                  style={{ width: "100%" }}
                  value={budgetMin}
                  onChange={(e) => setBudgetMin(Number(e.target.value))}
                  required
                />
              </div>

              <div>
                <label htmlFor="budgetMax">Budget Max (LKR)</label>
                <input
                  id="budgetMax"
                  className="qc-input"
                  type="number"
                  step="1000"
                  style={{ width: "100%" }}
                  value={budgetMax}
                  onChange={(e) => setBudgetMax(Number(e.target.value))}
                  required
                />
              </div>
            </div>

            {/* Quick Budget Presets */}
            <div className="qc-field" style={{ marginTop: -8 }}>
              <span style={{ fontSize: 11.5, color: "var(--qc-muted)", fontWeight: 500 }}>Quick Budget Presets:</span>
              <div className="qc-chip-group">
                {BUDGET_PRESETS.map((bp) => (
                  <span
                    key={bp.label}
                    className={`qc-chip ${budgetMin === bp.min && budgetMax === bp.max ? "qc-chip--active" : ""}`}
                    onClick={() => {
                      setBudgetMin(bp.min);
                      setBudgetMax(bp.max);
                    }}
                  >
                    {bp.label}
                  </span>
                ))}
              </div>
            </div>

            {/* Client Preferences */}
            <div className="qc-field">
              <label htmlFor="preferences">Client Preferences &amp; Special Requirements (optional)</label>
              <textarea
                id="preferences"
                className="qc-input"
                rows={2}
                style={{ width: "100%", resize: "vertical" }}
                placeholder="e.g. warm neutral tones, low-profile oak furniture, acoustic wall panelling"
                value={preferences}
                onChange={(e) => setPreferences(e.target.value)}
              />
              <div className="qc-chip-group">
                {PREFERENCE_CHIPS.map((chip) => (
                  <span key={chip} className="qc-chip" onClick={() => handleAddPref(chip)}>
                    + {chip}
                  </span>
                ))}
              </div>
            </div>

            {/* Modal Actions */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 24 }}>
              <button type="button" className="qc-btn qc-btn--ghost" onClick={onClose}>
                Cancel
              </button>
              <div style={{ display: "flex", gap: 10 }}>
                <button
                  type="submit"
                  className="qc-btn qc-btn--ghost"
                  disabled={loadingPreview || submitting}
                  title="Preview scope summary and itemized cost breakdown before saving"
                >
                  {loadingPreview ? (
                    <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span className="qc-spinner" /> Consulting Agent…
                    </span>
                  ) : (
                    "Preview Draft 👁️"
                  )}
                </button>
                <button
                  type="button"
                  className="qc-btn"
                  style={{
                    background: "linear-gradient(135deg, #C48A36 0%, #D97706 100%)",
                    color: "#ffffff",
                    border: "none",
                    fontWeight: 600,
                    boxShadow: "0 2px 8px rgba(196, 138, 54, 0.35)"
                  }}
                  disabled={loadingPreview || submitting}
                  onClick={handleDirectDraft}
                >
                  {submitting ? (
                    <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span className="qc-spinner" /> Drafting with AI…
                    </span>
                  ) : (
                    "Draft Quote with AI ✨"
                  )}
                </button>
              </div>
            </div>

            {error && <p style={{ color: "var(--qc-danger)", fontSize: 13, marginTop: 12 }}>{error}</p>}
          </form>
        )}

        {/* STEP 2: PREVIEW & REFINE */}
        {currentStep === "preview" && (
          <div>
            {/* Overview Card */}
            <div className="qc-preview-card">
              <div className="qc-preview-header">
                <div>
                  <div style={{ fontSize: 11, fontWeight: 700, textTransform: "uppercase", color: "var(--qc-primary)", letterSpacing: "0.05em" }}>
                    Scope of Work Draft
                  </div>
                  <input
                    className="qc-input"
                    style={{ fontSize: 15, fontWeight: 600, width: "100%", marginTop: 4 }}
                    value={draftScope}
                    onChange={(e) => setDraftScope(e.target.value)}
                    title="Click to edit scope summary"
                  />
                </div>
                <div style={{ textAlign: "right", minWidth: 160 }}>
                  <div style={{ fontSize: 11, fontWeight: 600, color: "var(--qc-muted)", textTransform: "uppercase" }}>
                    Estimated Total
                  </div>
                  <div style={{ fontSize: 20, fontWeight: 700, color: "var(--qc-ink)", marginTop: 2 }}>
                    {formatMoney(liveTotal)}
                  </div>
                </div>
              </div>

              {/* Status Badges */}
              <div style={{ display: "flex", flexWrap: "wrap", gap: 8, alignItems: "center", marginTop: 8 }}>
                <span className={`qc-badge-pill ${isWithinBudget ? "qc-badge-pill--success" : "qc-badge-pill--warning"}`}>
                  {isWithinBudget ? "✓ Within Client Budget" : "⚠ Exceeds Budget Range"}
                </span>

                <span className="qc-badge-pill qc-badge-pill--info">
                  Engine: {draftSource === "llm" ? "Claude (LLM Mode)" : "Deterministic Math Fallback (10% Design / 30% Labor / 35% Materials / 25% Furniture)"}
                </span>

                <span style={{ fontSize: 12, color: "var(--qc-muted)" }}>
                  Budget Target: {formatMoney(budgetMin)} – {formatMoney(budgetMax)}
                </span>
              </div>

              {/* Agent Notes */}
              {draftNotes && (
                <div style={{ marginTop: 12, padding: "8px 12px", background: "var(--qc-primary-light)", borderRadius: 6, fontSize: 12.5, color: "var(--qc-ink)", borderLeft: "3px solid var(--qc-primary)" }}>
                  <strong>Agent Rationale:</strong> {draftNotes}
                </div>
              )}
            </div>

            {/* Line Items Table */}
            <div style={{ marginBottom: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: "var(--qc-ink)" }}>
                  Categorized Line Items ({draftItems.length})
                </span>
                <button type="button" className="qc-btn qc-btn--ghost" onClick={handleAddItem} style={{ fontSize: 12, padding: "4px 8px" }}>
                  + Add Item
                </button>
              </div>

              <div style={{ maxHeight: 240, overflowY: "auto", border: "1px solid var(--qc-border)", borderRadius: 8, padding: 8 }}>
                {draftItems.map((item, idx) => (
                  <div key={item.id || idx} className="qc-item-row">
                    <input
                      className="qc-input"
                      placeholder="Item description"
                      value={item.description}
                      onChange={(e) => handleItemChange(idx, "description", e.target.value)}
                    />

                    <select
                      className="qc-select"
                      value={item.category}
                      onChange={(e) => handleItemChange(idx, "category", e.target.value)}
                    >
                      {CATEGORIES.map((c) => (
                        <option key={c} value={c}>
                          {c}
                        </option>
                      ))}
                    </select>

                    <input
                      className="qc-input"
                      type="number"
                      min="1"
                      placeholder="Qty"
                      value={item.quantity}
                      onChange={(e) => handleItemChange(idx, "quantity", Number(e.target.value))}
                    />

                    <input
                      className="qc-input"
                      type="number"
                      min="0"
                      step="100"
                      placeholder="Unit cost"
                      value={item.unitCost}
                      onChange={(e) => handleItemChange(idx, "unitCost", Number(e.target.value))}
                    />

                    <button
                      type="button"
                      className="qc-icon-btn"
                      onClick={() => handleRemoveItem(idx)}
                      title="Remove item"
                    >
                      ✕
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Preview Footer Actions */}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 20 }}>
              <button
                type="button"
                className="qc-btn qc-btn--ghost"
                onClick={() => setCurrentStep("configure")}
              >
                ← Back to Parameters
              </button>

              <div style={{ display: "flex", gap: 10 }}>
                <button type="button" className="qc-btn qc-btn--ghost" onClick={onClose}>
                  Cancel
                </button>
                <button
                  type="button"
                  className="qc-btn qc-btn--primary"
                  onClick={handleFinalSave}
                  disabled={submitting}
                >
                  {submitting ? (
                    <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <span className="qc-spinner" />
                      Saving Quote…
                    </span>
                  ) : (
                    "Save as Draft Quote ✨ (Draft OK)"
                  )}
                </button>
              </div>
            </div>

            {error && <p style={{ color: "var(--qc-danger)", fontSize: 13, marginTop: 12 }}>{error}</p>}
          </div>
        )}
      </div>
    </div>
  );
}