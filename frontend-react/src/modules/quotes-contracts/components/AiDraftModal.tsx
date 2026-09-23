import { useState, type FormEvent } from "react";

const STYLE_OPTIONS = ["Modern", "Minimalist", "Industrial", "Luxury", "Traditional", "Mid Century Modern"];

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
  onSubmit: (payload: AiDraftPayload) => Promise<void>;
  onClose: () => void;
}

export default function AiDraftModal({ onSubmit, onClose }: AiDraftModalProps) {
  const [roomType, setRoomType] = useState("Living room");
  const [roomSizeSqft, setRoomSizeSqft] = useState(200);
  const [budgetMin, setBudgetMin] = useState(150000);
  const [budgetMax, setBudgetMax] = useState(250000);
  const [styleProfile, setStyleProfile] = useState(STYLE_OPTIONS[0]);
  const [preferences, setPreferences] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    try {
      setSubmitting(true);
      await onSubmit({
        projectRequestId: crypto.randomUUID(),
        designerId: crypto.randomUUID(),
        roomType,
        roomSizeSqft: Number(roomSizeSqft),
        budgetMin: Number(budgetMin),
        budgetMax: Number(budgetMax),
        styleProfile,
        styleConfidence: 0.85,
        preferences: preferences || null,
      });
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "The AI service didn't respond. Is it running on port 8001?"
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="qc-modal-backdrop" onMouseDown={onClose}>
      <div className="qc-modal" onMouseDown={(e) => e.stopPropagation()}>
        <div className="qc-modal__title">Generate a draft quote with AI</div>

        <form onSubmit={handleSubmit}>
          <div className="qc-field">
            <label htmlFor="roomType">Room type</label>
            <input id="roomType" className="qc-input" style={{ width: "100%" }}
              value={roomType} onChange={(e) => setRoomType(e.target.value)} />
          </div>

          <div className="qc-field" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            <div>
              <label htmlFor="roomSize">Room size (sq ft)</label>
              <input id="roomSize" className="qc-input" type="number" style={{ width: "100%" }}
                value={roomSizeSqft} onChange={(e) => setRoomSizeSqft(Number(e.target.value))} />
            </div>
            <div>
              <label htmlFor="style">Detected style</label>
              <select id="style" className="qc-select" style={{ width: "100%" }}
                value={styleProfile} onChange={(e) => setStyleProfile(e.target.value)}>
                {STYLE_OPTIONS.map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
          </div>

          <div className="qc-field" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            <div>
              <label htmlFor="budgetMin">Budget min (LKR)</label>
              <input id="budgetMin" className="qc-input" type="number" style={{ width: "100%" }}
                value={budgetMin} onChange={(e) => setBudgetMin(Number(e.target.value))} />
            </div>
            <div>
              <label htmlFor="budgetMax">Budget max (LKR)</label>
              <input id="budgetMax" className="qc-input" type="number" style={{ width: "100%" }}
                value={budgetMax} onChange={(e) => setBudgetMax(Number(e.target.value))} />
            </div>
          </div>

          <div className="qc-field">
            <label htmlFor="preferences">Client preferences (optional)</label>
            <input id="preferences" className="qc-input" style={{ width: "100%" }}
              placeholder="e.g. warm neutral tones, low-profile furniture"
              value={preferences} onChange={(e) => setPreferences(e.target.value)} />
          </div>

          <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginTop: 20 }}>
            <button type="button" className="qc-btn qc-btn--ghost" onClick={onClose}>Cancel</button>
            <button type="submit" className="qc-btn qc-btn--primary" disabled={submitting}>
              {submitting ? "Generating…" : "Generate draft"}
            </button>
          </div>

          {error && <p style={{ color: "var(--qc-danger)", fontSize: 13, marginTop: 10 }}>{error}</p>}
        </form>
      </div>
    </div>
  );
}