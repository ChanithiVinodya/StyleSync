import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { api } from '../../auth/authService';
import { Palette, LogOut, FileText } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const DesignerDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const [requests, setRequests] = useState<any[]>([]);

  useEffect(() => {
    api.get('/designer/requests')
      .then((res) => setRequests(res.data))
      .catch((err) => console.error('Failed to load designer requests', err));
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
            <button
              onClick={logout}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition shadow-2xs"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </button>
          </div>
        </header>

        {/* Quick Navigation Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Link
            to="/quotes-contracts"
            className="p-5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl hover:border-[#C48A36] transition shadow-2xs group flex items-center justify-between"
          >
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-[#C48A36]" />
                <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">Quotes & Contracts Studio</h3>
              </div>
              <p className="text-xs text-[#57534E] dark:text-[#A8A29E]">Draft, revise, generate with AI, and manage quote submissions</p>
            </div>
            <span className="px-3 py-1.5 text-xs font-semibold bg-[#1C1917] dark:bg-[#FAF8F5] text-[#FAF8F5] dark:text-[#1C1917] rounded-xl group-hover:scale-105 transition">Manage Quotes &rarr;</span>
          </Link>
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
