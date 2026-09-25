import { useState, useEffect } from 'react';
import CreateRequestWizard from '../../components/CreateRequestWizard';
import RequestListAdmin from '../../components/RequestListAdmin';
import StyleAnalysisCard, { RequestStatusBanner } from '../../components/StyleAnalysisCard';
import { LayoutDashboard, PlusCircle, ArrowLeft, Edit3, Trash2, Lock, Check, X, ChevronDown, LogOut } from 'lucide-react';
import { ProjectRequest } from '../../services/api';
import { useAuth } from '../../auth/AuthContext';
import { Link, useNavigate } from 'react-router-dom';
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
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<ActiveTab>('staff-dashboard');
  const [selectedRequest, setSelectedRequest] = useState<ProjectRequest | null>(null);
  const [isEditing, setIsEditing] = useState<boolean>(false);
  const [isProfileOpen, setIsProfileOpen] = useState<boolean>(false);

  useEffect(() => {
    if (user?.role === 'Client') {
      setActiveTab('client-wizard');
    } else {
      setActiveTab('staff-dashboard');
    }
  }, [user?.role]);

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

    // Backend stores budget in budgetMin/budgetMax and dimensions in specialRequirements
    // e.g. "Dimensions: 15x12x10 ft. Photos: ..."
    const raw = selectedRequest as unknown as Record<string, unknown>;
    const budgetVal = (raw.budgetMin ?? raw.budgetMax ?? selectedRequest.budgetLkr ?? 0) as number;

    // Parse dimensions from specialRequirements string
    let length = selectedRequest.lengthFeet ?? 0;
    let width = selectedRequest.widthFeet ?? 0;
    let height = selectedRequest.heightFeet ?? 0;
    const specReq = (raw.specialRequirements ?? '') as string;
    const dimMatch = specReq.match(/Dimensions:\s*(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)/i);
    if (dimMatch) {
      length = parseFloat(dimMatch[1]);
      width = parseFloat(dimMatch[2]);
      height = parseFloat(dimMatch[3]);
    }

    setEditData({
      roomType: selectedRequest.roomType ?? 'Bedroom',
      lengthFeet: length,
      widthFeet: width,
      heightFeet: height,
      budgetLkr: budgetVal,
      description: selectedRequest.description ?? '',
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
            budgetMin: Number(editData.budgetLkr),
            budgetMax: Number(editData.budgetLkr),
            description: editData.description && editData.description.length >= 20
              ? editData.description
              : (editData.description || '') + ' '.repeat(Math.max(0, 20 - (editData.description?.length ?? 0))),
            specialRequirements: `Dimensions: ${editData.lengthFeet}x${editData.widthFeet}x${editData.heightFeet} ft`,
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
            {user?.role === 'Client' && (
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
            )}
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
              <span>{user?.role === 'Client' ? 'My Requests' : 'Staff Dashboard'}</span>
            </button>
          </div>

          <GlassThemeToggle />

          {user ? (
            <div className="relative">
              <button
                onClick={() => setIsProfileOpen((prev) => !prev)}
                className="inline-flex items-center gap-2 px-3 py-1.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs font-medium hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition"
              >
                <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
                <span className="max-w-[120px] truncate">{user.name}</span>
                <ChevronDown className={`w-3.5 h-3.5 text-[#78716C] dark:text-[#A8A29E] transition-transform ${isProfileOpen ? 'rotate-180' : ''}`} />
              </button>

              {isProfileOpen && (
                <>
                  {/* Backdrop */}
                  <div
                    className="fixed inset-0 z-40"
                    onClick={() => setIsProfileOpen(false)}
                  />
                  {/* Dropdown panel */}
                  <div className="absolute right-0 mt-2 w-64 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl shadow-xl z-50 overflow-hidden">
                    {/* Profile header */}
                    <div className="px-4 py-4 border-b border-[#E7E1D7] dark:border-[#2E2824] bg-[#FAF8F5] dark:bg-[#12100E]">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-[#C48A36] flex items-center justify-center text-white font-bold text-sm shrink-0">
                          {user.name?.charAt(0).toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-bold text-[#1C1917] dark:text-[#FAF8F5] truncate">{user.name}</p>
                          <p className="text-xs text-[#78716C] dark:text-[#A8A29E] truncate">{user.email}</p>
                        </div>
                      </div>
                    </div>

                    {/* Role badge */}
                    <div className="px-4 py-3 border-b border-[#E7E1D7] dark:border-[#2E2824]">
                      <div className="flex items-center justify-between">
                        <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">Role</span>
                        <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                          user.role === 'Client'
                            ? 'bg-blue-50 dark:bg-blue-950/50 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-900'
                            : user.role === 'Designer'
                            ? 'bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-900'
                            : 'bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525]'
                        }`}>
                          {user.role}
                        </span>
                      </div>
                      {user.id && (
                        <div className="flex items-center justify-between mt-2">
                          <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">User ID</span>
                          <span className="text-xs font-mono text-[#57534E] dark:text-[#A8A29E]">#{user.id}</span>
                        </div>
                      )}
                    </div>

                    {/* Logout */}
                    <div className="p-2">
                      <button
                        onClick={() => {
                          logout();
                          setIsProfileOpen(false);
                          navigate('/login');
                        }}
                        className="w-full flex items-center gap-2.5 px-3 py-2.5 text-xs font-semibold text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/50 rounded-xl transition"
                      >
                        <LogOut className="w-3.5 h-3.5" />
                        <span>Sign out</span>
                      </button>
                    </div>
                  </div>
                </>
              )}
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
                    placeholder="Describe your design preferences (min 20 characters)..."
                    value={editData.description}
                    onChange={(e) => setEditData({ ...editData, description: e.target.value })}
                    className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                  />
                  {editData.description && editData.description.length < 20 && (
                    <p className="text-[10px] text-amber-600 dark:text-amber-400 mt-1">
                      ⚠ Description must be at least 20 characters ({20 - editData.description.length} more needed)
                    </p>
                  )}
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
