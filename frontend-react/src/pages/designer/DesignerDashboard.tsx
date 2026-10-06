import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { api } from '../../auth/authService';
import { Palette, LogOut, FileCheck } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const DesignerDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const [requests, setRequests] = useState<any[]>([]);

  useEffect(() => {
    api.get('/designer/requests')
      .then((res: any) => setRequests(res.data))
      .catch((err: any) => console.error('Failed to load designer requests', err));
  }, []);

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10">
      <div className="max-w-5xl mx-auto space-y-6">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E7E1D7] dark:border-[#2E2824] pb-6">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Designer Studio Workspace</h1>
                <span className="px-2.5 py-0.5 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-[10px] font-bold uppercase rounded-full">
                  Designer
                </span>
              </div>
              <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Welcome back, {user?.name}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link
              to="/project-execution"
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition shadow-2xs"
            >
              <Palette className="w-4 h-4 text-[#C48A36]" />
              <span>Project Execution</span>
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

        {/* Module Navigation Section */}
        <div className="pt-2">
          <h2 className="text-xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5] mb-6">
            Module Navigation
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Student 1: Designers */}
            <Link to="/designers/studio" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <Palette className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">My Studio</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Manage your portfolio and profile</p>
              </div>
            </Link>

            {/* Student 2: Project Requests */}
            <Link to="/project-requests" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <FileCheck className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Project Requests</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">View incoming client requests</p>
              </div>
            </Link>

            {/* Student 3: Quotes & Contracts */}
            <Link to="/quotes-contracts" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <FileCheck className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Contracts Studio</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Submit quotes & sign agreements</p>
              </div>
            </Link>

            {/* Student 4: Project Execution */}
            <Link to="/projects/123e4567-e89b-12d3-a456-426614174000/execution" className="group p-6 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs hover:shadow-md hover:border-[#C48A36] transition-all flex flex-col gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] group-hover:scale-110 transition-transform">
                <Palette className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">Project Execution</h3>
                <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-1">Track active project progress</p>
              </div>
            </Link>
          </div>
        </div>

        <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
          <div className="flex items-center gap-2">
            <Palette className="w-5 h-5 text-[#C48A36]" />
            <h2 className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Assigned Makeover Projects</h2>
          </div>
          <div className="space-y-3">
            {requests.map((r, i) => (
              <div key={i} className="p-4 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl flex justify-between items-center">
                <div>
                  <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">{r.title}</h3>
                  <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Client: {r.clientName}</p>
                </div>
                <span className="px-3 py-1 bg-[#FAF3E8] dark:bg-[#2A231A] border border-[#E8DEC8] dark:border-[#423525] text-[#925C18] dark:text-[#E8A849] text-xs font-semibold rounded-full">
                  {r.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
