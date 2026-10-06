import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { api, User } from '../../auth/authService';
import { ShieldCheck, Users, LogOut, FileText } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';
import { RequestAnalyticsPanel } from '../../features/requests/components/RequestAnalyticsPanel';

export const AdminDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [designers, setDesigners] = useState<User[]>([]);
  const [selectedDesignerId, setSelectedDesignerId] = useState<string>('');
  const [selectedProjectId, setSelectedProjectId] = useState<string>('');

  // Mock projects since the Project Request module is not yet built
  const mockProjects = [
    { id: '123e4567-e89b-12d3-a456-426614174000', name: 'Luxury Villa Renovation' },
    { id: '223e4567-e89b-12d3-a456-426614174001', name: 'Downtown Penthouse Remodel' }
  ];

  useEffect(() => {
    const fetchDesigners = async () => {
      try {
        const res = await api.get<User[]>('/admin/users');
        setDesigners(res.data.filter(u => u.role === 'Designer'));
      } catch (err) {
        console.error('Failed to fetch designers', err);
      }
    };
    fetchDesigners();
  }, []);

  const handleNavigate = () => {
    if (selectedProjectId) {
      navigate(`/projects/${selectedProjectId}/execution`);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10">
      <div className="max-w-6xl mx-auto space-y-8">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E7E1D7] dark:border-[#2E2824] pb-6">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Admin Governance</h1>
                <span className="px-2.5 py-0.5 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-[10px] font-bold uppercase rounded-full">
                  Admin Role
                </span>
              </div>
              <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Logged in as {user?.name} ({user?.email})</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link
              to="/quotes-contracts"
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition shadow-2xs"
            >
              <FileText className="w-4 h-4 text-[#C48A36]" />
              <span>Quotes & Contracts Oversight</span>
            </Link>
            <Link
              to="/admin/users"
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition shadow-2xs"
            >
              <Users className="w-4 h-4 text-[#C48A36]" />
              <span>User Management</span>
            </Link>
            <button
              onClick={logout}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl hover:bg-rose-100 transition shadow-2xs"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </button>
          </div>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs space-y-2">
            <ShieldCheck className="w-6 h-6 text-[#C48A36]" />
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#78716C]">System Role</h3>
            <p className="text-2xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">{user?.role}</p>
          </div>
          <div className="p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs space-y-2">
            <div className="w-3 h-3 rounded-full bg-emerald-500" />
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#78716C]">Account Status</h3>
            <p className="text-2xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">
              {user?.isActive ? 'Active' : 'Disabled'}
            </p>
          </div>
          <div className="p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs space-y-2">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#78716C]">Security Boundary</h3>
            <p className="text-xs text-[#57534E] dark:text-[#A8A29E] leading-relaxed">
              Enforced server-side via ASP.NET Core JWT Middleware & <code>[Authorize(Roles = "Admin")]</code>.
            </p>
          </div>
        </div>

        {/* Module Navigation Section */}
        <div className="pt-6 border-t border-[#E7E1D7] dark:border-[#2E2824]">
          <h2 className="text-xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5] mb-6">
            Module Navigation
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Student 1: Designers */}
            <Link to="/admin/designers" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <Users className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Designers</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Manage designer profiles and matching</p>
              </div>
            </Link>

            {/* Student 2: Project Requests */}
            <Link to="/admin/requests" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Project Requests</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Review and manage client requests</p>
              </div>
            </Link>

            {/* Student 3: Quotes & Contracts */}
            <Link to="/quotes-contracts" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <FileText className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Quotes & Contracts</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Manage project quotes and agreements</p>
              </div>
            </Link>

            {/* Student 4: Project Execution */}
            <div className="p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs flex flex-col gap-4 relative">
              <div className="flex items-start justify-between">
                <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
                  <FileText className="w-6 h-6" />
                </div>
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Project Execution</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1 mb-3">Track progress and milestones</p>
                <div className="flex gap-2">
                  <select 
                    className="flex-1 text-xs bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#423525] rounded-xl px-2 py-2"
                    value={selectedProjectId}
                    onChange={(e) => setSelectedProjectId(e.target.value)}
                  >
                    <option value="">Select Project...</option>
                    {mockProjects.map(p => (
                      <option key={p.id} value={p.id}>{p.name}</option>
                    ))}
                  </select>
                  <button 
                    onClick={handleNavigate}
                    disabled={!selectedProjectId}
                    className="px-3 py-2 bg-[#1C1917] dark:bg-[#FAF8F5] text-white dark:text-[#1C1917] text-xs font-bold rounded-xl disabled:opacity-50"
                  >
                    Go
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Project requests analytics section */}
        <div className="pt-6 border-t border-[#E7E1D7] dark:border-[#2E2824]">
          <h2 className="text-xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5] mb-6">
            Project requests
          </h2>
          <RequestAnalyticsPanel />
        </div>
      </div>
    </div>
  );
};

