import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { ShieldCheck, Users, LogOut, FileText } from 'lucide-react';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';

export const AdminDashboard: React.FC = () => {
  const { user, logout } = useAuth();

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
      </div>
    </div>
  );
};
