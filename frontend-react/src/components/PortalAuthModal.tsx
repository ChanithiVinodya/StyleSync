import React, { useState } from 'react';
import { X, Palette, User as UserIcon, ArrowRight, Lock, Mail, CheckCircle2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { PersonaRole } from '../types';

interface PortalAuthModalProps {
  isOpen: boolean;
  defaultRole?: PersonaRole;
  onClose: () => void;
}

export const PortalAuthModal: React.FC<PortalAuthModalProps> = ({
  isOpen,
  defaultRole = 'designer',
  onClose,
}) => {
  const [activeRole, setActiveRole] = useState<'designer' | 'client'>(
    defaultRole === 'client' ? 'client' : 'designer'
  );
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  if (!isOpen) return null;

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const user = await login(email, password);
      onClose();
      if (user.role === 'Designer') {
        navigate('/designer');
      } else if (user.role === 'Client') {
        navigate('/client');
      } else if (user.role === 'Admin') {
        // Prevent Admin login via landing page modal
        navigate('/admin/dashboard');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Invalid email or password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C1917]/70 backdrop-blur-xs">
      <div 
        className="relative w-full max-w-md bg-[#FAF8F5] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8 shadow-2xl overflow-hidden text-[#1C1917] dark:text-[#FAF8F5]"
        role="dialog"
        aria-modal="true"
        aria-labelledby="portal-modal-title"
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 text-[#78716C] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] rounded-full transition-colors focus:outline-hidden"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="space-y-6">
          {/* Header */}
          <div className="space-y-1 pr-8">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#C48A36]">
              StyleSync Sign In
            </span>
            <h3 id="portal-modal-title" className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
              Welcome Back
            </h3>
            <p className="text-xs text-[#57534E] dark:text-[#A8A29E]">
              Access your interior design workspace or project portal.
            </p>
          </div>

          {/* Role Switcher Tabs (Only Designer and Client) */}
          <div className="grid grid-cols-2 gap-1.5 p-1 bg-[#EFEAE1] dark:bg-[#25201C] rounded-2xl">
            <button
              type="button"
              onClick={() => setActiveRole('client')}
              className={`py-2 px-2 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                activeRole === 'client'
                  ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs border border-[#E7E1D7] dark:border-[#2E2824]'
                  : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
              }`}
            >
              <UserIcon className="w-4 h-4 text-[#C48A36]" />
              <span>Client</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveRole('designer')}
              className={`py-2 px-2 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                activeRole === 'designer'
                  ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs border border-[#E7E1D7] dark:border-[#2E2824]'
                  : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
              }`}
            >
              <Palette className="w-4 h-4 text-[#C48A36]" />
              <span>Designer</span>
            </button>
          </div>

          {error && (
            <div className="p-3 text-xs text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl text-center">
              {error}
            </div>
          )}

          {/* Auth Form */}
          <form onSubmit={handleSignIn} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">
                Email Address
              </label>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={
                    activeRole === 'designer'
                      ? 'designer@studio.com'
                      : 'client@example.com'
                  }
                  className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                />
                <Mail className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Password</label>
              <div className="relative">
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                />
                <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 px-4 bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] text-[#FAF8F5] dark:text-[#1C1917] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs disabled:opacity-50"
            >
              <span>{loading ? 'Signing In...' : `Sign In as ${activeRole.charAt(0).toUpperCase() + activeRole.slice(1)}`}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* New User Application Note */}
          <div className="text-center pt-2 border-t border-[#E7E1D7] dark:border-[#2E2824]">
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              Don't have an account?{' '}
              <button
                type="button"
                onClick={() => {
                  onClose();
                  navigate('/register');
                }}
                className="font-medium text-[#1C1917] dark:text-[#FAF8F5] underline decoration-[#C48A36]"
              >
                Create Account
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
