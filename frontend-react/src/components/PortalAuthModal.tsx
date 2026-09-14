import React, { useState } from 'react';
import { X, Palette, ClipboardList, ShieldCheck, ArrowRight, Lock, Mail, CheckCircle2 } from 'lucide-react';
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
  const [activeRole, setActiveRole] = useState<PersonaRole>(
    defaultRole === 'client' ? 'designer' : defaultRole
  );
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submittedMessage, setSubmittedMessage] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSignIn = (e: React.FormEvent) => {
    e.preventDefault();
    const roleLabels: Record<string, string> = {
      designer: 'Designer Workspace (/portal/designer)',
      coordinator: 'Project Coordinator Suite (/portal/coordinator)',
      admin: 'Platform Admin Governance Console (/portal/admin)',
    };
    setSubmittedMessage(
      `Redirecting credentials for ${email || 'user'} to ${roleLabels[activeRole]}...`
    );
    setTimeout(() => {
      setSubmittedMessage(null);
      onClose();
    }, 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C1917]/70 backdrop-blur-xs">
      <div 
        className="relative w-full max-w-md bg-[#FAF8F5] border border-[#E7E1D7] rounded-3xl p-6 sm:p-8 shadow-2xl overflow-hidden"
        role="dialog"
        aria-modal="true"
        aria-labelledby="portal-modal-title"
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 text-[#78716C] hover:text-[#1C1917] hover:bg-[#EFEAE1] rounded-full transition-colors focus:outline-hidden"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="space-y-6">
          {/* Header */}
          <div className="space-y-1 pr-8">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#C48A36]">
              Desktop Web Portals
            </span>
            <h3 id="portal-modal-title" className="font-serif text-2xl text-[#1C1917]">
              Sign In to Your Workspace
            </h3>
            <p className="text-xs text-[#57534E]">
              Dedicated workspaces for interior design studios, project coordinators, and platform admins.
            </p>
          </div>

          {/* Role Switcher Tabs */}
          <div className="grid grid-cols-3 gap-1.5 p-1 bg-[#EFEAE1] rounded-2xl">
            <button
              onClick={() => setActiveRole('designer')}
              className={`py-2 px-2 rounded-xl text-xs font-semibold flex flex-col items-center gap-1 transition-all ${
                activeRole === 'designer'
                  ? 'bg-white text-[#1C1917] shadow-xs'
                  : 'text-[#78716C] hover:text-[#1C1917]'
              }`}
            >
              <Palette className="w-4 h-4 text-[#C48A36]" />
              <span>Designer</span>
            </button>

            <button
              onClick={() => setActiveRole('coordinator')}
              className={`py-2 px-2 rounded-xl text-xs font-semibold flex flex-col items-center gap-1 transition-all ${
                activeRole === 'coordinator'
                  ? 'bg-white text-[#1C1917] shadow-xs'
                  : 'text-[#78716C] hover:text-[#1C1917]'
              }`}
            >
              <ClipboardList className="w-4 h-4 text-[#C48A36]" />
              <span>Coordinator</span>
            </button>

            <button
              onClick={() => setActiveRole('admin')}
              className={`py-2 px-2 rounded-xl text-xs font-semibold flex flex-col items-center gap-1 transition-all ${
                activeRole === 'admin'
                  ? 'bg-white text-[#1C1917] shadow-xs'
                  : 'text-[#78716C] hover:text-[#1C1917]'
              }`}
            >
              <ShieldCheck className="w-4 h-4 text-[#C48A36]" />
              <span>Admin</span>
            </button>
          </div>

          {/* Auth Form */}
          <form onSubmit={handleSignIn} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-xs font-medium text-[#44403C]">
                Professional Email
              </label>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={
                    activeRole === 'designer'
                      ? 'studio@designpractice.com'
                      : activeRole === 'coordinator'
                      ? 'operations@stylesync.internal'
                      : 'admin@stylesync.internal'
                  }
                  className="w-full pl-9 pr-3 py-2.5 text-xs bg-white border border-[#E7E1D7] rounded-xl focus:outline-hidden focus:border-[#1C1917] text-[#1C1917]"
                />
                <Mail className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
              </div>
            </div>

            <div className="space-y-1">
              <div className="flex justify-between items-center text-xs">
                <label className="font-medium text-[#44403C]">Password</label>
                <a href="#reset" className="text-[11px] text-[#C48A36] hover:underline">
                  Forgot password?
                </a>
              </div>
              <div className="relative">
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full pl-9 pr-3 py-2.5 text-xs bg-white border border-[#E7E1D7] rounded-xl focus:outline-hidden focus:border-[#1C1917] text-[#1C1917]"
                />
                <Lock className="w-4 h-4 text-[#78716C] absolute left-3 top-3" />
              </div>
            </div>

            {/* Target Route Indicator */}
            <div className="p-2.5 bg-[#FAF3E8] border border-[#EADBCA] rounded-xl text-[11px] text-[#925C18] flex items-center justify-between">
              <span>Portal Target:</span>
              <code className="font-mono font-semibold">
                /portal/{activeRole}
              </code>
            </div>

            {submittedMessage && (
              <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>{submittedMessage}</span>
              </div>
            )}

            <button
              type="submit"
              className="w-full py-3 px-4 bg-[#1C1917] hover:bg-[#322C27] text-[#FAF8F5] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs"
            >
              <span>Sign In to {activeRole.charAt(0).toUpperCase() + activeRole.slice(1)} Workspace</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* New User Application Note */}
          <div className="text-center pt-2 border-t border-[#E7E1D7]">
            <p className="text-xs text-[#78716C]">
              Need access?{' '}
              <a
                href="#apply"
                onClick={(e) => {
                  e.preventDefault();
                  alert("Designer verification applications are open. Complete portfolio screening to receive portal credentials.");
                }}
                className="font-medium text-[#1C1917] underline decoration-[#C48A36]"
              >
                Apply for Verified Designer Accreditation
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
