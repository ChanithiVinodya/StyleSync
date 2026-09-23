import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { ShieldAlert, ArrowLeft } from 'lucide-react';
import { Logo } from '../components/Logo';
import { GlassThemeToggle } from '../components/GlassThemeToggle';

export const Unauthorized: React.FC = () => {
  const { user } = useAuth();

  const getHomePath = () => {
    if (!user) return '/login';
    if (user.role === 'Admin') return '/admin/dashboard';
    if (user.role === 'Designer') return '/designer';
    return '/client';
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex flex-col justify-center items-center px-4 py-12 relative">
      <div className="absolute top-6 right-6">
        <GlassThemeToggle />
      </div>

      <div className="w-full max-w-md bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 shadow-xl text-center space-y-6">
        <div className="flex justify-center mb-2">
          <Logo variant="auto" size="md" />
        </div>
        <div className="inline-flex items-center justify-center w-12 h-12 bg-rose-50 dark:bg-rose-950/60 border border-rose-200 dark:border-rose-900 rounded-full text-rose-600 dark:text-rose-400 mx-auto">
          <ShieldAlert className="w-6 h-6" />
        </div>
        <div>
          <span className="text-[11px] font-bold uppercase tracking-wider text-rose-600 dark:text-rose-400">
            HTTP 403 Forbidden
          </span>
          <h1 className="font-serif text-3xl font-normal text-[#1C1917] dark:text-[#FAF8F5] mt-1">
            Access Restricted
          </h1>
          <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-2 leading-relaxed">
            You do not have the required permissions or role accreditation to access this portal or API endpoint.
          </p>
        </div>

        <div className="pt-2">
          <Link
            to={getHomePath()}
            className="w-full py-3 px-4 bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] text-[#FAF8F5] dark:text-[#1C1917] rounded-xl text-xs font-semibold inline-flex items-center justify-center gap-2 transition-colors shadow-xs"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Return to Authorized Portal</span>
          </Link>
        </div>
      </div>
    </div>
  );
};
