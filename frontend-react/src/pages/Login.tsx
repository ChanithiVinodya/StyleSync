import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { Mail, Lock, ArrowRight, Smartphone, Sparkles, ShieldCheck, User, Palette, Wrench } from 'lucide-react';
import { Logo } from '../components/Logo';
import { GlassThemeToggle } from '../components/GlassThemeToggle';
import { MobileAppModal } from '../components/MobileAppModal';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [isMobileModalOpen, setIsMobileModalOpen] = useState(false);

  const { login, logout } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const user = await login(email, password);

      // Route Designer to Designer Dashboard
      if (user.role === 'Designer') {
        navigate('/designer');
        return;
      }

      // Route Admin to Admin Dashboard
      if (user.role === 'Admin') {
        navigate('/admin/dashboard');
        return;
      }

      // Strictly Block Client Login on Website - Clients MUST use Mobile App
      if (user.role === 'Client') {
        logout();
        setError('Client accounts are managed through the StyleSync Mobile App. Please use the mobile app on your phone.');
        setIsMobileModalOpen(true);
        return;
      }
    } catch (err: any) {
      const message = err.response?.data?.message || 'Invalid email or password.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const fillCredentials = (type: 'designer' | 'admin') => {
    if (type === 'designer') {
      setEmail('designer@stylesync.com');
      setPassword('Designer@2026!');
    } else {
      setEmail('admin@stylesync.com');
      setPassword('Admin@StyleSync2026!');
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex flex-col justify-center items-center px-4 py-12 relative transition-colors duration-300">
      <div className="absolute top-6 right-6">
        <GlassThemeToggle />
      </div>

      <div className="w-full max-w-md bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 sm:p-10 shadow-2xl space-y-6">
        {/* StyleSync Header */}
        <div className="text-center space-y-1.5">
          <div className="flex justify-center mb-1">
            <Logo variant="auto" size="md" />
          </div>
          <h1 className="font-serif text-2xl sm:text-3xl font-bold tracking-tight text-[#1C1917] dark:text-[#FAF8F5]">
            StyleSync Design Marketplace
          </h1>
          <p className="text-xs font-semibold tracking-wider uppercase text-[#C48A36]">
            Interior Design &amp; AI Platform
          </p>
        </div>

        {/* Section Title */}
        <div className="text-center pt-1 space-y-0.5">
          <h2 className="text-xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">
            Login
          </h2>
          <p className="text-xs font-medium text-[#78716C] dark:text-[#A8A29E]">
            Designer &amp; Administrator Portal
          </p>
        </div>

        {/* Error Feedback */}
        {error && (
          <div className="p-3 text-xs text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl text-center">
            {error}
          </div>
        )}

        {/* Login Form for Designer & Admin */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1">
            <label className="block text-xs font-semibold text-[#44403C] dark:text-[#D6D3D1]">
              Email:
            </label>
            <div className="relative">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5] transition"
                placeholder="designer@stylesync.com"
              />
              <Mail className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-xs font-semibold text-[#44403C] dark:text-[#D6D3D1]">
              Password:
            </label>
            <div className="relative">
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5] transition"
                placeholder="••••••••••••"
              />
              <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3 px-4 bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] text-[#FAF8F5] dark:text-[#1C1917] rounded-xl text-xs font-bold tracking-wider uppercase flex items-center justify-center gap-2 transition-all shadow-md disabled:opacity-50"
          >
            <span>{loading ? 'Logging In...' : 'Login'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        {/* Designer Register Link */}
        <div className="text-center">
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
            Designer?{' '}
            <Link
              to="/register"
              className="font-bold text-[#1C1917] dark:text-[#FAF8F5] underline decoration-[#C48A36] hover:text-[#C48A36] transition"
            >
              Register
            </Link>
          </p>
        </div>

        {/* Divider */}
        <hr className="border-[#E7E1D7] dark:border-[#2E2824]" />

        {/* 👤 Clients Section */}
        <div className="text-center space-y-2.5">
          <div className="inline-flex items-center gap-1.5 text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">
            <User className="w-4 h-4 text-[#C48A36]" />
            <span>Clients</span>
          </div>

          <p className="text-xs text-[#57534E] dark:text-[#A8A29E] leading-relaxed">
            Client accounts are managed through
            <br />
            the StyleSync Mobile App.
          </p>

          <button
            type="button"
            onClick={() => setIsMobileModalOpen(true)}
            className="w-full py-2.5 px-4 bg-[#FAF3E8] dark:bg-[#25201C] hover:bg-[#F3E7D3] dark:hover:bg-[#302822] text-[#925C18] dark:text-[#EADBCA] border border-[#EADBCA] dark:border-[#3D332A] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-all shadow-xs"
          >
            <Smartphone className="w-4 h-4 text-[#C48A36]" />
            <span>📱 Open Client App / Download App</span>
          </button>
        </div>

        {/* Divider */}
        <hr className="border-[#E7E1D7] dark:border-[#2E2824]" />

        {/* 🎨 Designers & 🛠️ Administrators Information Section */}
        <div className="space-y-3 text-xs text-[#57534E] dark:text-[#A8A29E]">
          <div className="flex items-start gap-2">
            <Palette className="w-4 h-4 text-[#C48A36] shrink-0 mt-0.5" />
            <div>
              <span className="font-bold text-[#1C1917] dark:text-[#FAF8F5] block">
                Designers
              </span>
              <span>Designer registration and login are available on this website.</span>
            </div>
          </div>

          <div className="flex items-start gap-2">
            <Wrench className="w-4 h-4 text-[#78716C] shrink-0 mt-0.5" />
            <div>
              <span className="font-bold text-[#1C1917] dark:text-[#FAF8F5] block">
                Administrators
              </span>
              <span>Administrator login is available here.</span>
            </div>
          </div>
        </div>

        {/* Quick Fill Pills for Easy Review */}
        <div className="pt-2 flex justify-center gap-2 border-t border-[#E7E1D7] dark:border-[#2E2824]">
          <button
            type="button"
            onClick={() => fillCredentials('designer')}
            className="text-[10px] px-2.5 py-1 rounded-md bg-[#F5F2EB] dark:bg-[#25201C] text-[#78716C] hover:text-[#1C1917] dark:hover:text-white transition flex items-center gap-1 border border-[#E7E1D7] dark:border-[#2E2824]"
          >
            <Sparkles className="w-3 h-3 text-[#C48A36]" />
            <span>Fill Designer</span>
          </button>
          <button
            type="button"
            onClick={() => fillCredentials('admin')}
            className="text-[10px] px-2.5 py-1 rounded-md bg-[#F5F2EB] dark:bg-[#25201C] text-[#78716C] hover:text-[#1C1917] dark:hover:text-white transition flex items-center gap-1 border border-[#E7E1D7] dark:border-[#2E2824]"
          >
            <ShieldCheck className="w-3 h-3 text-[#C48A36]" />
            <span>Fill Admin</span>
          </button>
        </div>
      </div>

      {/* StyleSync Mobile App Modal */}
      <MobileAppModal
        isOpen={isMobileModalOpen}
        onClose={() => setIsMobileModalOpen(false)}
      />
    </div>
  );
};
