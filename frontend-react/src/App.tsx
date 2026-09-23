import { useState } from 'react';
import CreateRequestWizard from './components/CreateRequestWizard';
import RequestListAdmin from './components/RequestListAdmin';
import StyleAnalysisCard, { RequestStatusBanner } from './components/StyleAnalysisCard';
import { LayoutDashboard, PlusCircle, ArrowLeft, Edit3, Trash2, Lock, Send, Check, X } from 'lucide-react';
import { ProjectRequest } from './services/api';

// ─── Types ────────────────────────────────────────────────────────────────

interface EditFormData {
  roomType: string;
  lengthFeet: number | string;
  widthFeet: number | string;
  heightFeet: number | string;
  budgetLkr: number | string;
  description: string;
}

type ActiveTab = 'client-wizard' | 'staff-dashboard';

// ─── Component ────────────────────────────────────────────────────────────

export default function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('client-wizard');
  const [selectedRequest, setSelectedRequest] = useState<ProjectRequest | null>(null);
  const [isEditing, setIsEditing] = useState<boolean>(false);

  const [editData, setEditData] = useState<EditFormData>({
    roomType: '',
    lengthFeet: 0,
    widthFeet: 0,
    heightFeet: 0,
    budgetLkr: 0,
    description: '',
  });

  const isDraft = selectedRequest?.status === 'Draft';

  const startEditDraft = (): void => {
    if (!isDraft || !selectedRequest) {
      alert('🔒 Editing locked: The backend enforces that only Draft requests can be modified.');
      return;
    }
    setEditData({
      roomType: selectedRequest.roomType,
      lengthFeet: selectedRequest.lengthFeet,
      widthFeet: selectedRequest.widthFeet,
      heightFeet: selectedRequest.heightFeet,
      budgetLkr: selectedRequest.budgetLkr,
      description: selectedRequest.description,
    });
    setIsEditing(true);
  };

  const handleSaveEdit = async (): Promise<void> => {
    if (!selectedRequest) return;
    try {
      const res = await fetch(
        `http://localhost:5000/api/v1/project-requests/${selectedRequest.id}`,
        {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'X-Client-Id': 'client-nimali',
          },
          body: JSON.stringify({
            ...editData,
            lengthFeet: Number(editData.lengthFeet),
            widthFeet: Number(editData.widthFeet),
            heightFeet: Number(editData.heightFeet),
            budgetLkr: Number(editData.budgetLkr),
            preferredStyles: selectedRequest.preferredStyles || ['Modern'],
          }),
        }
      );

      if (res.ok) {
        const updated = (await res.json()) as ProjectRequest;
        alert('✅ Draft request updated successfully!');
        setSelectedRequest(updated);
        setIsEditing(false);
      } else {
        const err = (await res.json()) as { message?: string };
        alert('Backend Error: ' + (err.message ?? 'Failed to update draft request'));
      }
    } catch (err) {
      alert('Error updating draft: ' + (err instanceof Error ? err.message : String(err)));
    }
  };

  const handleDeleteRequest = async (id: string): Promise<void> => {
    if (!isDraft) {
      alert('🔒 Deletion locked: The backend enforces that only Draft requests can be deleted.');
      return;
    }
    if (window.confirm('Are you sure you want to delete this Draft request?')) {
      try {
        const res = await fetch(
          `http://localhost:5000/api/v1/project-requests/${id}`,
          {
            method: 'DELETE',
            headers: { 'X-Client-Id': 'client-nimali' },
          }
        );
        if (res.ok) {
          alert('🗑️ Draft request deleted successfully from backend.');
          setSelectedRequest(null);
          setActiveTab('staff-dashboard');
        } else {
          const data = (await res.json()) as { message?: string };
          alert('Backend Error: ' + (data.message ?? 'Failed to delete request'));
        }
      } catch (err) {
        alert('Error: ' + (err instanceof Error ? err.message : String(err)));
      }
    }
  };

  const handleSubmitDraftToAI = async (id: string): Promise<void> => {
    try {
      const res = await fetch(
        `http://localhost:5000/api/v1/project-requests/${id}/submit`,
        { method: 'POST' }
      );
      if (res.ok) {
        const result = (await res.json()) as ProjectRequest;
        alert('🚀 Draft submitted! AI Style Analysis Agent processing...');
        setSelectedRequest(result);
      } else {
        alert('Failed to submit draft for AI analysis.');
      }
    } catch (err) {
      alert('Error: ' + (err instanceof Error ? err.message : String(err)));
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      {/* Navigation Header */}
      <header
        style={{
          background: 'rgba(15, 23, 42, 0.8)',
          backdropFilter: 'blur(12px)',
          borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '16px 32px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          position: 'sticky',
          top: 0,
          zIndex: 100,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: '900',
              fontSize: '1.2rem',
              color: 'white',
              boxShadow: '0 4px 12px rgba(99, 102, 241, 0.4)',
            }}
          >
            S
          </div>
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: '800', letterSpacing: '-0.5px' }}>
              StyleSync
            </h1>
            <span style={{ fontSize: '0.75rem', color: '#a5b4fc', fontWeight: '600' }}>
              Student 2 — Project Requests &amp; Style Analysis Agent
            </span>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            className={activeTab === 'client-wizard' ? 'btn-primary' : 'btn-secondary'}
            onClick={() => {
              setActiveTab('client-wizard');
              setSelectedRequest(null);
              setIsEditing(false);
            }}
          >
            <PlusCircle size={18} /> Client Wizard (Create)
          </button>
          <button
            className={activeTab === 'staff-dashboard' ? 'btn-primary' : 'btn-secondary'}
            onClick={() => {
              setActiveTab('staff-dashboard');
              setSelectedRequest(null);
              setIsEditing(false);
            }}
          >
            <LayoutDashboard size={18} /> Staff Dashboard
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '32px 16px' }}>
        {selectedRequest ? (
          <div className="glass-panel" style={{ maxWidth: '900px', margin: '0 auto', padding: '32px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', flexWrap: 'wrap', gap: '12px' }}>
              <button
                className="btn-secondary"
                onClick={() => { setSelectedRequest(null); setIsEditing(false); }}
              >
                <ArrowLeft size={16} /> Back to Requests
              </button>

              {/* Action Controls */}
              <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                {isDraft && (
                  <button
                    className="btn-primary"
                    onClick={() => handleSubmitDraftToAI(selectedRequest.id)}
                    style={{ background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)' }}
                  >
                    <Send size={16} /> Submit to AI Analysis 🤖
                  </button>
                )}

                <button
                  className="btn-secondary"
                  disabled={!isDraft}
                  title={isDraft ? 'Edit Draft Request' : '🔒 Editing locked after submission'}
                  style={{
                    opacity: isDraft ? 1 : 0.4,
                    cursor: isDraft ? 'pointer' : 'not-allowed',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                  onClick={startEditDraft}
                >
                  {isDraft ? <Edit3 size={16} /> : <Lock size={16} />}
                  ✏️ Edit Draft {isDraft ? '' : '(Locked)'}
                </button>

                <button
                  className="btn-secondary"
                  disabled={!isDraft}
                  title={isDraft ? 'Delete Draft Request' : '🔒 Deletion locked after submission'}
                  style={{
                    opacity: isDraft ? 1 : 0.4,
                    cursor: isDraft ? 'pointer' : 'not-allowed',
                    color: isDraft ? '#ef4444' : '#64748b',
                    borderColor: isDraft ? 'rgba(239, 68, 68, 0.4)' : 'rgba(255,255,255,0.1)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                  onClick={() => handleDeleteRequest(selectedRequest.id)}
                >
                  {isDraft ? <Trash2 size={16} /> : <Lock size={16} />}
                  🗑️ Delete Draft {isDraft ? '' : '(Locked)'}
                </button>
              </div>
            </div>

            {/* Request Status Banner */}
            <RequestStatusBanner status={selectedRequest.status} />

            {/* Inline Edit Form for Draft */}
            {isEditing ? (
              <div style={{ background: 'rgba(99, 102, 241, 0.1)', border: '1px solid rgba(99, 102, 241, 0.3)', padding: '24px', borderRadius: '14px', marginBottom: '24px' }}>
                <h3 style={{ fontSize: '1.2rem', fontWeight: '800', marginBottom: '16px', color: '#a5b4fc' }}>
                  ✏️ Editing Draft Request ({selectedRequest.id.substring(0, 8)})
                </h3>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Room Type</label>
                    <input
                      type="text"
                      className="input-field"
                      value={editData.roomType}
                      onChange={(e) => setEditData({ ...editData, roomType: e.target.value })}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Budget (LKR)</label>
                    <input
                      type="number"
                      className="input-field"
                      value={editData.budgetLkr}
                      onChange={(e) => setEditData({ ...editData, budgetLkr: e.target.value })}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', marginBottom: '16px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Length (ft)</label>
                    <input
                      type="number"
                      className="input-field"
                      value={editData.lengthFeet}
                      onChange={(e) => setEditData({ ...editData, lengthFeet: e.target.value })}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Width (ft)</label>
                    <input
                      type="number"
                      className="input-field"
                      value={editData.widthFeet}
                      onChange={(e) => setEditData({ ...editData, widthFeet: e.target.value })}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Height (ft)</label>
                    <input
                      type="number"
                      className="input-field"
                      value={editData.heightFeet}
                      onChange={(e) => setEditData({ ...editData, heightFeet: e.target.value })}
                    />
                  </div>
                </div>

                <div style={{ marginBottom: '20px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', marginBottom: '6px' }}>Description</label>
                  <textarea
                    className="input-field"
                    rows={3}
                    value={editData.description}
                    onChange={(e) => setEditData({ ...editData, description: e.target.value })}
                  />
                </div>

                <div style={{ display: 'flex', gap: '12px' }}>
                  <button className="btn-primary" onClick={handleSaveEdit}>
                    <Check size={16} /> Save Changes
                  </button>
                  <button className="btn-secondary" onClick={() => setIsEditing(false)}>
                    <X size={16} /> Cancel
                  </button>
                </div>
              </div>
            ) : (
              <>
                <h2 style={{ fontSize: '1.6rem', fontWeight: '800', marginBottom: '8px' }}>
                  🏠 {selectedRequest.roomType} Request Details
                </h2>
                <p style={{ color: 'var(--text-muted)', marginBottom: '24px' }}>
                  Dimensions: {selectedRequest.lengthFeet} × {selectedRequest.widthFeet} × {selectedRequest.heightFeet} ft | Budget: LKR {Number(selectedRequest.budgetLkr).toLocaleString()}
                </p>

                <div style={{ background: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '12px', marginBottom: '24px' }}>
                  <h4 style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: '6px' }}>Client Description &amp; Goals</h4>
                  <p style={{ fontSize: '1rem', fontStyle: 'italic' }}>"{selectedRequest.description}"</p>
                </div>
              </>
            )}

            {/* AI Analysis Component */}
            {selectedRequest.styleAnalysis && (
              <StyleAnalysisCard
                analysis={selectedRequest.styleAnalysis}
                photos={selectedRequest.photos ?? []}
              />
            )}
          </div>
        ) : activeTab === 'client-wizard' ? (
          <CreateRequestWizard
            onRequestCreated={(req) => {
              setSelectedRequest(req);
              setIsEditing(false);
            }}
          />
        ) : (
          <RequestListAdmin
            onViewDetail={(req) => {
              setSelectedRequest(req);
              setIsEditing(false);
            }}
          />
        )}
      </main>

      {/* Footer */}
      <footer
        style={{
          borderTop: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '16px 32px',
          textAlign: 'center',
          fontSize: '0.8rem',
          color: 'var(--text-muted)',
        }}
      >
        StyleSync — Interior Design Marketplace | Module: SE3090 — Assignment 1 (Student 2 Component)
      </footer>
    </div>
  );
}
