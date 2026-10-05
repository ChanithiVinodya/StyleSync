import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { ShieldCheck, Mail, Lock, ArrowRight } from 'lucide-react';
import { Logo } from '../components/Logo';
import { GlassThemeToggle } from '../components/GlassThemeToggle';

export const AdminLogin: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const user = await login(email, password);
      if (user.role === 'Admin') {
        navigate('/admin/dashboard');
      } else {
        setError('Access denied: Admin credentials required.');
      }
    } catch (err: any) {
      const message = err.response?.data?.message || 'Invalid administrator credentials.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex flex-col justify-center items-center px-4 py-12 relative">
      <div className="absolute top-6 right-6">
        <GlassThemeToggle />
      </div>

      <div className="w-full max-w-md bg-white dark:bg-[#1A1715] border border-[#C48A36]/40 dark:border-[#C48A36]/30 rounded-3xl p-8 shadow-2xl space-y-6">
        <div className="text-center space-y-2">
          <div className="flex justify-center mb-1">
            <Logo variant="auto" size="md" />
          </div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#FAF3E8] dark:bg-[#2A231A] border border-[#E8DEC8] dark:border-[#423525] rounded-full text-[#925C18] dark:text-[#E8A849] text-xs font-semibold">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Restricted Governance Extension (/admin)</span>
          </div>
          <h1 className="font-serif text-3xl font-normal text-[#1C1917] dark:text-[#FAF8F5] pt-1">
            Platform Admin Console
          </h1>
          <p className="text-xs text-[#57534E] dark:text-[#A8A29E]">
            Secure administrator authentication portal
          </p>
        </div>

        {error && (
          <div className="p-3 text-xs text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Admin Email</label>
            <div className="relative">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="admin@stylesync.com"
              />
              <Mail className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Master Password</label>
            <div className="relative">
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="••••••••••••"
              />
              <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 bg-[#C48A36] hover:bg-[#A8742A] text-white rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs disabled:opacity-50"
          >
            <span>{loading ? 'Authenticating Admin...' : 'Authenticate & Access Console'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>
      </div>
    </div>
  );
};
