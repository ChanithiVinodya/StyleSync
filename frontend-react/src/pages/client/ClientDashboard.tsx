import React, { useEffect, useState } from 'react';
import { useAuth } from '../../auth/AuthContext';
import { api } from '../../auth/authService';
import { Home, LogOut } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const ClientDashboard: React.FC = () => {
  const { user, logout } = useAuth();
  const [requests, setRequests] = useState<any[]>([]);

  useEffect(() => {
    api.get('/client/requests')
      .then((res) => setRequests(res.data))
      .catch((err) => console.error('Failed to load client requests', err));
  }, []);

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10">
      <div className="max-w-5xl mx-auto space-y-6">
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#E7E1D7] dark:border-[#2E2824] pb-6">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Client Portal</h1>
                <span className="px-2.5 py-0.5 bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] text-[10px] font-bold uppercase rounded-full">
                  Client
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

        <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8 shadow-xs space-y-4">
          <div className="flex items-center gap-2">
            <Home className="w-5 h-5 text-[#C48A36]" />
            <h2 className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Your Room Makeover Requests</h2>
          </div>
          <div className="space-y-3">
            {requests.map((r, i) => (
              <div key={i} className="p-4 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl flex justify-between items-center">
                <div>
                  <h3 className="font-semibold text-sm text-[#1C1917] dark:text-[#FAF8F5]">{r.roomType}</h3>
                  <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Budget: ${r.budget}</p>
                </div>
                <span className="px-3 py-1 bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 text-xs font-semibold rounded-full">
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
