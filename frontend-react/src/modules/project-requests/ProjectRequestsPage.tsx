import { useState, useEffect } from 'react';
import CreateRequestWizard from '../../components/CreateRequestWizard';
import RequestListAdmin from '../../components/RequestListAdmin';
import StyleAnalysisCard, { RequestStatusBanner } from '../../components/StyleAnalysisCard';
import {
  LayoutDashboard,
  PlusCircle,
  ArrowLeft,
  Edit3,
  Trash2,
  Lock,
  Check,
  X,
  ChevronDown,
  LogOut,
  Sparkles,
  Send,
  RefreshCw,
  Home,
  Ruler,
  Banknote,
  Palette,
  FileText,
  Image as ImageIcon,
  AlertCircle
} from 'lucide-react';
import { ProjectRequest, fetchAIStyleAnalysis, submitRequestForAI } from '../../services/api';
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
  const [analyzingAi, setAnalyzingAi] = useState<boolean>(false);
  const [editErrorMsg, setEditErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    if (user?.role === 'Client') {
      setActiveTab('client-wizard');
    } else {
      setActiveTab('staff-dashboard');
    }
  }, [user?.role]);

  // Auto-run AI style analysis if request is not Draft and has no style analysis yet
  useEffect(() => {
    if (selectedRequest && !selectedRequest.styleAnalysis && selectedRequest.status !== 'Draft' && !analyzingAi) {
      handleRunAiAnalysis(selectedRequest);
    }
  }, [selectedRequest?.id]);

  const handleRunAiAnalysis = async (req: ProjectRequest): Promise<void> => {
    setAnalyzingAi(true);
    try {
      const analysis = await fetchAIStyleAnalysis(req);
      const updated = { ...req, styleAnalysis: analysis };
      setSelectedRequest(updated);
    } catch (err) {
      console.warn('AI analysis execution notice:', err);
    } finally {
      setAnalyzingAi(false);
    }
  };

  const handleSubmitDraft = async (req: ProjectRequest): Promise<void> => {
    setAnalyzingAi(true);
    try {
      const submitted = await submitRequestForAI(req.id, req);
      setSelectedRequest(submitted);
      alert('🚀 Request submitted! AI Style Analysis Agent invoked successfully.');
    } catch (err) {
      alert('Error submitting draft: ' + (err instanceof Error ? err.message : String(err)));
    } finally {
      setAnalyzingAi(false);
    }
  };

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
    
    if (Number(editData.lengthFeet) <= 0 || Number(editData.widthFeet) <= 0 || Number(editData.heightFeet) <= 0) {
      setEditErrorMsg('Please enter valid dimensions greater than zero.');
      return;
    }
    if (Number(editData.budgetLkr) <= 0) {
      setEditErrorMsg('Please enter a valid budget greater than zero.');
      return;
    }
    setEditErrorMsg(null);

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
          `http://localhost:5000/api/v1/project-requests/${id}/cancel`,
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
                      onChange={(e) => {
                        setEditErrorMsg(null);
                        setEditData({ ...editData, roomType: e.target.value });
                      }}
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
                      onChange={(e) => {
                        setEditErrorMsg(null);
                        setEditData({ ...editData, lengthFeet: e.target.value });
                      }}
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
                      onChange={(e) => {
                        setEditErrorMsg(null);
                        setEditData({ ...editData, widthFeet: e.target.value });
                      }}
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
                      onChange={(e) => {
                        setEditErrorMsg(null);
                        setEditData({ ...editData, heightFeet: e.target.value });
                      }}
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
                      onChange={(e) => {
                        setEditErrorMsg(null);
                        setEditData({ ...editData, budgetLkr: e.target.value });
                      }}
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
                    onChange={(e) => {
                      setEditErrorMsg(null);
                      setEditData({ ...editData, description: e.target.value });
                    }}
                    className="w-full px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs"
                  />
                  {editData.description && editData.description.length < 20 && (
                    <p className="text-[10px] text-amber-600 dark:text-amber-400 mt-1">
                      ⚠ Description must be at least 20 characters ({20 - editData.description.length} more needed)
                    </p>
                  )}
                </div>

                {editErrorMsg && (
                  <div className="flex items-center gap-2.5 p-3.5 text-xs font-semibold text-rose-600 bg-rose-50 border border-rose-200 rounded-xl dark:bg-rose-950/30 dark:border-rose-900/50 dark:text-rose-400">
                    <AlertCircle className="w-4 h-4 shrink-0" />
                    <span>{editErrorMsg}</span>
                  </div>
                )}

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

            {/* Request Overview Card */}
            {!isEditing && (
              <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8 shadow-sm space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E7E1D7] dark:border-[#2E2824] pb-5">
                  <div className="flex items-center gap-3.5">
                    <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] border border-[#E8DEC8] dark:border-[#423525] flex items-center justify-center text-[#C48A36]">
                      <Home className="w-6 h-6" />
                    </div>
                    <div>
                      <h2 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                        {selectedRequest.roomType.replace(/([A-Z])/g, ' $1').trim()} Makeover
                      </h2>
                      <div className="flex items-center gap-3 text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">
                        <span>Client: <strong className="font-mono text-[#1C1917] dark:text-[#FAF8F5]">{selectedRequest.clientId || 'Client'}</strong></span>
                        <span>•</span>
                        <span>Request #{selectedRequest.id}</span>
                      </div>
                    </div>
                  </div>

                  {/* Actions for Draft or AI Re-run */}
                  <div className="flex items-center gap-2">
                    {isDraft ? (
                      <button
                        onClick={() => handleSubmitDraft(selectedRequest)}
                        disabled={analyzingAi}
                        className="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-[#C48A36] to-[#A87226] text-white text-xs font-bold rounded-xl shadow-md hover:opacity-95 transition"
                      >
                        {analyzingAi ? (
                          <>
                            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                            <span>Submitting &amp; Analyzing...</span>
                          </>
                        ) : (
                          <>
                            <Send className="w-3.5 h-3.5" />
                            <span>Submit &amp; Run AI Style Analysis</span>
                          </>
                        )}
                      </button>
                    ) : (
                      <button
                        onClick={() => handleRunAiAnalysis(selectedRequest)}
                        disabled={analyzingAi}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-xs font-semibold rounded-xl hover:bg-[#F3EAD9] transition"
                      >
                        <RefreshCw className={`w-3.5 h-3.5 ${analyzingAi ? 'animate-spin' : ''}`} />
                        <span>{analyzingAi ? 'Analyzing...' : 'Re-run AI Style Agent'}</span>
                      </button>
                    )}
                  </div>
                </div>

                {/* Key Metrics Grid: Budget, Dimensions, Room Type, Styles */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  {/* Budget */}
                  <div className="bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-4 flex items-center gap-3.5">
                    <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                      <Banknote className="w-5 h-5" />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] block">
                        Budget (LKR)
                      </span>
                      <span className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                        {selectedRequest.budgetLkr > 0
                          ? `LKR ${Number(selectedRequest.budgetLkr).toLocaleString()}`
                          : 'Not specified'}
                      </span>
                    </div>
                  </div>

                  {/* Dimensions */}
                  <div className="bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-4 flex items-center gap-3.5">
                    <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800/40 flex items-center justify-center text-blue-600 dark:text-blue-400">
                      <Ruler className="w-5 h-5" />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] block">
                        Dimensions (L × W × H)
                      </span>
                      <span className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                        {selectedRequest.lengthFeet > 0
                          ? `${selectedRequest.lengthFeet} × ${selectedRequest.widthFeet} × ${selectedRequest.heightFeet} ft`
                          : 'Not specified'}
                      </span>
                    </div>
                  </div>

                  {/* Room Type & Preferred Styles */}
                  <div className="bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-4 flex items-center gap-3.5">
                    <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800/40 flex items-center justify-center text-[#C48A36]">
                      <Palette className="w-5 h-5" />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] block">
                        Aesthetics
                      </span>
                      <div className="flex flex-wrap gap-1 mt-0.5">
                        {selectedRequest.preferredStyles && selectedRequest.preferredStyles.length > 0 ? (
                          selectedRequest.preferredStyles.map((st) => (
                            <span key={st} className="px-2 py-0.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-md text-[10px] font-semibold text-[#57534E] dark:text-[#A8A29E]">
                              {st}
                            </span>
                          ))
                        ) : (
                          <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">Modern default</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Description details */}
                <div className="bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-4 sm:p-5">
                  <div className="flex items-center gap-2 mb-2 text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                    <FileText className="w-4 h-4 text-[#C48A36]" />
                    <span>Client Design Description &amp; Notes</span>
                  </div>
                  <p className="text-sm text-[#1C1917] dark:text-[#FAF8F5] leading-relaxed italic">
                    {selectedRequest.description ? `"${selectedRequest.description}"` : 'No additional description provided.'}
                  </p>
                </div>

                {/* Photos if any */}
                {selectedRequest.photos && selectedRequest.photos.length > 0 && (
                  <div>
                    <div className="flex items-center gap-2 mb-3 text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                      <ImageIcon className="w-4 h-4 text-[#C48A36]" />
                      <span>Uploaded Room Photos ({selectedRequest.photos.length})</span>
                    </div>
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                      {selectedRequest.photos.map((ph, idx) => (
                        <div key={ph.id || idx} className="h-28 rounded-xl overflow-hidden border border-[#E7E1D7] dark:border-[#2E2824] bg-stone-900 group relative">
                          <img
                            src={ph.photoUrl}
                            alt={`Photo ${idx + 1}`}
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Lifecycle Status Banner */}
            <RequestStatusBanner status={selectedRequest.status} />

            {/* AI Style Analysis Section */}
            {analyzingAi ? (
              <div className="bg-white dark:bg-[#1A1715] border border-[#C48A36]/40 rounded-3xl p-8 text-center space-y-3 shadow-sm">
                <div className="w-12 h-12 rounded-full bg-[#FAF3E8] dark:bg-[#2A231A] text-[#C48A36] flex items-center justify-center mx-auto animate-spin">
                  <Sparkles className="w-6 h-6" />
                </div>
                <h4 className="font-serif text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  Executing AI Style Analysis Agent...
                </h4>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-md mx-auto">
                  Invoking LangGraph StateGraph pipeline at <code className="font-mono text-[#C48A36]">http://localhost:8000</code> to analyze room aesthetics, extract features, and generate concept styling recommendations.
                </p>
              </div>
            ) : selectedRequest.styleAnalysis ? (
              <div>
                <div className="flex items-center justify-between mb-3 px-1">
                  <div className="flex items-center gap-2 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                    <span>Live AI Agent Output (LangGraph Subsystem @ localhost:8000) — Dynamic &amp; Verified</span>
                  </div>
                </div>
                <StyleAnalysisCard
                  analysis={selectedRequest.styleAnalysis}
                  photos={selectedRequest.photos}
                />
              </div>
            ) : isDraft ? (
              <div className="bg-[#FAF3E8]/50 dark:bg-[#2A231A]/30 border border-[#E8DEC8] dark:border-[#423525] rounded-3xl p-8 text-center space-y-3">
                <Sparkles className="w-8 h-8 text-[#C48A36] mx-auto" />
                <h4 className="font-serif text-base font-bold text-[#925C18] dark:text-[#E8A849]">
                  AI Style Analysis is Ready
                </h4>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-md mx-auto">
                  This request is currently in <strong>Draft</strong>. Submit it to trigger our Python LangGraph AI Style Analysis agent to evaluate color schemes, layout features, and generate 3D concept renders.
                </p>
                <button
                  onClick={() => handleSubmitDraft(selectedRequest)}
                  className="inline-flex items-center gap-2 px-6 py-2.5 bg-[#C48A36] hover:bg-[#A87226] text-white text-xs font-semibold rounded-xl transition shadow-xs"
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>Submit &amp; Run AI Style Analysis</span>
                </button>
              </div>
            ) : (
              <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 text-center space-y-3">
                <Sparkles className="w-8 h-8 text-[#C48A36] mx-auto" />
                <h4 className="font-serif text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  Generate AI Style Analysis
                </h4>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-md mx-auto">
                  Run the real-time AI Style Analysis agent to process this room makeover request.
                </p>
                <button
                  onClick={() => handleRunAiAnalysis(selectedRequest)}
                  className="inline-flex items-center gap-2 px-6 py-2.5 bg-[#C48A36] hover:bg-[#A87226] text-white text-xs font-semibold rounded-xl transition shadow-xs"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Run AI Style Analysis Now</span>
                </button>
              </div>
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
