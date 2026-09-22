import { useState } from 'react';
import { createProjectRequest } from '../services/api';
import type { ProjectRequest } from '../services/api';
import { Sparkles, Image, ArrowRight, Save, Send } from 'lucide-react';

// ─── Types ────────────────────────────────────────────────────────────────

interface WizardFormData {
  roomType: string;
  lengthFeet: number | string;
  widthFeet: number | string;
  heightFeet: number | string;
  budgetLkr: number | string;
  preferredStyles: string[];
  description: string;
  photoUrls: string[];
}

interface CreateRequestWizardProps {
  onRequestCreated: (req: ProjectRequest) => void;
}

// ─── Constants ────────────────────────────────────────────────────────────

const SUPPORTED_STYLES: string[] = [
  'Modern',
  'Minimalist',
  'Industrial',
  'Luxury',
  'Traditional',
  'Mid Century Modern',
];

// ─── Component ────────────────────────────────────────────────────────────

export default function CreateRequestWizard({ onRequestCreated }: CreateRequestWizardProps) {
  const [step, setStep] = useState<number>(1);
  const [loading, setLoading] = useState<boolean>(false);

  const [formData, setFormData] = useState<WizardFormData>({
    roomType: 'Bedroom',
    lengthFeet: 15,
    widthFeet: 12,
    heightFeet: 10,
    budgetLkr: 250000,
    preferredStyles: ['Industrial'],
    description: 'Exposed brick wall with raw timber beams and steel frames.',
    photoUrls: [
      'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop',
    ],
  });

  const [newPhotoUrl, setNewPhotoUrl] = useState<string>('');

  const addPhotoUrl = (): void => {
    if (newPhotoUrl.trim()) {
      setFormData((prev) => ({
        ...prev,
        photoUrls: [...prev.photoUrls, newPhotoUrl.trim()],
      }));
      setNewPhotoUrl('');
    }
  };

  const removePhotoUrl = (index: number): void => {
    setFormData((prev) => ({
      ...prev,
      photoUrls: prev.photoUrls.filter((_, i) => i !== index),
    }));
  };

  const toggleStyle = (style: string): void => {
    setFormData((prev) => {
      const exists = prev.preferredStyles.includes(style);
      const updated = exists
        ? prev.preferredStyles.filter((s) => s !== style)
        : [...prev.preferredStyles, style];
      return { ...prev, preferredStyles: updated };
    });
  };

  const handleCreate = async (submitImmediately: boolean): Promise<void> => {
    setLoading(true);
    try {
      const newReq = await createProjectRequest({
        roomType: formData.roomType,
        lengthFeet: Number(formData.lengthFeet),
        widthFeet: Number(formData.widthFeet),
        heightFeet: Number(formData.heightFeet),
        budgetLkr: Number(formData.budgetLkr),
        preferredStyles: formData.preferredStyles,
        description: formData.description,
        photoUrls: formData.photoUrls,
        submitImmediately,
      });
      onRequestCreated(newReq);
    } catch (err) {
      alert('Error creating request: ' + (err instanceof Error ? err.message : String(err)));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass-panel" style={{ padding: '32px', maxWidth: '750px', margin: '0 auto' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
        <Sparkles style={{ color: '#f59e0b', width: '28px', height: '28px' }} />
        <div>
          <h2 style={{ fontSize: '1.4rem', fontWeight: '800' }}>New Room Makeover Request</h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.88rem' }}>
            Submit room specs &amp; photos to kick off Style Analysis AI Agent 🤖
          </p>
        </div>
      </div>

      {/* Progress Steps Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '32px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '16px' }}>
        {([1, 2, 3] as const).map((num) => (
          <div
            key={num}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: step >= num ? 'var(--primary)' : 'var(--text-muted)',
              fontWeight: step >= num ? '700' : '500',
            }}
          >
            <span
              style={{
                width: '28px',
                height: '28px',
                borderRadius: '50%',
                background: step >= num ? 'var(--primary)' : 'rgba(255,255,255,0.1)',
                color: 'white',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '0.85rem',
              }}
            >
              {num}
            </span>
            {num === 1 ? 'Room Specs 📏' : num === 2 ? 'Budget & Style 💰' : 'Photos & Action 📸'}
          </div>
        ))}
      </div>

      <div>
        {step === 1 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', fontWeight: '600' }}>
                Room Type 🛏️
              </label>
              <select
                className="input-field"
                value={formData.roomType}
                onChange={(e) => setFormData({ ...formData, roomType: e.target.value })}
              >
                <option value="Bedroom">Bedroom 🛏️</option>
                <option value="Living Room">Living Room 🛋️</option>
                <option value="Kitchen">Kitchen 🍳</option>
                <option value="Dining Room">Dining Room 🍽️</option>
                <option value="Home Office">Home Office 💼</option>
              </select>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.85rem' }}>Length (ft)</label>
                <input
                  type="number"
                  className="input-field"
                  value={formData.lengthFeet}
                  onChange={(e) => setFormData({ ...formData, lengthFeet: e.target.value })}
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.85rem' }}>Width (ft)</label>
                <input
                  type="number"
                  className="input-field"
                  value={formData.widthFeet}
                  onChange={(e) => setFormData({ ...formData, widthFeet: e.target.value })}
                />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.85rem' }}>Height (ft)</label>
                <input
                  type="number"
                  className="input-field"
                  value={formData.heightFeet}
                  onChange={(e) => setFormData({ ...formData, heightFeet: e.target.value })}
                />
              </div>
            </div>

            <button
              type="button"
              className="btn-primary"
              onClick={() => setStep(2)}
              style={{ alignSelf: 'flex-end', marginTop: '12px' }}
            >
              Next: Budget &amp; Style <ArrowRight size={16} />
            </button>
          </div>
        )}

        {step === 2 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', fontWeight: '600' }}>
                Maximum Budget (LKR) 💰
              </label>
              <input
                type="number"
                className="input-field"
                value={formData.budgetLkr}
                onChange={(e) => setFormData({ ...formData, budgetLkr: e.target.value })}
              />
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '12px', fontSize: '0.9rem', fontWeight: '600' }}>
                Preferred Style Aesthetics (Select one or more) 🎨
              </label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
                {SUPPORTED_STYLES.map((style) => {
                  const isSelected = formData.preferredStyles.includes(style);
                  return (
                    <button
                      key={style}
                      type="button"
                      onClick={() => toggleStyle(style)}
                      style={{
                        padding: '10px 18px',
                        borderRadius: '20px',
                        border: isSelected ? '1px solid #6366f1' : '1px solid rgba(255,255,255,0.15)',
                        background: isSelected ? 'rgba(99, 102, 241, 0.25)' : 'rgba(255,255,255,0.05)',
                        color: isSelected ? '#a5b4fc' : 'white',
                        fontWeight: '600',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                      }}
                    >
                      {isSelected ? '✓ ' : '+ '}{style}
                    </button>
                  );
                })}
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '12px' }}>
              <button type="button" className="btn-secondary" onClick={() => setStep(1)}>
                Back
              </button>
              <button type="button" className="btn-primary" onClick={() => setStep(3)}>
                Next: Photos &amp; Action <ArrowRight size={16} />
              </button>
            </div>
          </div>
        )}

        {step === 3 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div
              style={{
                border: '2px dashed rgba(99, 102, 241, 0.4)',
                padding: '20px',
                borderRadius: '12px',
                background: 'rgba(99, 102, 241, 0.05)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                <Image style={{ width: '24px', height: '24px', color: '#818cf8' }} />
                <span style={{ fontWeight: '600', fontSize: '0.95rem' }}>
                  Room Photos ({formData.photoUrls.length} attached) 📸
                </span>
              </div>

              {formData.photoUrls.length > 0 && (
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '12px' }}>
                  {formData.photoUrls.map((url, idx) => (
                    <div
                      key={`${url}-${idx}`}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        background: 'rgba(255,255,255,0.1)',
                        padding: '4px 10px',
                        borderRadius: '12px',
                        fontSize: '0.8rem',
                      }}
                    >
                      <span>Photo #{idx + 1}</span>
                      <button
                        type="button"
                        onClick={() => removePhotoUrl(idx)}
                        style={{ background: 'none', border: 'none', color: '#f87171', cursor: 'pointer', fontWeight: 'bold' }}
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div style={{ display: 'flex', gap: '8px' }}>
                <input
                  type="text"
                  className="input-field"
                  placeholder="Paste photo image URL..."
                  value={newPhotoUrl}
                  onChange={(e) => setNewPhotoUrl(e.target.value)}
                  style={{ flex: 1, fontSize: '0.85rem' }}
                />
                <button type="button" className="btn-secondary" onClick={addPhotoUrl} style={{ fontSize: '0.85rem' }}>
                  + Add Photo
                </button>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', fontWeight: '600' }}>
                Design Preferences &amp; Notes ✍️
              </label>
              <textarea
                className="input-field"
                rows={3}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px', gap: '12px' }}>
              <button type="button" className="btn-secondary" onClick={() => setStep(2)}>
                Back
              </button>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button
                  type="button"
                  className="btn-secondary"
                  style={{ borderColor: 'rgba(99, 102, 241, 0.5)', color: '#a5b4fc', display: 'flex', alignItems: 'center', gap: '6px' }}
                  disabled={loading}
                  onClick={() => handleCreate(false)}
                >
                  <Save size={16} /> Save as Draft 📝
                </button>

                <button
                  type="button"
                  className="btn-primary"
                  disabled={loading}
                  onClick={() => handleCreate(true)}
                  style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
                >
                  <Send size={16} /> {loading ? 'Analyzing Style...' : 'Submit & Analyze Style 🤖'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
