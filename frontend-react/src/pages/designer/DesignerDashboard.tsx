import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { fetchAllRequests, ProjectRequest } from '../../services/api';
import {
  Palette,
  LogOut,
  Sparkles,
  FileText,
  Hammer,
  ArrowRight,
  Clock,
  CheckCircle2,
  Calendar,
  Layers,
  Search,
  Eye,
  SlidersHorizontal
} from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const DesignerDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const [requests, setRequests] = useState<ProjectRequest[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [filterStatus, setFilterStatus] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');

  useEffect(() => {
    setIsLoading(true);
    fetchAllRequests()
      .then((data) => setRequests(data))
      .catch((err) => console.error('Failed to load designer requests', err))
      .finally(() => setIsLoading(false));
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'ProposalReady':
      case 'Approved':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 text-xs font-semibold rounded-full">
            <CheckCircle2 className="w-3.5 h-3.5" />
            {status}
          </span>
        );
      case 'Submitted':
      case 'UnderReview':
      case 'AIAnalysis':
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 bg-blue-50 dark:bg-blue-950/60 text-blue-800 dark:text-blue-300 border border-blue-200 dark:border-blue-800 text-xs font-semibold rounded-full">
            <Clock className="w-3.5 h-3.5" />
            {status}
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-3 py-1 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-xs font-semibold rounded-full">
            <Layers className="w-3.5 h-3.5" />
            {status || 'Draft'}
          </span>
        );
    }
  };

  const filteredRequests = requests.filter((r) => {
    const matchesFilter = filterStatus === 'All' || r.status === filterStatus;
    const query = searchQuery.toLowerCase();
    const matchesSearch =
      !searchQuery ||
      r.roomType.toLowerCase().includes(query) ||
      (r.description && r.description.toLowerCase().includes(query)) ||
      (r.preferredStyles && r.preferredStyles.some((s) => s.toLowerCase().includes(query)));
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10 transition-colors">
      <div className="max-w-6xl mx-auto space-y-8">

        {/* Navigation / Header */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E7E1D7] dark:border-[#2E2824] pb-6">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Designer Studio Workspace</h1>
                <span className="px-2.5 py-0.5 bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-800 text-[10px] font-bold uppercase rounded-full">
                  Designer
                </span>
              </div>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">Welcome back, {user?.name}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link
              to="/project-requests"
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-white bg-[#C48A36] hover:bg-[#A87226] rounded-xl transition shadow-xs"
            >
              <SlidersHorizontal className="w-4 h-4" />
              <span>Makeover Console</span>
            </Link>
            <button
              onClick={logout}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition shadow-2xs"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </button>
          </div>
        </header>

        {/* Designer Hub Quick Action Cards */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <Link
            to="/project-requests"
            className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl hover:border-[#C48A36] dark:hover:border-[#C48A36] transition shadow-2xs group flex flex-col justify-between h-36"
          >
            <div>
              <div className="w-9 h-9 rounded-xl bg-amber-50 dark:bg-amber-950/50 flex items-center justify-center text-[#C48A36] mb-3 group-hover:scale-105 transition-transform">
                <Sparkles className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">Review AI Analyses</h3>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">Inspect client room photos & styles</p>
            </div>
            <div className="flex items-center text-xs font-medium text-[#C48A36] gap-1 group-hover:translate-x-0.5 transition-transform">
              <span>Open Staff Console</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </div>
          </Link>

          <Link
            to="/quotes-contracts"
            className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl hover:border-[#C48A36] dark:hover:border-[#C48A36] transition shadow-2xs group flex flex-col justify-between h-36"
          >
            <div>
              <div className="w-9 h-9 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 flex items-center justify-center text-emerald-600 dark:text-emerald-400 mb-3 group-hover:scale-105 transition-transform">
                <FileText className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">Draft Proposals</h3>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">Generate estimates & itemized quotes</p>
            </div>
            <div className="flex items-center text-xs font-medium text-emerald-600 dark:text-emerald-400 gap-1 group-hover:translate-x-0.5 transition-transform">
              <span>Prepare Quotes</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </div>
          </Link>

          <Link
            to="/project-execution"
            className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl hover:border-[#C48A36] dark:hover:border-[#C48A36] transition shadow-2xs group flex flex-col justify-between h-36"
          >
            <div>
              <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-950/50 flex items-center justify-center text-blue-600 dark:text-blue-400 mb-3 group-hover:scale-105 transition-transform">
                <Hammer className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">Project Milestones</h3>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">Manage renovation tasks & timelines</p>
            </div>
            <div className="flex items-center text-xs font-medium text-blue-600 dark:text-blue-400 gap-1 group-hover:translate-x-0.5 transition-transform">
              <span>View Tasks</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </div>
          </Link>

          <Link
            to="/designers"
            className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl hover:border-[#C48A36] dark:hover:border-[#C48A36] transition shadow-2xs group flex flex-col justify-between h-36"
          >
            <div>
              <div className="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-950/50 flex items-center justify-center text-purple-600 dark:text-purple-400 mb-3 group-hover:scale-105 transition-transform">
                <Palette className="w-5 h-5" />
              </div>
              <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">Public Profile</h3>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">View your marketplace portfolio</p>
            </div>
            <div className="flex items-center text-xs font-medium text-purple-600 dark:text-purple-400 gap-1 group-hover:translate-x-0.5 transition-transform">
              <span>View Portfolio</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </div>
          </Link>
        </section>

        {/* Requests Feed Section */}
        <section className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8 shadow-xs space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#C48A36]">
                <Palette className="w-5 h-5" />
              </div>
              <div>
                <h2 className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                  Incoming &amp; Assigned Makeover Requests
                </h2>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                  Client requests awaiting your review, style validation, and proposal creation
                </p>
              </div>
            </div>

            {/* Filter and Search Bar */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="relative">
                <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-[#78716C]" />
                <input
                  type="text"
                  placeholder="Filter requests..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-8 pr-3 py-1.5 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36]"
                />
              </div>

              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-1.5 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36]"
              >
                <option value="All">All Statuses</option>
                <option value="Submitted">Submitted</option>
                <option value="ProposalReady">Proposal Ready</option>
                <option value="Approved">Approved</option>
                <option value="Draft">Draft</option>
              </select>
            </div>
          </div>

          {isLoading ? (
            <div className="py-12 flex flex-col items-center justify-center gap-3 text-[#78716C]">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-[#C48A36] border-t-transparent" />
              <p className="text-xs">Loading requests from clients...</p>
            </div>
          ) : filteredRequests.length === 0 ? (
            <div className="py-12 text-center border-2 border-dashed border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl space-y-3">
              <Palette className="w-10 h-10 mx-auto text-[#C48A36]/60" />
              <div className="space-y-1">
                <h3 className="text-sm font-semibold text-[#1C1917] dark:text-[#FAF8F5]">No matching client requests found</h3>
                <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-sm mx-auto">
                  When clients submit room makeover requests, they will appear here with photos and calculated AI style recommendations.
                </p>
              </div>
              <Link
                to="/project-requests"
                className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-white bg-[#C48A36] hover:bg-[#A87226] rounded-xl transition shadow-xs"
              >
                <span>Open Project Requests Console</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredRequests.map((r) => (
                <div
                  key={r.id}
                  className="p-5 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl flex flex-col justify-between gap-4 hover:border-[#C48A36]/50 transition"
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <h3 className="font-serif font-bold text-base text-[#1C1917] dark:text-[#FAF8F5]">
                          {r.roomType}
                        </h3>
                        <span className="text-[10px] text-[#78716C] dark:text-[#A8A29E] px-2 py-0.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-md">
                          Client: {r.clientId || 'Client'}
                        </span>
                      </div>
                      {getStatusBadge(r.status)}
                    </div>

                    <p className="text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-2">
                      {r.description || 'No description provided.'}
                    </p>

                    <div className="grid grid-cols-2 gap-2 pt-2 text-xs text-[#78716C] dark:text-[#A8A29E]">
                      <div>
                        <span className="font-medium text-[#1C1917] dark:text-[#FAF8F5]">Room Size: </span>
                        {r.lengthFeet} × {r.widthFeet} × {r.heightFeet} ft
                      </div>
                      <div>
                        <span className="font-medium text-[#1C1917] dark:text-[#FAF8F5]">Budget: </span>
                        LKR {r.budgetLkr?.toLocaleString() || 'N/A'}
                      </div>
                    </div>

                    {/* Preferred Styles Badges */}
                    {r.preferredStyles && r.preferredStyles.length > 0 && (
                      <div className="flex flex-wrap gap-1 pt-1">
                        {r.preferredStyles.map((style, idx) => (
                          <span
                            key={idx}
                            className="px-2 py-0.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] text-[10px] rounded-md text-[#57534E] dark:text-[#A8A29E]"
                          >
                            {style}
                          </span>
                        ))}
                      </div>
                    )}

                    {/* AI Analysis Preview Card */}
                    {r.styleAnalysis ? (
                      <div className="mt-3 p-3 bg-white dark:bg-[#1A1715] border border-amber-200/60 dark:border-amber-900/40 rounded-xl space-y-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-semibold text-amber-700 dark:text-amber-400 flex items-center gap-1">
                            <Sparkles className="w-3.5 h-3.5" />
                            AI Recommendation: {r.styleAnalysis.primaryStyle}
                          </span>
                          <span className="text-[11px] font-bold text-emerald-600 dark:text-emerald-400">
                            {r.styleAnalysis.confidenceScore}% Score
                          </span>
                        </div>
                        <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E] line-clamp-2">
                          {r.styleAnalysis.analysisSummary}
                        </p>
                      </div>
                    ) : (
                      <div className="mt-3 p-2.5 bg-white dark:bg-[#1A1715] border border-dashed border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-center">
                        <span className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
                          AI Style Analysis not yet triggered
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="pt-2 border-t border-[#E7E1D7] dark:border-[#2E2824] flex items-center justify-between text-xs">
                    <span className="text-[#A8A29E] flex items-center gap-1 text-[11px]">
                      <Calendar className="w-3.5 h-3.5" />
                      {new Date(r.createdAt).toLocaleDateString()}
                    </span>
                    <div className="flex items-center gap-3">
                      <Link
                        to="/quotes-contracts"
                        className="font-medium text-emerald-600 dark:text-emerald-400 hover:underline inline-flex items-center gap-1 text-[11px]"
                      >
                        <FileText className="w-3 h-3" />
                        <span>Create Quote</span>
                      </Link>
                      <Link
                        to="/project-requests"
                        className="font-medium text-[#C48A36] hover:underline inline-flex items-center gap-1"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>Inspect in Console</span>
                      </Link>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

      </div>
    </div>
  );
};
