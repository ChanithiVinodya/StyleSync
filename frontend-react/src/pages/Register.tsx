import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { User as UserIcon, Palette, Mail, Lock, UserCheck, ArrowRight } from 'lucide-react';
import { Logo } from '../components/Logo';
import { GlassThemeToggle } from '../components/GlassThemeToggle';

export const Register: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [role, setRole] = useState<'Client' | 'Designer'>('Client');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const { register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    setLoading(true);

    try {
      await register({
        name,
        email,
        password,
        confirmPassword,
        role,
      });

      navigate('/login');
    } catch (err: any) {
      let message = 'Registration failed. Please check your inputs.';
      if (err.response?.data) {
        if (typeof err.response.data.message === 'string' && err.response.data.message) {
          message = err.response.data.message;
        } else if (err.response.data.errors) {
          const firstError = Object.values(err.response.data.errors).flat()[0];
          if (firstError) message = String(firstError);
        } else if (err.response.data.title) {
          message = err.response.data.title;
        }
      } else if (err.message) {
        message = `Unable to connect to backend server (${err.message}). Please verify the backend API is running.`;
      }
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

      <div className="w-full max-w-md bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 shadow-xl space-y-6">
        <div className="text-center space-y-2">
          <div className="flex justify-center mb-2">
            <Logo variant="auto" size="md" />
          </div>
          <span className="text-[11px] font-bold uppercase tracking-wider text-[#C48A36]">
            Create Account
          </span>
          <h1 className="font-serif text-3xl font-normal text-[#1C1917] dark:text-[#FAF8F5]">
            Join StyleSync
          </h1>
          <p className="text-xs text-[#57534E] dark:text-[#A8A29E]">
            Client & Designer registration portal
          </p>
        </div>

        {error && (
          <div className="p-3 text-xs text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Account Type</label>
            <div className="grid grid-cols-2 gap-2 p-1 bg-[#EFEAE1] dark:bg-[#25201C] rounded-2xl">
              <button
                type="button"
                onClick={() => setRole('Client')}
                className={`py-2 px-3 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                  role === 'Client'
                    ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs border border-[#E7E1D7] dark:border-[#2E2824]'
                    : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
                }`}
              >
                <UserIcon className="w-3.5 h-3.5 text-[#C48A36]" />
                <span>Client</span>
              </button>
              <button
                type="button"
                onClick={() => setRole('Designer')}
                className={`py-2 px-3 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                  role === 'Designer'
                    ? 'bg-white dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] shadow-xs border border-[#E7E1D7] dark:border-[#2E2824]'
                    : 'text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
                }`}
              >
                <Palette className="w-3.5 h-3.5 text-[#C48A36]" />
                <span>Designer</span>
              </button>
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Full Name</label>
            <div className="relative">
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="Alex Smith"
              />
              <UserCheck className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Email Address</label>
            <div className="relative">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="alex@example.com"
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
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="Minimum 8 characters"
              />
              <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <div className="space-y-1">
            <label className="block text-xs font-medium text-[#44403C] dark:text-[#D6D3D1]">Confirm Password</label>
            <div className="relative">
              <input
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 text-xs bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl focus:outline-hidden focus:border-[#C48A36] text-[#1C1917] dark:text-[#FAF8F5]"
                placeholder="Re-enter password"
              />
              <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] text-[#FAF8F5] dark:text-[#1C1917] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs disabled:opacity-50"
          >
            <span>{loading ? 'Creating Account...' : 'Create Account'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="text-center pt-2 border-t border-[#E7E1D7] dark:border-[#2E2824]">
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
            Already have an account?{' '}
            <Link to="/login" className="font-medium text-[#1C1917] dark:text-[#FAF8F5] underline decoration-[#C48A36]">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};
