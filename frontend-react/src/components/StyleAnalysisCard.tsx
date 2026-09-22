import React from 'react';
import { Sparkles, CheckCircle2, Palette, Sliders } from 'lucide-react';
import type { StyleAnalysis, Photo } from '../services/api';

// ─── Types ────────────────────────────────────────────────────────────────

interface RequestStatusBannerProps {
  status: string;
}

interface StyleAnalysisCardProps {
  analysis: StyleAnalysis;
  photos?: Photo[];
}

interface StatusDisplay {
  icon: string;
  label: string;
  badgeClass: string;
  bgColor: string;
  borderColor: string;
  textColor: string;
  description: string;
}

interface LifecycleStep {
  key: string;
  label: string;
}

// ─── RequestStatusBanner ──────────────────────────────────────────────────

export function RequestStatusBanner({ status }: RequestStatusBannerProps) {
  const getStatusDisplay = (st: string): StatusDisplay => {
    switch (st) {
      case 'Draft':
        return {
          icon: '📝',
          label: 'Draft',
          badgeClass: 'badge-draft',
          bgColor: 'rgba(99, 102, 241, 0.15)',
          borderColor: 'rgba(99, 102, 241, 0.4)',
          textColor: '#818cf8',
          description: 'Request created. Ready to be submitted for AI Style Analysis.',
        };
      case 'Submitted':
        return {
          icon: '📤',
          label: 'Submitted',
          badgeClass: 'badge-submitted',
          bgColor: 'rgba(245, 158, 11, 0.15)',
          borderColor: 'rgba(245, 158, 11, 0.4)',
          textColor: '#fbbf24',
          description: 'Request queued. Preparing AI Style Analysis Agent...',
        };
      case 'AIAnalysis':
        return {
          icon: '🤖',
          label: 'AI Analysis',
          badgeClass: 'badge-submitted',
          bgColor: 'rgba(168, 85, 247, 0.2)',
          borderColor: 'rgba(168, 85, 247, 0.5)',
          textColor: '#c084fc',
          description: 'Analyzing your room photos & preferences with LangGraph StateGraph...',
        };
      case 'ProposalReady':
        return {
          icon: '🟢',
          label: 'Proposal Ready',
          badgeClass: 'badge-proposal',
          bgColor: 'rgba(16, 185, 129, 0.15)',
          borderColor: 'rgba(16, 185, 129, 0.4)',
          textColor: '#34d399',
          description: 'AI Style Analysis complete! Design recommendation ready for client review.',
        };
      case 'AwaitingApproval':
        return {
          icon: '⏳',
          label: 'Awaiting Approval',
          badgeClass: 'badge-submitted',
          bgColor: 'rgba(59, 130, 246, 0.15)',
          borderColor: 'rgba(59, 130, 246, 0.4)',
          textColor: '#60a5fa',
          description: 'Awaiting client approval before passing to Designer Matching.',
        };
      case 'Approved':
        return {
          icon: '✅',
          label: 'Approved',
          badgeClass: 'badge-proposal',
          bgColor: 'rgba(16, 185, 129, 0.2)',
          borderColor: 'rgba(16, 185, 129, 0.6)',
          textColor: '#10b981',
          description: 'Request approved! Assigned to Designer Matching.',
        };
      default:
        return {
          icon: '📌',
          label: st || 'Unknown',
          badgeClass: 'badge-draft',
          bgColor: 'rgba(255,255,255,0.1)',
          borderColor: 'rgba(255,255,255,0.2)',
          textColor: '#cbd5e1',
          description: '',
        };
    }
  };

  const current = getStatusDisplay(status);

  const steps: LifecycleStep[] = [
    { key: 'Draft', label: 'Draft' },
    { key: 'Submitted', label: 'Submitted' },
    { key: 'AIAnalysis', label: 'AI Analysis' },
    { key: 'ProposalReady', label: 'Proposal Ready' },
    { key: 'AwaitingApproval', label: 'Awaiting Approval' },
    { key: 'Approved', label: 'Approved' },
  ];

  const getStepIndex = (st: string): number => steps.findIndex((s) => s.key === st);
  const currentIndex = getStepIndex(status);

  return (
    <div
      style={{
        padding: '20px',
        borderRadius: '14px',
        background: current.bgColor,
        border: `1px solid ${current.borderColor}`,
        marginBottom: '24px',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
        <div>
          <span style={{ fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '1px', color: 'var(--text-muted)' }}>
            Request Status Lifecycle
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '4px' }}>
            <span style={{ fontSize: '1.8rem' }}>{current.icon}</span>
            <h3 style={{ fontSize: '1.4rem', fontWeight: '800', color: current.textColor }}>
              {current.label}
            </h3>
          </div>
        </div>
      </div>

      <p style={{ fontSize: '0.9rem', color: '#e2e8f0', marginBottom: '16px' }}>
        {current.description}
      </p>

      {/* Lifecycle Progress Pipeline */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', overflowX: 'auto', paddingTop: '8px' }}>
        {steps.map((s, idx) => {
          const isPassed = currentIndex >= idx;
          const isCurrent = currentIndex === idx;
          return (
            <React.Fragment key={s.key}>
              <div
                style={{
                  padding: '6px 12px',
                  borderRadius: '20px',
                  fontSize: '0.75rem',
                  fontWeight: isCurrent ? '800' : '600',
                  background: isCurrent
                    ? current.textColor
                    : isPassed
                    ? 'rgba(255,255,255,0.15)'
                    : 'rgba(255,255,255,0.05)',
                  color: isCurrent ? '#0f172a' : isPassed ? '#f8fafc' : '#64748b',
                  whiteSpace: 'nowrap',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                {isPassed && !isCurrent && <span>✓</span>}
                {isCurrent && <span>➔</span>}
                {s.label}
              </div>
              {idx < steps.length - 1 && (
                <div style={{ width: '12px', height: '2px', background: isPassed ? 'rgba(255,255,255,0.3)' : 'rgba(255,255,255,0.08)' }} />
              )}
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}

// ─── StyleAnalysisCard ────────────────────────────────────────────────────

export default function StyleAnalysisCard({ analysis, photos = [] }: StyleAnalysisCardProps) {
  const [selectedPhotoIdx, setSelectedPhotoIdx] = React.useState<number>(0);
  if (!analysis) return null;

  const hasPhotos = photos && photos.length > 0;
  const selectedPhoto = hasPhotos ? photos[selectedPhotoIdx] : null;
  const conceptUrl =
    analysis.conceptRenderUrl && analysis.conceptRenderUrl.trim() !== ''
      ? analysis.conceptRenderUrl
      : null;

  return (
    <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* TOP SECTION: Side-by-Side Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>

        {/* Left: Client Uploaded Room Photos */}
        <div
          className="glass-panel"
          style={{
            padding: '20px',
            background: 'rgba(15, 23, 42, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.12)',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '1.2rem' }}>📷</span>
            <h3 style={{ fontSize: '1.1rem', fontWeight: '800', color: '#f8fafc' }}>
              Original Room Photos
            </h3>
            <span style={{ marginLeft: 'auto', fontSize: '0.75rem', color: 'var(--text-muted)', background: 'rgba(255,255,255,0.08)', padding: '2px 8px', borderRadius: '12px' }}>
              {hasPhotos ? `${photos.length} Photo${photos.length > 1 ? 's' : ''}` : 'No Photos'}
            </span>
          </div>

          {/* Primary photo viewer */}
          <div style={{ borderRadius: '10px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.1)', height: '190px', position: 'relative', background: '#0b0f19', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {selectedPhoto ? (
              <>
                <img
                  src={selectedPhoto.photoUrl}
                  alt={`Room photo ${selectedPhotoIdx + 1}`}
                  style={{ width: '100%', height: '100%', objectFit: 'cover', position: 'absolute', inset: 0 }}
                />
                <div style={{ position: 'absolute', bottom: '8px', left: '8px', right: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ background: 'rgba(15, 23, 42, 0.85)', backdropFilter: 'blur(6px)', padding: '3px 8px', borderRadius: '6px', fontSize: '0.72rem', color: '#cbd5e1', fontWeight: '600' }}>
                    Photo {selectedPhotoIdx + 1} of {photos.length}
                  </span>
                </div>
              </>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '10px', color: 'rgba(255,255,255,0.25)' }}>
                <span style={{ fontSize: '2.5rem' }}>🖼️</span>
                <span style={{ fontSize: '0.82rem', fontWeight: '600' }}>No photo uploaded</span>
              </div>
            )}
          </div>

          {/* Thumbnail strip */}
          {hasPhotos && photos.length > 1 && (
            <div style={{ display: 'grid', gridTemplateColumns: `repeat(${Math.min(photos.length, 4)}, 1fr)`, gap: '6px' }}>
              {photos.map((photo, idx) => (
                <div
                  key={photo.id || idx}
                  onClick={() => setSelectedPhotoIdx(idx)}
                  style={{
                    borderRadius: '6px',
                    overflow: 'hidden',
                    height: '52px',
                    border: idx === selectedPhotoIdx ? '2px solid #818cf8' : '2px solid rgba(255,255,255,0.08)',
                    cursor: 'pointer',
                    background: '#0b0f19',
                    transition: 'border-color 0.2s ease',
                    opacity: idx === selectedPhotoIdx ? 1 : 0.65,
                  }}
                >
                  <img
                    src={photo.photoUrl}
                    alt={`Thumbnail ${idx + 1}`}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                </div>
              ))}
            </div>
          )}

          <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontStyle: 'italic', marginTop: 'auto' }}>
            Input provided to Node 1 (Style Analysis Agent) for feature extraction.
          </p>
        </div>

        {/* Right: AI Style Analysis Metrics */}
        <div
          className="glass-panel"
          style={{
            padding: '20px',
            background: 'linear-gradient(135deg, rgba(30, 27, 75, 0.9) 0%, rgba(49, 16, 75, 0.9) 100%)',
            border: '1px solid rgba(129, 140, 248, 0.3)',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Sparkles style={{ color: '#f59e0b', width: '20px', height: '20px' }} />
              <h3 style={{ fontSize: '1.1rem', fontWeight: '800', color: 'white' }}>
                AI Style Analysis (Node 1)
              </h3>
            </div>
            <div
              style={{
                background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                color: 'white',
                padding: '4px 12px',
                borderRadius: '20px',
                fontWeight: '800',
                fontSize: '0.8rem',
              }}
            >
              {analysis.confidenceScore}% Confidence
            </div>
          </div>

          {/* Primary & Secondary Styles */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '16px' }}>
            <div style={{ background: 'rgba(255,255,255,0.06)', padding: '10px 12px', borderRadius: '10px' }}>
              <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Primary Style</span>
              <h4 style={{ fontSize: '1.1rem', fontWeight: '800', color: '#a5b4fc', marginTop: '2px' }}>
                🏙️ {analysis.primaryStyle}
              </h4>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.06)', padding: '10px 12px', borderRadius: '10px' }}>
              <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Secondary Accent</span>
              <h4 style={{ fontSize: '1.1rem', fontWeight: '800', color: '#fcd34d', marginTop: '2px' }}>
                🤍 {analysis.secondaryStyle}
              </h4>
            </div>
          </div>

          {/* Recommended Colors */}
          <div style={{ marginBottom: '14px' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: '700', color: '#cbd5e1', display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
              <Palette size={14} style={{ color: '#818cf8' }} /> Palette Swatches:
            </span>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
              {analysis.recommendedColors.map((col, idx) => {
                const hexMatch = col.match(/#[A-Fa-f0-9]{6}/);
                const hex = hexMatch ? hexMatch[0] : '#ffffff';
                return (
                  <div key={idx} className="color-swatch" style={{ padding: '3px 8px', fontSize: '0.75rem' }}>
                    <span className="color-dot" style={{ background: hex, width: '10px', height: '10px' }} />
                    <span>{col}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Detected Features */}
          <div>
            <span style={{ fontSize: '0.78rem', fontWeight: '700', color: '#cbd5e1', display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
              <Sliders size={14} style={{ color: '#34d399' }} /> Spatial Features:
            </span>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px' }}>
              {analysis.detectedFeatures.slice(0, 4).map((feat, idx) => (
                <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.76rem', color: '#e2e8f0', background: 'rgba(255,255,255,0.03)', padding: '4px 8px', borderRadius: '6px' }}>
                  <CheckCircle2 size={12} style={{ color: '#34d399', flexShrink: 0 }} />
                  <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{feat}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* BOTTOM SECTION: AI-Generated Design Concept */}
      <div
        className="glass-panel"
        style={{
          padding: '24px',
          background: 'linear-gradient(135deg, rgba(15, 23, 42, 0.95) 0%, rgba(30, 27, 75, 0.95) 100%)',
          border: '1px solid rgba(168, 85, 247, 0.4)',
          borderRadius: '16px',
          boxShadow: '0 8px 32px rgba(168, 85, 247, 0.15)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: '10px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ fontSize: '1.4rem' }}>🎨</span>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '800', color: 'white', letterSpacing: '-0.3px' }}>
                AI-GENERATED DESIGN CONCEPT
              </h3>
            </div>
            <p style={{ fontSize: '0.82rem', color: '#a5b4fc', marginTop: '2px' }}>
              Synthesized by Node 2 (Concept Image Agent) calling AI generative model using Node 1 structured output.
            </p>
          </div>

          <div style={{ background: 'rgba(168, 85, 247, 0.2)', border: '1px solid rgba(168, 85, 247, 0.4)', color: '#c084fc', padding: '6px 14px', borderRadius: '20px', fontWeight: '700', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>🤖</span> {analysis.primaryStyle} + {analysis.secondaryStyle} Redesign
          </div>
        </div>

        {/* Concept Render Frame */}
        <div
          style={{
            borderRadius: '14px',
            overflow: 'hidden',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            minHeight: '260px',
            maxHeight: '440px',
            position: 'relative',
            background: '#0b0f19',
            boxShadow: '0 12px 28px rgba(0,0,0,0.4)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {conceptUrl ? (
            <>
              <img
                src={conceptUrl}
                alt={`${analysis.primaryStyle} Design Concept Render`}
                style={{ width: '100%', height: '100%', maxHeight: '440px', objectFit: 'cover', display: 'block' }}
              />
              <div
                style={{
                  position: 'absolute',
                  bottom: 0,
                  left: 0,
                  right: 0,
                  background: 'linear-gradient(to top, rgba(15, 23, 42, 0.95) 0%, rgba(15, 23, 42, 0.6) 70%, transparent 100%)',
                  padding: '20px 24px 16px 24px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-end',
                }}
              >
                <div>
                  <span style={{ fontSize: '0.75rem', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '1px', color: '#f59e0b' }}>
                    Generative AI Redesign Concept
                  </span>
                  <h4 style={{ fontSize: '1.2rem', fontWeight: '800', color: 'white', marginTop: '2px' }}>
                    {analysis.primaryStyle} &amp; {analysis.secondaryStyle} Room Makeover
                  </h4>
                </div>
                <span style={{ fontSize: '0.75rem', color: '#94a3b8', background: 'rgba(255,255,255,0.1)', backdropFilter: 'blur(8px)', padding: '4px 10px', borderRadius: '8px' }}>
                  8K Photorealistic Render
                </span>
              </div>
            </>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '12px', padding: '48px', color: 'rgba(255,255,255,0.25)' }}>
              <span style={{ fontSize: '3rem' }}>🎨</span>
              <span style={{ fontSize: '0.9rem', fontWeight: '600' }}>Concept render not yet generated</span>
              <span style={{ fontSize: '0.78rem', color: 'rgba(255,255,255,0.18)' }}>
                Submit the request for AI analysis to generate the concept image.
              </span>
            </div>
          )}
        </div>

        {/* Analysis Summary */}
        <div style={{ marginTop: '16px', padding: '14px 18px', borderRadius: '10px', background: 'rgba(99, 102, 241, 0.1)', border: '1px solid rgba(99, 102, 241, 0.2)' }}>
          <p style={{ fontSize: '0.88rem', lineHeight: '1.5', color: '#e0e7ff' }}>
            💬 <strong>Agent Summary:</strong> {analysis.analysisSummary}
          </p>
        </div>
      </div>
    </div>
  );
}
