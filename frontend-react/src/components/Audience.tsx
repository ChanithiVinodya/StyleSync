import React from 'react';
import { 
  Smartphone, 
  Palette, 
  ClipboardList, 
  ShieldCheck, 
  Check, 
  ArrowUpRight,
} from 'lucide-react';
import { PERSONAS_DATA } from '../data/landingData';
import { PersonaRole } from '../types';

interface AudienceProps {
  onOpenMobileModal: () => void;
  onOpenPortalModal: (role: PersonaRole) => void;
}

interface RoleTheme {
  topBorder: string;
  iconBg: string;
  icon: React.ReactNode;
  badge: string;
  tagline: string;
  checkColor: string;
  ctaHover: string;
  ctaArrow: string;
  cardHover: string;
}

const ROLE_THEMES: Record<PersonaRole, RoleTheme> = {
  client: {
    topBorder: 'border-t-2 border-t-[#C48A36]',
    iconBg: 'bg-[#FAF3E8] dark:bg-[#2A231C] border-[#EADBCA] dark:border-[#3D3328]',
    icon: <Smartphone className="w-5 h-5 text-[#C48A36]" />,
    badge: 'bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border-[#EADBCA] dark:border-[#3D3328]',
    tagline: 'text-[#925C18] dark:text-[#E8A849]',
    checkColor: 'text-[#C48A36] dark:text-[#E8A849]',
    ctaHover: 'hover:border-[#C48A36]/50 hover:bg-[#FAF3E8]/60 dark:hover:bg-[#2A231C]/60',
    ctaArrow: 'text-[#C48A36]',
    cardHover: 'hover:border-[#C48A36]/40 hover:shadow-lg hover:shadow-[#C48A36]/5 dark:hover:shadow-black/40',
  },
  designer: {
    topBorder: 'border-t-2 border-t-[#1C1917] dark:border-t-[#FAF8F5]/80',
    iconBg: 'bg-[#F5F2EC] dark:bg-[#28231F] border-[#DED7CB] dark:border-[#3A332D]',
    icon: <Palette className="w-5 h-5 text-[#1C1917] dark:text-[#FAF8F5]" />,
    badge: 'bg-[#F5F2EC] dark:bg-[#28231F] text-[#292524] dark:text-[#E7E5E4] border-[#DED7CB] dark:border-[#3A332D]',
    tagline: 'text-[#44403C] dark:text-[#D6D0C7]',
    checkColor: 'text-[#1C1917] dark:text-[#FAF8F5]',
    ctaHover: 'hover:border-[#1C1917]/40 dark:hover:border-[#FAF8F5]/40 hover:bg-[#F5F2EC]/60 dark:hover:bg-[#28231F]/60',
    ctaArrow: 'text-[#1C1917] dark:text-[#FAF8F5]',
    cardHover: 'hover:border-[#1C1917]/30 dark:hover:border-[#FAF8F5]/30 hover:shadow-lg hover:shadow-stone-900/5 dark:hover:shadow-black/40',
  },
  coordinator: {
    topBorder: 'border-t-2 border-t-emerald-600 dark:border-t-emerald-500',
    iconBg: 'bg-emerald-50 dark:bg-emerald-950/40 border-emerald-200/80 dark:border-emerald-800/50',
    icon: <ClipboardList className="w-5 h-5 text-emerald-700 dark:text-emerald-400" />,
    badge: 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 border-emerald-200/80 dark:border-emerald-800/50',
    tagline: 'text-emerald-800 dark:text-emerald-400',
    checkColor: 'text-emerald-600 dark:text-emerald-400',
    ctaHover: 'hover:border-emerald-300 dark:hover:border-emerald-800/70 hover:bg-emerald-50/60 dark:hover:bg-emerald-950/40',
    ctaArrow: 'text-emerald-600 dark:text-emerald-400',
    cardHover: 'hover:border-emerald-500/40 dark:hover:border-emerald-500/30 hover:shadow-lg hover:shadow-emerald-900/5 dark:hover:shadow-black/40',
  },
  admin: {
    topBorder: 'border-t-2 border-t-slate-600 dark:border-t-slate-400',
    iconBg: 'bg-slate-100 dark:bg-slate-800/70 border-slate-200/80 dark:border-slate-700/60',
    icon: <ShieldCheck className="w-5 h-5 text-slate-700 dark:text-slate-300" />,
    badge: 'bg-slate-100 dark:bg-slate-800/70 text-slate-700 dark:text-slate-300 border-slate-200/80 dark:border-slate-700/60',
    tagline: 'text-slate-700 dark:text-slate-300',
    checkColor: 'text-slate-600 dark:text-slate-400',
    ctaHover: 'hover:border-slate-300 dark:hover:border-slate-700 hover:bg-slate-100/70 dark:hover:bg-slate-800/50',
    ctaArrow: 'text-slate-600 dark:text-slate-400',
    cardHover: 'hover:border-slate-400 dark:hover:border-slate-500 hover:shadow-lg hover:shadow-slate-900/5 dark:hover:shadow-black/40',
  },
};

