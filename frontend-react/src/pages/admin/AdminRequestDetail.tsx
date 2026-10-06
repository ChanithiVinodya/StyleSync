import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useRequestDetail, usePalettePresets } from '../../features/requests/hooks';
import { StatusTimeline } from '../../features/requests/components/StatusTimeline';
import { requestApi, ApiError } from '../../features/requests/api';
import { ArrowLeft, Flag, Image as ImageIcon, Copy, Check, ChevronLeft, ChevronRight, X, AlertTriangle, XOctagon, MoreHorizontal } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const AdminRequestDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { data: request, loading, error, refetch } = useRequestDetail(id!);
  const { data: presets } = usePalettePresets();

  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [copiedHex, setCopiedHex] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  
  // Actions
  const [menuOpen, setMenuOpen] = useState(false);
  const [modalType, setModalType] = useState<'cancel' | 'flag' | null>(null);
  const [reason, setReason] = useState('');
  const [actionPending, setActionPending] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Lightbox keyboard controls
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (lightboxIndex === null) return;
      if (e.key === 'Escape') setLightboxIndex(null);
      if (e.key === 'ArrowRight' && request?.moodboards) {
        setLightboxIndex((prev) => (prev! + 1) % request.moodboards.length);
      }
      if (e.key === 'ArrowLeft' && request?.moodboards) {
        setLightboxIndex((prev) => (prev! - 1 + request.moodboards.length) % request.moodboards.length);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [lightboxIndex, request]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] p-10 flex justify-center items-center">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  if (error?.status === 404 || (!request && !loading)) {
    return (
      <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] p-10 flex flex-col items-center justify-center text-[#1C1917] dark:text-[#FAF8F5]">
        <h1 className="text-3xl font-serif font-bold mb-4">Request not found</h1>
        <Link to="/admin/requests" className="text-amber-600 hover:underline">Back to all requests</Link>
      </div>
    );
  }

  if (!request) return null;

  const formatCurrency = (val: number) => new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR' }).format(val);
  const formatDate = (val: string) => new Date(val).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });

  const getLuminance = (hex: string) => {
    const r = parseInt(hex.slice(1, 3), 16) / 255;
    const g = parseInt(hex.slice(3, 5), 16) / 255;
    const b = parseInt(hex.slice(5, 7), 16) / 255;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };

  const copyToClipboard = async (hex: string) => {
    try {
      await navigator.clipboard.writeText(hex);
      setCopiedHex(hex);
      setTimeout(() => setCopiedHex(null), 2000);
    } catch {
      // Ignore clipboard errors silently
    }
  };

  let paletteSourceText = 'No colours chosen';
  if (request.paletteMode === 'Preset' && request.palettePresetId) {
    const presetName = presets?.find(p => p.id === request.palettePresetId)?.name || request.palettePresetId;
    paletteSourceText = `Preset: ${presetName}`;
  } else if (request.paletteMode === 'Generated' && request.paletteBaseHex) {
    paletteSourceText = `Generated from ${request.paletteBaseHex}`;
  }

  const handleActionSubmit = async () => {
    if (reason.length < 5 || reason.length > 500) return;
    setActionPending(true);
    setActionError(null);
    try {
      if (modalType === 'cancel') {
        await requestApi.cancelRequest(request.id, reason);
        setToast('Request cancelled successfully');
      } else if (modalType === 'flag') {
        await requestApi.flagRequest(request.id, reason, !request.isFlagged);
        setToast(request.isFlagged ? 'Flag removed successfully' : 'Request flagged successfully');
      }
      setModalType(null);
      setReason('');
      await refetch();
      setTimeout(() => setToast(null), 3000);
    } catch (err) {
      if (err instanceof ApiError) {
        setActionError(err.problem.detail || err.problem.title || 'Action failed');
      } else {
        setActionError('An unexpected error occurred');
      }
    } finally {
      setActionPending(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10 font-sans relative">
      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 bg-gray-900 text-white px-4 py-2 rounded-lg shadow-lg text-sm transition-opacity">
          {toast}
        </div>
      )}
      <div className="max-w-5xl mx-auto space-y-6">
        
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <div className="flex items-center gap-3">
                <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  {request.referenceCode}
                </h1>
                <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525]">
                  {request.status}
                </span>
                {request.isFlagged && (
                  <span className="flex items-center gap-1 px-2 py-1 text-xs font-semibold rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900">
                    <Flag size={12} className="fill-rose-500" /> Flagged
                  </span>
                )}
              </div>
              <p className="text-sm text-[#57534E] dark:text-[#A8A29E] mt-1">
                Client: <strong>{request.clientId}</strong> &bull; Created: {formatDate(request.createdAt)}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link to="/admin/requests" className="flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition">
              <ArrowLeft size={14} /> Back
            </Link>
            
            {/* Actions Menu */}
            <div className="relative">
              <button 
                data-testid="actions-menu-btn"
                onClick={() => setMenuOpen(!menuOpen)} 
                className="flex items-center justify-center p-2 text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition"
              >
                <MoreHorizontal size={18} />
              </button>
              {menuOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl shadow-lg z-10 overflow-hidden text-sm">
                  <button 
                    onClick={() => { setModalType('flag'); setReason(''); setActionError(null); setMenuOpen(false); }}
                    className="w-full text-left px-4 py-3 hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition flex items-center gap-2"
                  >
                    <AlertTriangle size={14} className={request.isFlagged ? "text-amber-500" : ""} /> 
                    {request.isFlagged ? "Remove flag" : "Flag as invalid"}
                  </button>
                  {request.status === 'AwaitingApproval' && (
                    <button 
                      onClick={async () => { 
                        setMenuOpen(false);
                        try {
                          await requestApi.approveRequest(request.id);
                          setToast('Request approved successfully');
                          refetch();
                        } catch (err) {
                          alert('Failed to approve request');
                        }
                      }}
                      className="w-full text-left px-4 py-3 hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition flex items-center gap-2 border-t border-[#E7E1D7] dark:border-[#2E2824] text-green-600 dark:text-green-500"
                    >
                      <Check size={14} /> Approve Request
                    </button>
                  )}
                  {(request.status === 'DesignerAssigned' || request.status === 'Approved') && (
                    <button 
                      onClick={async () => { 
                        setMenuOpen(false);
                        try {
                          await requestApi.startExecution(request.id);
                          setToast('Project execution started! Status is now In Progress.');
                          refetch();
                        } catch (err) {
                          alert('Failed to start project execution');
                        }
                      }}
                      className="w-full text-left px-4 py-3 hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition flex items-center gap-2 border-t border-[#E7E1D7] dark:border-[#2E2824] text-amber-600 dark:text-amber-500 font-semibold"
                    >
                      <Check size={14} /> Start Execution (In Progress)
                    </button>
                  )}
                  {/* Hide cancel if Completed, Rejected, or Cancelled */}
                  {!['Completed', 'Rejected', 'Cancelled'].includes(request.status) && (
                    <button 
                      onClick={() => { setModalType('cancel'); setReason(''); setActionError(null); setMenuOpen(false); }}
                      className="w-full text-left px-4 py-3 hover:bg-rose-50 dark:hover:bg-rose-950/50 text-rose-600 dark:text-rose-400 transition flex items-center gap-2 border-t border-[#E7E1D7] dark:border-[#2E2824]"
                    >
                      <XOctagon size={14} /> Cancel request
                    </button>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            
            {/* Room Photo & Details */}
            <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs flex flex-col md:flex-row gap-6">
              <div className="w-full md:w-1/2 space-y-2">
                <div className="w-full aspect-video bg-gray-100 dark:bg-gray-800 rounded-2xl overflow-hidden flex items-center justify-center border border-[#E7E1D7] dark:border-[#2E2824]">
                  {request.roomPhotoUrl ? (
                    <img src={request.roomPhotoUrl} alt="Current room" className="w-full h-full object-cover" onError={(e) => { e.currentTarget.style.display = 'none'; e.currentTarget.nextElementSibling?.classList.remove('hidden'); }} />
                  ) : (
                    <div className="text-gray-400 flex flex-col items-center"><ImageIcon size={32}/><span className="text-xs mt-2">No photo</span></div>
                  )}
                  <div className="hidden text-gray-400 flex flex-col items-center"><ImageIcon size={32}/><span className="text-xs mt-2">Failed to load</span></div>
                </div>
                <p className="text-center text-xs font-medium text-[#78716C]">Current room</p>
              </div>
              
              <div className="w-full md:w-1/2 space-y-4">
                <h2 className="text-lg font-serif font-bold">Request Details</h2>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-[#78716C] mb-0.5">Room Type</p>
                    <p className="font-semibold">{request.roomType}</p>
                  </div>
                  <div>
                    <p className="text-[#78716C] mb-0.5">Size</p>
                    <p className="font-semibold">{request.roomSizeSqFt} sq ft</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-[#78716C] mb-0.5">Budget</p>
                    <p className="font-semibold text-amber-600 dark:text-amber-500">{formatCurrency(request.budget)}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-[#78716C] mb-0.5">Description</p>
                    <p className="whitespace-pre-wrap">{request.description}</p>
                  </div>
                  {request.designerDisplayName && (
                    <div className="col-span-2 pt-3 border-t border-[#E7E1D7] dark:border-[#2E2824]">
                      <div className="flex items-center justify-between mb-1">
                        <p className="text-[#78716C] text-xs font-semibold uppercase tracking-wider">
                          {['DesignerAssigned', 'InProgress', 'Completed'].includes(request.status) 
                            ? 'Assigned Designer' 
                            : 'Recommended Designer (AI Match)'}
                        </p>
                        {!['DesignerAssigned', 'InProgress', 'Completed'].includes(request.status) && (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 font-medium">
                            Pending Approval
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-3 p-2.5 rounded-xl bg-[#FAF8F5] dark:bg-[#141210] border border-[#E7E1D7] dark:border-[#2E2824]">
                        <div className="w-8 h-8 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-700 dark:text-amber-400 flex items-center justify-center font-bold text-xs">
                          {request.designerDisplayName.charAt(0)}
                        </div>
                        <div>
                          <p className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">{request.designerDisplayName}</p>
                          {request.designerEmail && (
                            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">{request.designerEmail}</p>
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Preferred Colours */}
            <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs">
              <h2 className="text-lg font-serif font-bold mb-4">Preferred Colours</h2>
              {request.palette && request.palette.length > 0 ? (
                <div className="space-y-4">
                  <div className="flex flex-wrap gap-3">
                    {[...request.palette].sort((a,b) => a.position - b.position).map(c => {
                      const isLight = getLuminance(c.hex) > 0.5;
                      const isCopied = copiedHex === c.hex;
                      return (
                        <button
                          key={c.hex}
                          onClick={() => copyToClipboard(c.hex)}
                          className="w-24 h-24 rounded-2xl flex flex-col items-center justify-center shadow-sm border border-black/5 hover:scale-105 transition-transform relative group"
                          style={{ backgroundColor: c.hex }}
                        >
                          <span className={`text-xs font-bold uppercase ${isLight ? 'text-black/70' : 'text-white/90'}`}>
                            {c.hex}
                          </span>
                          <div className={`absolute inset-0 bg-black/20 rounded-2xl flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity ${isLight ? 'text-black' : 'text-white'}`}>
                            {isCopied ? <Check size={20} /> : <Copy size={20} />}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                  <p className="text-sm text-[#78716C]">
                    {paletteSourceText}
                  </p>
                </div>
              ) : (
                <p className="text-sm text-[#78716C]">{paletteSourceText}</p>
              )}
            </div>

            {/* Moodboard Gallery */}
            <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs">
              <h2 className="text-lg font-serif font-bold mb-4">Moodboard Gallery</h2>
              {request.moodboards && request.moodboards.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
                  {[...request.moodboards].sort((a,b) => a.sortOrder - b.sortOrder).map((img, idx) => (
                    <button
                      key={img.id}
                      onClick={() => setLightboxIndex(idx)}
                      className="aspect-square bg-gray-100 dark:bg-gray-800 rounded-xl overflow-hidden hover:opacity-80 transition focus:outline-none focus:ring-2 focus:ring-amber-500"
                    >
                      <img src={img.url} alt={`Moodboard ${idx + 1}`} className="w-full h-full object-cover" />
                    </button>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-[#78716C]">No moodboard images uploaded.</p>
              )}
            </div>
            
          </div>
          
          {/* Sidebar - Timeline */}
          <div className="space-y-6">
            <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs">
              <h2 className="text-lg font-serif font-bold mb-2">Workflow Status</h2>
              <div className="flex items-center gap-2 mb-6">
                <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525]">
                  {request.status}
                </span>
                <span className="text-sm text-[#78716C]">Current stage</span>
              </div>
              <StatusTimeline history={request.statusHistory || (request as any).statusHistories || []} currentStatus={request.status} />
              
              {/* Stored Reasons */}
              {(request.cancelReason || request.flagReason) && (
                <div className="mt-6 space-y-3 pt-6 border-t border-[#E7E1D7] dark:border-[#2E2824]">
                  {request.cancelReason && (
                    <div>
                      <p className="text-[11px] font-bold text-[#78716C] uppercase mb-1">Cancel Reason</p>
                      <p className="text-sm text-rose-700 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/30 p-2 rounded-lg border border-rose-100 dark:border-rose-900/50">
                        {request.cancelReason}
                      </p>
                    </div>
                  )}
                  {request.flagReason && (
                    <div>
                      <p className="text-[11px] font-bold text-[#78716C] uppercase mb-1">Flag Reason</p>
                      <p className="text-sm text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/30 p-2 rounded-lg border border-amber-100 dark:border-amber-900/50">
                        {request.flagReason}
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Review Proposal Button */}
            {request.status === 'AwaitingApproval' && (
              <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs text-center">
                <h3 className="text-md font-bold mb-2">Proposal is ready</h3>
                <div className="group relative inline-block">
                  <button disabled className="px-4 py-2 w-full bg-amber-500 text-white font-bold rounded-xl opacity-50 cursor-not-allowed">
                    Review Proposal
                  </button>
                  <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover:block w-48 p-2 bg-black text-white text-xs rounded text-center z-10">
                    Stage 1 review is provided by Component 3
                  </div>
                </div>
              </div>
            )}

            {/* Start Execution Button when Designer is Assigned */}
            {(request.status === 'DesignerAssigned' || request.status === 'Approved') && (
              <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 shadow-xs text-center space-y-3">
                <div>
                  <h3 className="text-md font-bold">Designer Assigned</h3>
                  <p className="text-xs text-[#78716C] mt-1">Proposal &amp; Quote approved. Start project execution to move this request to In Progress.</p>
                </div>
                <button
                  onClick={async () => {
                    try {
                      await requestApi.startExecution(request.id);
                      setToast('Project execution started! Status is now In Progress.');
                      refetch();
                    } catch {
                      alert('Failed to start execution');
                    }
                  }}
                  className="w-full py-2.5 px-4 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-white font-bold rounded-xl shadow-md transition flex items-center justify-center gap-2 text-sm"
                >
                  <Check size={16} /> Start Project Execution
                </button>
              </div>
            )}
          </div>
          
        </div>
      </div>

      {/* Lightbox */}
      {lightboxIndex !== null && request?.moodboards && (
        <div 
          className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center focus:outline-none"
          role="dialog"
          aria-modal="true"
          aria-label="Image lightbox"
          tabIndex={-1}
        >
          <button 
            onClick={() => setLightboxIndex(null)}
            className="absolute top-4 right-4 text-white/70 hover:text-white p-2 focus:outline-none focus:ring-2 focus:ring-white rounded"
            aria-label="Close"
          >
            <X size={32} />
          </button>
          
          <button 
            onClick={() => setLightboxIndex((prev) => (prev! - 1 + request.moodboards.length) % request.moodboards.length)}
            className="absolute left-4 top-1/2 -translate-y-1/2 text-white/70 hover:text-white p-2 focus:outline-none focus:ring-2 focus:ring-white rounded"
            aria-label="Previous"
          >
            <ChevronLeft size={48} />
          </button>
          
          <img 
            src={request.moodboards.sort((a,b) => a.sortOrder - b.sortOrder)[lightboxIndex].url} 
            alt={`Moodboard ${lightboxIndex + 1}`} 
            className="max-h-[85vh] max-w-[85vw] object-contain rounded-lg" 
          />
          
          <button 
            onClick={() => setLightboxIndex((prev) => (prev! + 1) % request.moodboards.length)}
            className="absolute right-4 top-1/2 -translate-y-1/2 text-white/70 hover:text-white p-2 focus:outline-none focus:ring-2 focus:ring-white rounded"
            aria-label="Next"
          >
            <ChevronRight size={48} />
          </button>
        </div>
      )}

      {/* Action Modal */}
      {modalType && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white dark:bg-[#1A1715] rounded-3xl p-6 shadow-xl w-full max-w-md border border-[#E7E1D7] dark:border-[#2E2824]">
            <h2 className="text-xl font-serif font-bold mb-2">
              {modalType === 'cancel' ? 'Cancel Request' : (request.isFlagged ? 'Remove Flag' : 'Flag Request')}
            </h2>
            
            {modalType === 'cancel' && (
              <p className="text-sm text-rose-600 dark:text-rose-400 mb-4 font-medium flex items-start gap-2">
                <AlertTriangle size={16} className="shrink-0 mt-0.5" />
                Warning: Cancelling a request cannot be undone. It terminates all active work and notifies the client.
              </p>
            )}

            {actionError && (
              <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded-xl text-sm border border-red-100 dark:border-red-900/50">
                {actionError}
              </div>
            )}

            <div className="space-y-1 mb-6">
              <label className="text-sm font-semibold text-[#57534E] dark:text-[#A8A29E]">Reason (required)</label>
              <textarea
                value={reason}
                onChange={e => setReason(e.target.value)}
                placeholder="Explain the reason..."
                className="w-full h-32 p-3 bg-transparent border border-[#D9D2C7] dark:border-[#3E3834] rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500 resize-none text-sm"
              />
              <div className="flex justify-end">
                <span className={`text-xs ${reason.length < 5 || reason.length > 500 ? 'text-rose-500' : 'text-[#78716C]'}`}>
                  {reason.length} / 500
                </span>
              </div>
            </div>

            <div className="flex justify-end gap-3">
              <button 
                onClick={() => setModalType(null)} 
                disabled={actionPending}
                className="px-4 py-2 text-sm font-semibold text-[#57534E] dark:text-[#A8A29E] hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition"
              >
                Close
              </button>
              <button 
                onClick={handleActionSubmit}
                disabled={actionPending || reason.length < 5 || reason.length > 500}
                className={`px-4 py-2 text-sm font-semibold text-white rounded-xl transition flex items-center justify-center gap-2 ${
                  modalType === 'cancel' 
                    ? 'bg-rose-600 hover:bg-rose-700 disabled:bg-rose-300 dark:disabled:bg-rose-900' 
                    : 'bg-amber-600 hover:bg-amber-700 disabled:bg-amber-300 dark:disabled:bg-amber-900'
                }`}
              >
                {actionPending && <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />}
                Confirm
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
