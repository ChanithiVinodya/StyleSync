import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, 
  ShieldAlert, 
  Sliders, 
  Search, 
  Save, 
  CheckCircle2, 
  AlertCircle, 
  ArrowLeft, 
  Layers, 
  RefreshCw, 
  Lock,
  Sparkles,
  Users
} from 'lucide-react';
import { DesignerProfile, ListingStatus } from '../types';
import { designerApi } from '../services/designerApi';

interface AdminDesignerGovernancePageProps {
  userRole?: string; // Sourced from existing auth context
  onBack?: () => void;
  onRoleChange?: (newRole: string) => void;
}

export const AdminDesignerGovernancePage: React.FC<AdminDesignerGovernancePageProps> = ({
  userRole = 'admin',
  onBack,
  onRoleChange
}) => {
  const [currentRole, setCurrentRole] = useState<string>(userRole);
  const [profiles, setProfiles] = useState<DesignerProfile[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [editingCapacity, setEditingCapacity] = useState<{ [designerId: number]: number }>({});
  const [editingStatus, setEditingStatus] = useState<{ [designerId: number]: ListingStatus }>({});
  const [savingId, setSavingId] = useState<number | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Sync prop changes
  useEffect(() => {
    setCurrentRole(userRole);
  }, [userRole]);

  // Load all designer profiles (including un-published)
  const loadProfiles = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await designerApi.getAllProfiles();
      setProfiles(data);
      // Initialize edit states
      const initialCapacity: { [id: number]: number } = {};
      const initialStatus: { [id: number]: ListingStatus } = {};
      data.forEach(p => {
        initialCapacity[p.id] = p.maxConcurrentProjects;
        initialStatus[p.id] = p.listingStatus;
      });
      setEditingCapacity(initialCapacity);
      setEditingStatus(initialStatus);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to load designer records';
      setErrorMessage(msg);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (currentRole === 'admin') {
      loadProfiles();
    }
  }, [currentRole]);

  const handleSaveOverride = async (designerId: number) => {
    const newStatus = editingStatus[designerId];
    const newCapacity = editingCapacity[designerId];

    if (newCapacity === undefined || newCapacity < 1) {
      setErrorMessage('Max concurrent projects must be at least 1.');
      return;
    }

    setSavingId(designerId);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      const updated = await designerApi.overrideListingStatusAndCapacity(
        designerId,
        newStatus,
        newCapacity
      );

      // Update local profiles list
      setProfiles(prev => prev.map(p => p.id === designerId ? updated : p));
      setSuccessMessage(`Updated ${updated.displayName}: Status set to ${ListingStatus[newStatus]}, Capacity limit overridden to ${newCapacity}.`);
      
      setTimeout(() => {
        setSuccessMessage(null);
      }, 4000);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to save admin overrides';
      setErrorMessage(msg);
    } finally {
      setSavingId(null);
    }
  };

  // Role Gate Guard: If user does not have 'admin' role
  if (currentRole !== 'admin') {
    return (
      <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] p-6 sm:p-12 flex flex-col items-center justify-center text-center space-y-6">
        <div className="w-16 h-16 rounded-full bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center shadow-inner">
          <Lock className="w-8 h-8" />
        </div>
        <div className="max-w-md space-y-2">
          <h2 className="text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
            Administrator Access Required
          </h2>
          <p className="text-sm text-[#78716C] dark:text-[#A8A29E] leading-relaxed">
            This governance screen is gated behind the <strong>Admin</strong> role. Your current active session role is <code className="px-2 py-0.5 rounded bg-[#EAE4D9] dark:bg-[#2A2420] text-xs font-mono font-bold text-[#1C1917] dark:text-[#FAF8F5]">{currentRole}</code>.
          </p>
        </div>

        {/* Role Switcher Demo Control */}
        <div className="p-4 rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] space-y-3">
          <span className="text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] block">
            Simulate Persona Session:
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => {
                setCurrentRole('admin');
                onRoleChange?.('admin');
              }}
              className="px-4 py-2 rounded-xl text-xs font-bold bg-[#925C18] text-white hover:bg-[#784A12] transition-colors cursor-pointer"
            >
              Switch to Administrator Role
            </button>
            {onBack && (
              <button
                onClick={onBack}
                className="px-4 py-2 rounded-xl text-xs font-semibold bg-[#EAE4D9] dark:bg-[#2A2420] text-[#1C1917] dark:text-[#FAF8F5] hover:bg-[#DFD8CC] transition-colors cursor-pointer"
              >
                Back to Directory
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  const filteredProfiles = profiles.filter(p =>
    p.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.styleTags.some(t => t.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] pb-24 transition-colors">
      {/* Admin Control Header */}
      <div className="bg-[#1C1917] text-[#FAF8F5] border-b border-[#2C2723] py-4 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#FAF3E8] text-[#925C18] flex items-center justify-center font-bold">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-bold">Designer Governance & Capacity Admin</h1>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                  Role: Administrator
                </span>
              </div>
              <p className="text-xs text-[#A8A29E]">
                Override studio listing statuses (Draft/Published/Suspended/Archived) and max concurrent projects
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {onBack && (
              <button
                type="button"
                onClick={onBack}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#FAF8F5] bg-[#2C2723] hover:bg-[#38312B] transition-colors cursor-pointer"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>Exit Admin</span>
              </button>
            )}
            <button
              type="button"
              onClick={loadProfiles}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#1C1917] bg-[#FAF8F5] hover:bg-[#EAE4D9] transition-colors cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Refresh</span>
            </button>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-6">
        {/* Notification Banners */}
        {successMessage && (
          <div className="p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 text-xs font-semibold flex items-center gap-2 shadow-xs animate-fadeIn">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
            <span>{successMessage}</span>
          </div>
        )}

        {errorMessage && (
          <div className="p-4 rounded-2xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 text-xs font-semibold flex items-center gap-2 shadow-xs animate-fadeIn">
            <AlertCircle className="w-4 h-4 text-red-600 dark:text-red-400 shrink-0" />
            <span>{errorMessage}</span>
          </div>
        )}

        {/* Search Bar & Filter Summary */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xs">
          <div className="relative w-full sm:w-96">
            <Search className="w-4 h-4 text-[#78716C] dark:text-[#A8A29E] absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              placeholder="Search designer by name or style tag..."
              className="w-full pl-9 pr-4 py-2 text-xs rounded-xl bg-[#F8F5F0] dark:bg-[#221D19] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
            />
          </div>

          <div className="text-xs text-[#78716C] dark:text-[#A8A29E] self-end sm:self-auto">
            Governing <strong>{filteredProfiles.length}</strong> designer records
          </div>
        </div>

        {/* Loading Spinner */}
        {isLoading ? (
          <div className="p-16 flex flex-col items-center justify-center space-y-3">
            <div className="w-8 h-8 border-3 border-[#C48A36] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">Loading designer governance table...</span>
          </div>
        ) : (
          /* Designers Governance Table / Cards */
          <div className="space-y-4">
            {filteredProfiles.map(designer => {
              const currentCapInput = editingCapacity[designer.id] ?? designer.maxConcurrentProjects;
              const currentStatusInput = editingStatus[designer.id] ?? designer.listingStatus;
              const isSaving = savingId === designer.id;

              // Compute preview flags
              const isUnderCap = designer.activeProjectCount < currentCapInput;
              const isAtCap = designer.activeProjectCount >= currentCapInput;
              const remaining = Math.max(0, currentCapInput - designer.activeProjectCount);

              const hasUnsavedChanges = 
                currentCapInput !== designer.maxConcurrentProjects || 
                currentStatusInput !== designer.listingStatus;

              return (
                <div
                  key={designer.id}
                  className={`p-5 rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border transition-all duration-200 shadow-xs ${
                    hasUnsavedChanges 
                      ? 'border-[#C48A36] dark:border-[#E8A849] ring-1 ring-[#C48A36]/40' 
                      : 'border-[#E7E1D7] dark:border-[#2C2723]'
                  }`}
                >
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
                    {/* Designer Details & Capacity Status */}
                    <div className="space-y-2 max-w-xl">
                      <div className="flex flex-wrap items-center gap-2.5">
                        <span className="text-xs font-mono font-bold text-[#78716C] dark:text-[#A8A29E] bg-[#EAE4D9] dark:bg-[#2A2420] px-2 py-0.5 rounded">
                          ID #{designer.id}
                        </span>
                        <h3 className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                          {designer.displayName}
                        </h3>

                        {/* Current Status Badge */}
                        <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                          designer.listingStatus === ListingStatus.Published
                            ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/70 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-800'
                            : designer.listingStatus === ListingStatus.Draft
                            ? 'bg-amber-100 text-amber-800 dark:bg-amber-950/70 dark:text-amber-300 border border-amber-300 dark:border-amber-800'
                            : designer.listingStatus === ListingStatus.Suspended
                            ? 'bg-rose-100 text-rose-800 dark:bg-rose-950/70 dark:text-rose-300 border border-rose-300 dark:border-rose-800'
                            : 'bg-stone-200 text-stone-700 dark:bg-stone-800 dark:text-stone-300 border border-stone-300 dark:border-stone-700'
                        }`}>
                          Current: {ListingStatus[designer.listingStatus]}
                        </span>

                        {/* Capacity Status Badge */}
                        {isAtCap ? (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-900/20 text-amber-600 dark:text-amber-400 border border-amber-500/30">
                            At Capacity ({designer.activeProjectCount}/{currentCapInput})
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30">
                            {remaining} open slot{remaining === 1 ? '' : 's'}
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-1">
                        {designer.bio || "Interior designer profile record."}
                      </p>

                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {designer.styleTags.map((t, idx) => (
                          <span key={idx} className="text-[10px] px-2 py-0.5 rounded bg-[#F0ECE1] dark:bg-[#28221D] text-[#78716C] dark:text-[#D6D3D1]">
                            {t}
                          </span>
                        ))}
                      </div>
                    </div>

                    {/* Admin Override Controls */}
                    <div className="flex flex-wrap items-center gap-4 bg-[#F8F5F0] dark:bg-[#221D19] p-3.5 rounded-xl border border-[#E7E1D7] dark:border-[#2C2723]">
                      {/* ListingStatus Control */}
                      <div className="space-y-1">
                        <label className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] block">
                          Listing Status
                        </label>
                        <select
                          value={currentStatusInput}
                          onChange={e => {
                            const newSt = parseInt(e.target.value, 10) as ListingStatus;
                            setEditingStatus(prev => ({ ...prev, [designer.id]: newSt }));
                          }}
                          className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-[#FAF8F5] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] cursor-pointer focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
                        >
                          <option value={ListingStatus.Draft}>Draft (Hidden)</option>
                          <option value={ListingStatus.Published}>Published (Active)</option>
                          <option value={ListingStatus.Suspended}>Suspended (Hidden)</option>
                          <option value={ListingStatus.Archived}>Archived (Soft Deleted)</option>
                        </select>
                      </div>

                      {/* MaxConcurrentProjects Override Control */}
                      <div className="space-y-1">
                        <label className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] block">
                          Max Projects Limit
                        </label>
                        <div className="flex items-center gap-1.5">
                          <input
                            type="number"
                            min="1"
                            max="20"
                            value={currentCapInput}
                            onChange={e => {
                              const val = Math.max(1, parseInt(e.target.value, 10) || 1);
                              setEditingCapacity(prev => ({ ...prev, [designer.id]: val }));
                            }}
                            className="w-16 px-2.5 py-1.5 text-xs font-bold rounded-lg bg-[#FAF8F5] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] text-center focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
                          />
                          <span className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
                            (Active: {designer.activeProjectCount})
                          </span>
                        </div>
                      </div>

                      {/* Save Override Action Button */}
                      <div className="self-end pt-1">
                        <button
                          type="button"
                          onClick={() => handleSaveOverride(designer.id)}
                          disabled={isSaving || !hasUnsavedChanges}
                          className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-[#1C1917] dark:bg-[#FAF8F5] text-[#FAF8F5] dark:text-[#1C1917] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] disabled:opacity-30 disabled:cursor-not-allowed transition-all cursor-pointer shadow-xs"
                        >
                          {isSaving ? (
                            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                          ) : (
                            <Save className="w-3.5 h-3.5" />
                          )}
                          <span>Save Override</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
};