export const Audience: React.FC<AudienceProps> = ({
  onOpenMobileModal,
  onOpenPortalModal,
}) => {
  const handleAction = (role: PersonaRole) => {
    if (role === 'client') {
      onOpenMobileModal();
    } else {
      onOpenPortalModal(role);
    }
  };

  return (
    <section id="who-its-for" className="pt-8 pb-16 sm:pt-10 sm:pb-20 bg-[#F4F0E8]/40 dark:bg-[#181513]/40 border-t border-[#E7E1D7] dark:border-[#2A2522]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-[#EFEAE1] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">
            <span>Marketplace Ecosystem</span>
          </div>
          <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
            Built for Every Stakeholder in the Renovation
          </h2>
          <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] max-w-2xl mx-auto leading-relaxed">
            From mobile room capture for homeowners to high-resolution desktop workspaces for design studios, coordinators, and administrators.
          </p>
        </div>

        {/* 4 Persona Cards Grid */}
        <div className="mt-8 sm:mt-10 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {PERSONAS_DATA.map((persona) => {
            const theme = ROLE_THEMES[persona.id];

            return (
              <div
                key={persona.id}
                className={`group bg-[#FFFFFF] dark:bg-[#1E1B18] rounded-3xl p-6 sm:p-7 border border-[#E7E1D7] dark:border-[#2E2824] ${theme.topBorder} flex flex-col justify-between transition-all duration-300 ease-out hover:-translate-y-1.5 ${theme.cardHover}`}
              >
                <div className="space-y-4">
                  {/* Top Row: Icon + Role Platform Badge */}
                  <div className="flex items-center justify-between">
                    <div className={`w-10 h-10 rounded-2xl border flex items-center justify-center shadow-2xs transition-transform duration-300 group-hover:scale-105 ${theme.iconBg}`}>
                      {theme.icon}
                    </div>
                    <span
                      className={`text-[10px] font-semibold px-2.5 py-1 rounded-full border ${theme.badge}`}
                    >
                      {persona.badge}
                    </span>
                  </div>

                  {/* Title & Tagline (Value Prop) */}
                  <div>
                    <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
                      {persona.title}
                    </h3>
                    <p className={`text-xs font-semibold mt-1 leading-snug ${theme.tagline}`}>
                      {persona.tagline}
                    </p>
                  </div>

                  {/* Description: 1 Short Sentence Adding a Concrete Detail */}
                  <p className="text-xs sm:text-[13px] text-[#57534E] dark:text-[#D6D0C7] leading-relaxed min-h-[40px]">
                    {persona.description}
                  </p>

                  {/* 3 Key Benefits List */}
                  <ul className="space-y-2.5 pt-3.5 border-t border-[#E7E1D7] dark:border-[#2A2522]">
                    {persona.keyBenefits.map((benefit, idx) => (
                      <li key={idx} className="flex items-start gap-2 text-xs text-[#44403C] dark:text-[#D6D0C7] leading-tight">
                        <Check className={`w-3.5 h-3.5 ${theme.checkColor} shrink-0 mt-0.5`} />
                        <span>{benefit}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Bottom CTA & Platform Disclaimer */}
                <div className="pt-6 mt-6 border-t border-[#E7E1D7] dark:border-[#2A2522] space-y-2">
                  <button
                    onClick={() => handleAction(persona.id)}
                    className={`w-full py-2.5 px-4 rounded-full text-xs font-semibold flex items-center justify-center gap-1.5 transition-all focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] bg-[#FAF8F5] dark:bg-[#26211D] text-[#1C1917] dark:text-[#FAF8F5] border border-[#E7E1D7] dark:border-[#352F2B] ${theme.ctaHover}`}
                  >
                    <span>{persona.ctaText}</span>
                    <ArrowUpRight className={`w-3.5 h-3.5 ${theme.ctaArrow}`} />
                  </button>

                  <p className="text-[10px] text-center text-[#78716C] dark:text-[#8C8681] italic leading-tight">
                    {persona.platformNote}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

      </div>
    </section>
  );
};
