import { useState } from 'react';
import CreateRequestWizard from '../../components/CreateRequestWizard';
import RequestListAdmin from '../../components/RequestListAdmin';
import StyleAnalysisCard, { RequestStatusBanner } from '../../components/StyleAnalysisCard';
import { LayoutDashboard, PlusCircle, ArrowLeft, Edit3, Trash2, Lock, Send, Check, X } from 'lucide-react';
import { ProjectRequest } from '../../services/api';
import { useAuth } from '../../auth/AuthContext';
import { Link } from 'react-router-dom';

interface EditFormData {
  roomType: string;
  lengthFeet: number | string;
  widthFeet: number | string;
  heightFeet: number | string;
  budgetLkr: number | string;
  description: string;
}

type ActiveTab = 'client-wizard' | 'staff-dashboard';

export default function ProjectRequestsPage() {
  const { user } = useAuth();
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
      const token = localStorage.getItem('stylesync_token');
      const res = await fetch(
        `http://localhost:5000/api/v1/project-requests/${selectedRequest.id}`,
        {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'X-Client-Id': user?.id || 'client-nimali',
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
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
        const token = localStorage.getItem('stylesync_token');
        const res = await fetch(
          `http://localhost:5000/api/v1/project-requests/${id}`,
          {
            method: 'DELETE',
            headers: {
              'X-Client-Id': user?.id || 'client-nimali',
              ...(token ? { Authorization: `Bearer ${token}` } : {}),
            },
          }
        );
        if (res.ok) {
          alert('🗑️ Draft request deleted successfully.');
          setSelectedRequest(null);
        } else {
          const err = (await res.json()) as { message?: string };
          alert('Backend Error: ' + (err.message ?? 'Failed to delete draft request'));
        }
      } catch (err) {
        alert('Error deleting: ' + (err instanceof Error ? err.message : String(err)));
      }
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', background: 'var(--bg-gradient, #0f172a)', color: '#f8fafc' }}>
      {/* Top Bar with Auth status */}
      <header
        style={{
          borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '16px 32px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          backdropFilter: 'blur(10px)',
          background: 'rgba(15, 23, 42, 0.85)',
          position: 'sticky',
          top: 0,
          zIndex: 40,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <Link to="/" style={{ textDecoration: 'none', color: 'inherit', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 10,
                background: 'linear-gradient(135deg, #6366f1 0%, #ec4899 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 'bold',
                fontSize: '1.2rem',
                color: 'white',
              }}
            >
              S
            </div>
            <div>
              <h1 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0 }}>StyleSync</h1>
              <p style={{ fontSize: '0.8rem', color: '#94a3b8', margin: 0 }}>
                Student 2 — Project Requests & Style Analysis Agent
              </p>
            </div>
          </Link>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <button
            onClick={() => {
              setActiveTab('client-wizard');
              setSelectedRequest(null);
            }}
            className={activeTab === 'client-wizard' ? 'btn-primary' : 'btn-secondary'}
            style={{ padding: '8px 16px', fontSize: '0.875rem' }}
          >
            <PlusCircle size={16} /> Client Wizard (Create)
          </button>
          <button
            onClick={() => {
              setActiveTab('staff-dashboard');
              setSelectedRequest(null);
            }}
            className={activeTab === 'staff-dashboard' ? 'btn-primary' : 'btn-secondary'}
            style={{ padding: '8px 16px', fontSize: '0.875rem' }}
          >
            <LayoutDashboard size={16} /> Staff Dashboard
          </button>

          {user ? (
            <div style={{ marginLeft: 16, display: 'flex', alignItems: 'center', gap: 8, padding: '6px 12px', background: 'rgba(255,255,255,0.08)', borderRadius: 8, fontSize: '0.85rem' }}>
              <span style={{ color: '#34d399' }}>●</span>
              <span>{user.name} ({user.role})</span>
            </div>
          ) : (
            <Link
              to="/login"
              style={{
                marginLeft: 12,
                padding: '8px 16px',
                borderRadius: 8,
                background: 'rgba(99, 102, 241, 0.2)',
                border: '1px solid rgba(99, 102, 241, 0.4)',
                color: '#818cf8',
                textDecoration: 'none',
                fontSize: '0.875rem',
                fontWeight: 600,
              }}
            >
              Sign In
            </Link>
          )}
        </div>
      </header>

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '32px 16px', maxWidth: '1200px', margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>
        {selectedRequest ? (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
              <button
                onClick={() => setSelectedRequest(null)}
                className="btn-secondary"
                style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '8px 16px' }}
              >
                <ArrowLeft size={16} /> Back to Requests
              </button>

              <div style={{ display: 'flex', gap: 12 }}>
                {isDraft ? (
                  <>
                    <button
                      onClick={startEditDraft}
                      className="btn-secondary"
                      style={{ display: 'inline-flex', alignItems: 'center', gap: 8, color: '#60a5fa' }}
                    >
                      <Edit3 size={16} /> Edit Draft
                    </button>
                    <button
                      onClick={() => handleDeleteRequest(selectedRequest.id)}
                      className="btn-secondary"
                      style={{ display: 'inline-flex', alignItems: 'center', gap: 8, color: '#f87171' }}
                    >
                      <Trash2 size={16} /> Delete Draft
                    </button>
                  </>
                ) : (
                  <div
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 8,
                      fontSize: '0.85rem',
                      color: 'var(--text-muted, #94a3b8)',
                      background: 'rgba(255,255,255,0.05)',
                      padding: '8px 16px',
                      borderRadius: 8,
                      border: '1px solid rgba(255,255,255,0.1)',
                    }}
                  >
                    <Lock size={14} /> Editing Locked ({selectedRequest.status})
                  </div>
                )}
              </div>
            </div>

            {isEditing && (
              <div className="glass-panel" style={{ padding: 24, marginBottom: 24, border: '1px solid #3b82f6' }}>
                <h3 style={{ marginTop: 0, marginBottom: 16 }}>✏️ Edit Draft Request Details</h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 16 }}>
                  <div>
                    <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Room Type</label>
                    <select
                      value={editData.roomType}
                      onChange={(e) => setEditData({ ...editData, roomType: e.target.value })}
                      className="input-field"
                      style={{ marginTop: 4 }}
                    >
                      <option value="LivingRoom">Living Room</option>
                      <option value="Bedroom">Bedroom</option>
                      <option value="Kitchen">Kitchen</option>
                      <option value="DiningRoom">Dining Room</option>
                      <option value="Office">Office</option>
                      <option value="Bathroom">Bathroom</option>
                    </select>
                  </div>
                  <div>
                    <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Length (ft)</label>
                    <input
                      type="number"
                      value={editData.lengthFeet}
                      onChange={(e) => setEditData({ ...editData, lengthFeet: e.target.value })}
                      className="input-field"
                      style={{ marginTop: 4 }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Width (ft)</label>
                    <input
                      type="number"
                      value={editData.widthFeet}
                      onChange={(e) => setEditData({ ...editData, widthFeet: e.target.value })}
                      className="input-field"
                      style={{ marginTop: 4 }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Height (ft)</label>
                    <input
                      type="number"
                      value={editData.heightFeet}
                      onChange={(e) => setEditData({ ...editData, heightFeet: e.target.value })}
                      className="input-field"
                      style={{ marginTop: 4 }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Budget (LKR)</label>
                    <input
                      type="number"
                      value={editData.budgetLkr}
                      onChange={(e) => setEditData({ ...editData, budgetLkr: e.target.value })}
                      className="input-field"
                      style={{ marginTop: 4 }}
                    />
                  </div>
                </div>
                <div style={{ marginBottom: 16 }}>
                  <label style={{ fontSize: '0.85rem', color: '#94a3b8' }}>Description</label>
                  <textarea
                    rows={3}
                    value={editData.description}
                    onChange={(e) => setEditData({ ...editData, description: e.target.value })}
                    className="input-field"
                    style={{ marginTop: 4, width: '100%' }}
                  />
                </div>
                <div style={{ display: 'flex', gap: 12 }}>
                  <button onClick={handleSaveEdit} className="btn-primary" style={{ padding: '8px 16px' }}>
                    <Check size={16} /> Save Changes
                  </button>
                  <button onClick={() => setIsEditing(false)} className="btn-secondary" style={{ padding: '8px 16px' }}>
                    <X size={16} /> Cancel
                  </button>
                </div>
              </div>
            )}

            <RequestStatusBanner status={selectedRequest.status} />
            {selectedRequest.styleAnalysis && (
              <StyleAnalysisCard
                analysis={selectedRequest.styleAnalysis}
                photos={selectedRequest.photos}
              />
            )}
          </div>
        ) : (
          <div>
            {activeTab === 'client-wizard' && (
              <div style={{ maxWidth: '800px', margin: '0 auto' }}>
                <CreateRequestWizard
                  onRequestCreated={(created: ProjectRequest) => {
                    setSelectedRequest(created);
                  }}
                />
              </div>
            )}

            {activeTab === 'staff-dashboard' && (
              <RequestListAdmin
                onViewDetail={(req: ProjectRequest) => setSelectedRequest(req)}
              />
            )}
          </div>
        )}
      </main>

      {/* Footer */}
      <footer
        style={{
          borderTop: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '16px 32px',
          textAlign: 'center',
          fontSize: '0.8rem',
          color: '#94a3b8',
        }}
      >
        StyleSync — Interior Design Marketplace | Module: SE3090 — Assignment 1 (Student 2 Component)
      </footer>
    </div>
  );
}
