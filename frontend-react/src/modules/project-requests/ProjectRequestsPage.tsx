import { useState } from 'react';
import CreateRequestWizard from '../../components/CreateRequestWizard';
import RequestListAdmin from '../../components/RequestListAdmin';
import StyleAnalysisCard, { RequestStatusBanner } from '../../components/StyleAnalysisCard';
import { LayoutDashboard, PlusCircle, ArrowLeft, Edit3, Trash2, Lock, Check, X } from 'lucide-react';
import { ProjectRequest } from '../../services/api';
import { useAuth } from '../../auth/AuthContext';
import { Link } from 'react-router-dom';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

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
      const token = localStorage.getItem('stylesync_jwt_token');
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
            roomType: editData.roomType,
            lengthFeet: Number(editData.lengthFeet),
            widthFeet: Number(editData.widthFeet),
            heightFeet: Number(editData.heightFeet),
            budgetLkr: Number(editData.budgetLkr),
            description: editData.description,
          }),
        }
      );
      if (res.ok) {
        const updated = (await res.json()) as ProjectRequest;
        setSelectedRequest(updated);
        setIsEditing(false);
        alert('✅ Draft request updated successfully!');
      } else {
        const err = (await res.json()) as { message?: string };
        alert('Backend Error: ' + (err.message ?? 'Failed to update draft'));
      }
    } catch (err) {
      alert('Error saving edit: ' + (err instanceof Error ? err.message : String(err)));
    }
  };

  const handleDeleteRequest = async (id: string): Promise<void> => {
    if (!isDraft) {
      alert('🔒 Deletion locked: The backend enforces that only Draft requests can be deleted.');
      return;
    }
    if (window.confirm('Are you sure you want to delete this Draft request?')) {
      try {
        const token = localStorage.getItem('stylesync_jwt_token');
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
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex flex-col transition-colors">
      {/* Top Bar with Auth status */}
      <header className="border-b border-[#E7E1D7] dark:border-[#2E2824] px-6 sm:px-10 py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 sticky top-0 bg-[#FAF8F5]/90 dark:bg-[#12100E]/90 backdrop-blur-md z-40">
        <div className="flex items-center gap-4">
          <Logo variant="auto" size="md" />
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Makeover Studio</h1>
              <span className="px-2.5 py-0.5 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-[10px] font-bold uppercase rounded-full">
                AI Agent
              </span>
            </div>
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              Room Makeover Requests &amp; AI Style Analysis
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center p-1 bg-[#EFEAE1] dark:bg-[#1C1917] rounded-xl border border-[#E7E1D7] dark:border-[#2E2824]">
            <button
              onClick={() => {
                setActiveTab('client-wizard');
                setSelectedRequest(null);
              }}
              className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                activeTab === 'client-wizard'
                  ? 'bg-white dark:bg-[#2A231A] text-[#1C1917] dark:text-[#FAF8F5] shadow-2xs'
                  : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
              }`}
            >
              <PlusCircle className="w-3.5 h-3.5" />
              <span>Create Request</span>
            </button>
            <button
              onClick={() => {
                setActiveTab('staff-dashboard');
                setSelectedRequest(null);
              }}
              className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                activeTab === 'staff-dashboard'
                  ? 'bg-white dark:bg-[#2A231A] text-[#1C1917] dark:text-[#FAF8F5] shadow-2xs'
                  : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
              }`}
            >
              <LayoutDashboard className="w-3.5 h-3.5" />
              <span>Staff Dashboard</span>
            </button>
          </div>

          <GlassThemeToggle />

          {user ? (
            <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs font-medium">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              <span>{user.name}</span>
            </div>
          ) : (
            <Link
              to="/login"
              className="px-3.5 py-1.5 text-xs font-semibold text-[#FAF8F5] bg-[#1C1917] dark:bg-[#FAF8F5] dark:text-[#1C1917] rounded-xl hover:opacity-90 transition"
            >
              Sign In
            </Link>
          )}
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 p-6 sm:p-10 max-w-6xl mx-auto w-full">
        {selectedRequest ? (
          <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <button
                onClick={() => setSelectedRequest(null)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs font-semibold hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition self-start"
              >
                <ArrowLeft className="w-4 h-4" />
                <span>Back to Requests</span>
              </button>

              <div className="flex items-center gap-3">
                {isDraft ? (
                  <>
                    <button
                      onClick={startEditDraft}
                      className="inline-flex items-center gap-2 px-3.5 py-2 bg-blue-50 dark:bg-blue-950/50 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-900 rounded-xl text-xs font-semibold hover:bg-blue-100 transition"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                      <span>Edit Draft</span>
                    </button>
                    <button
                      onClick={() => handleDeleteRequest(selectedRequest.id)}
                      className="inline-flex items-center gap-2 px-3.5 py-2 bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900 rounded-xl text-xs font-semibold hover:bg-rose-100 transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>Delete Draft</span>
                    </button>
                  </>
                ) : (
                  <div className="inline-flex items-center gap-2 px-3.5 py-2 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#78716C] dark:text-[#A8A29E]">
                    <Lock className="w-3.5 h-3.5" />
                    <span>Locked ({selectedRequest.status})</span>
                  </div>
                )}
              </div>
            </div>

            {isEditing && (
              <div className="bg-white dark:bg-[#1A1715] border border-[#C48A36]/60 rounded-3xl p-6 shadow-sm space-y-4">
                <h3 className="font-serif text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  Edit Draft Request Details
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                      Room Type
                    </label>
                    <select
                      value={editData.roomType}
                      onChange={(e) => setEditData({ ...editData, roomType: e.target.value })}
                      className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
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
                    <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                      Length (ft)
                    </label>
                    <input
                      type="number"
                      value={editData.lengthFeet}
                      onChange={(e) => setEditData({ ...editData, lengthFeet: e.target.value })}
                      className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                      Width (ft)
                    </label>
                    <input
                      type="number"
                      value={editData.widthFeet}
                      onChange={(e) => setEditData({ ...editData, widthFeet: e.target.value })}
                      className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                      Height (ft)
                    </label>
                    <input
                      type="number"
                      value={editData.heightFeet}
                      onChange={(e) => setEditData({ ...editData, heightFeet: e.target.value })}
                      className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                      Budget (LKR)
                    </label>
                    <input
                      type="number"
                      value={editData.budgetLkr}
                      onChange={(e) => setEditData({ ...editData, budgetLkr: e.target.value })}
                      className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                    Description
                  </label>
                  <textarea
                    rows={3}
                    value={editData.description}
                    onChange={(e) => setEditData({ ...editData, description: e.target.value })}
                    className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                  />
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={handleSaveEdit}
                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-[#C48A36] text-white rounded-xl text-xs font-semibold hover:bg-[#A87226]"
                  >
                    <Check className="w-3.5 h-3.5" />
                    <span>Save Changes</span>
                  </button>
                  <button
                    onClick={() => setIsEditing(false)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold rounded-xl"
                  >
                    <X className="w-3.5 h-3.5" />
                    <span>Cancel</span>
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
              <CreateRequestWizard
                onRequestCreated={(created: ProjectRequest) => {
                  setSelectedRequest(created);
                }}
              />
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
      <footer className="border-t border-[#E7E1D7] dark:border-[#2E2824] py-6 px-6 text-center text-xs text-[#78716C] dark:text-[#A8A29E]">
        StyleSync — Interior Design Marketplace | Architecture &amp; Styling Agent Platform
      </footer>
    </div>
  );
}
