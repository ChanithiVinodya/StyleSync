import React, { useState } from 'react';
import { 
  Check, 
  ChevronRight, 
  Sparkles, 
  ShieldCheck, 
  Clock
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { FEATURES_DATA } from '../data/landingData';

interface FeaturesProps {
  onOpenGetStarted: () => void;
}

const TAB_ACCENTS = [
  {
    // Tab 0: Smart Matching (Amber / Gold)
    activeBorder: 'border-[#C48A36]/70 dark:border-[#E8A849]/70',
    activeGlow: 'shadow-[0_4px_16px_-2px_rgba(196,138,54,0.35)]',
    badgeBg: 'bg-[#C48A36] text-white dark:bg-[#E8A849] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#C48A36]/40 dark:ring-[#E8A849]/40',
  },
  {
    // Tab 1: Transparent Quotes (Emerald Green)
    activeBorder: 'border-emerald-600/70 dark:border-emerald-400/70',
    activeGlow: 'shadow-[0_4px_16px_-2px_rgba(16,185,129,0.35)]',
    badgeBg: 'bg-emerald-600 text-white dark:bg-emerald-500 dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-emerald-500/40 dark:ring-emerald-400/40',
  },
  {
    // Tab 2: Milestone Tracking (Terracotta / Warm Ochre)
    activeBorder: 'border-[#C25E30]/70 dark:border-[#F07844]/70',
    activeGlow: 'shadow-[0_4px_16px_-2px_rgba(194,94,48,0.35)]',
    badgeBg: 'bg-[#C25E30] text-white dark:bg-[#F07844] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#C25E30]/40 dark:ring-[#F07844]/40',
  },
  {
    // Tab 3: Human Approval (Rich Bronze / Amber)
    activeBorder: 'border-[#925C18]/70 dark:border-[#E8A849]/70',
    activeGlow: 'shadow-[0_4px_16px_-2px_rgba(146,92,24,0.35)]',
    badgeBg: 'bg-[#925C18] text-white dark:bg-[#E8A849] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#925C18]/40 dark:ring-[#E8A849]/40',
  },
];

export const Features: React.FC<FeaturesProps> = ({ onOpenGetStarted }) => {
  const [activeTab, setActiveTab] = useState<number>(0);

  const activeFeature = FEATURES_DATA[activeTab];

  return (
    <section id="how-it-works" className="pt-8 pb-16 sm:pt-10 sm:pb-20 relative bg-transparent border-t border-[#E7E1D7] dark:border-[#2A2522] overflow-hidden">
      {/* Subtle warm radial vignette behind the section for visual depth */}
      <div 
        className="absolute inset-0 pointer-events-none opacity-70 dark:opacity-35" 
        style={{
          background: 'radial-gradient(ellipse 75% 55% at 50% 45%, rgba(243, 235, 222, 0.75) 0%, rgba(250, 248, 245, 0) 100%)'
        }}
        aria-hidden="true"
      />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-[#F4F0E8] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">
            <span>How StyleSync Works</span>
          </div>
          <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
            The Deterministic Engine for Room Makeovers
          </h2>
          <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] max-w-2xl mx-auto leading-relaxed">
            No guesswork, no vague promises. Every match, quote, and milestone is backed by a calculated, auditable process — with a real person signing off at every step.
          </p>
        </div>

        {/* Feature Navigation Tabs with subtle accent color hints */}
        <div className="mt-6 sm:mt-7 flex items-center justify-start sm:justify-center overflow-x-auto pb-2 scrollbar-none gap-2 sm:gap-2.5">
          {FEATURES_DATA.map((feat, index) => {
            const isActive = activeTab === index;
            const accent = TAB_ACCENTS[index];
            return (
              <button
                key={feat.id}
                onClick={() => setActiveTab(index)}
                className={`whitespace-nowrap px-3.5 py-2 rounded-full text-xs sm:text-sm font-medium transition-all duration-300 flex items-center gap-2 border focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] cursor-pointer ${
                  isActive
                    ? `bg-[#1C1917] dark:bg-[#FAF8F5] text-[#FAF8F5] dark:text-[#1C1917] ${accent.activeBorder} ${accent.activeGlow} ${accent.ringColor}`
                    : 'bg-[#FAF8F5] dark:bg-[#1E1B18] text-[#57534E] dark:text-[#D6D0C7] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] hover:bg-[#F3EDE2] dark:hover:bg-[#28221D] border-[#E8E0D2] dark:border-[#2C2622] hover:border-[#D8CFC0] dark:hover:border-[#3D352E] shadow-2xs'
                }`}
              >
                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full transition-colors ${
                  isActive 
                    ? accent.badgeBg 
                    : 'bg-[#EDE5D8] dark:bg-[#2B2520] text-[#78716C] dark:text-[#A8A29E]'
                }`}>
                  {feat.number}
                </span>
                <span className="tracking-tight">{feat.title}</span>
              </button>
            );
          })}
        </div>

        {/* Dynamic Feature Deep-Dive Card with generous padding and soft elevation */}
        <div className="mt-6 sm:mt-7 bg-[#FFFFFF] dark:bg-[#1A1715] border border-[#E7E0D2] dark:border-[#2A2522] rounded-3xl p-6 sm:p-8 lg:p-9 shadow-[0_12px_36px_-10px_rgba(28,25,23,0.06)] dark:shadow-[0_12px_36px_-10px_rgba(0,0,0,0.6)] transition-colors duration-500">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -12 }}
              transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
              className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10 items-center"
            >
              
              {/* Feature Copy */}
              <div className="lg:col-span-6 space-y-4 sm:space-y-5">
                <div className="space-y-1.5">
                  <span className="text-xs font-semibold text-[#C48A36] dark:text-[#E8A849] uppercase tracking-wider">
                    Capability {activeFeature.number} of 04
                  </span>
                  <h3 className="font-serif text-2xl sm:text-3xl text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
                    {activeFeature.title}
                  </h3>
                  <p className="text-sm font-medium text-[#78716C] dark:text-[#A8A29E]">
                    {activeFeature.subtitle}
                  </p>
                </div>

                <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                  {activeFeature.description}
                </p>

                {/* Bullet Points */}
                <ul className="space-y-2.5 pt-1">
                  {activeFeature.bulletPoints.map((point, idx) => (
                    <li key={idx} className="flex items-start gap-3 text-sm text-[#44403C] dark:text-[#D6D0C7]">
                      <div className="w-5 h-5 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] text-[#925C18] dark:text-[#E8A849] flex items-center justify-center shrink-0 mt-0.5 shadow-2xs">
                        <Check className="w-3 h-3 stroke-[3]" />
                      </div>
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>

                {/* Metric Stamp & Interactive Action Link with tasteful hover */}
                <div className="pt-2 flex flex-wrap items-center gap-3">
                  <div className="px-3.5 py-2 rounded-xl bg-[#FAF8F5] dark:bg-[#221E1B] border border-[#E7E1D7] dark:border-[#332C27] text-xs font-medium text-[#1C1917] dark:text-[#FAF8F5] flex items-center gap-2 shadow-2xs hover:border-[#D6CEBF] dark:hover:border-[#473E36] transition-colors">
                    <Sparkles className="w-4 h-4 text-[#C48A36]" />
                    <span>{activeFeature.highlightMetric}</span>
                  </div>
                  <button
                    onClick={onOpenGetStarted}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 -ml-1 rounded-lg text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] hover:text-[#925C18] dark:hover:text-[#E8A849] hover:bg-[#F4EFE6] dark:hover:bg-[#28231E] transition-all duration-200 group cursor-pointer"
                  >
                    <span>Experience this flow</span>
                    <ChevronRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform duration-200" />
                  </button>
                </div>
              </div>

              {/* Feature Visual Representation */}
              <div className="lg:col-span-6">
                {activeTab === 0 && (
                  /* TAB 0: Match-Score Engine Visual (The Visual Centerpiece) */
                  <div className="bg-[#FDFBF7] dark:bg-[#171412] border border-[#EAE2D3] dark:border-[#2C2622] rounded-3xl p-5 sm:p-6 space-y-4 shadow-[0_12px_32px_-12px_rgba(28,25,23,0.08),0_4px_12px_-4px_rgba(28,25,23,0.04)] dark:shadow-[0_12px_32px_-12px_rgba(0,0,0,0.5)] transition-all duration-500">
                    
                    {/* Header with Prominent 98.4% Circular Progress Ring as Centerpiece */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-[#EAE2D3] dark:border-[#28221E]">
                      <div className="space-y-1">
                        <p className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                          Match Analysis Matrix
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Client Brief #SF-409 • Japandi Living Room
                        </p>
                      </div>

                      {/* Oversized Circular Progress Ring for Overall Match: 98.4% */}
                      <div className="flex items-center gap-3 self-start sm:self-auto bg-[#FAF4EA] dark:bg-[#221D18] px-3.5 py-1.5 rounded-2xl border border-[#EADBCA] dark:border-[#382E24] shadow-2xs">
                        <div className="relative w-14 h-14 sm:w-16 sm:h-16 flex items-center justify-center shrink-0">
                          <svg className="w-full h-full -rotate-90 transform" viewBox="0 0 96 96">
                            <circle
                              cx="48"
                              cy="48"
                              r="38"
                              className="stroke-[#E7DDCF] dark:stroke-[#302820]"
                              strokeWidth="7"
                              fill="transparent"
                            />
                            <motion.circle
                              cx="48"
                              cy="48"
                              r="38"
                              className="stroke-[#C48A36] dark:stroke-[#E8A849]"
                              strokeWidth="7"
                              strokeDasharray="238.76"
                              initial={{ strokeDashoffset: 238.76 }}
                              whileInView={{ strokeDashoffset: 3.82 }}
                              viewport={{ once: true }}
                              transition={{ duration: 1.2, ease: [0.16, 1, 0.3, 1] }}
                              strokeLinecap="round"
                              fill="transparent"
                            />
                          </svg>
                          <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                            <span className="font-serif font-bold text-base sm:text-lg text-[#1C1917] dark:text-[#FAF8F5] leading-none">
                              98.4%
                            </span>
                          </div>
                        </div>
                        <div className="pr-1">
                          <span className="text-xs font-bold text-[#925C18] dark:text-[#E8A849] block">
                            Overall Match: 98.4%
                          </span>
                          <span className="text-[10px] text-[#78716C] dark:text-[#A8A29E] font-medium block">
                            Algorithmic Fit Locked
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* The 4 Progress Bars with Deliberate Data-Viz Styling and Entrance Animation */}
                    <div className="space-y-3.5 text-xs">
                      {/* Row 1: Spatial Geometry */}
                      <div className="space-y-1">
                        <div className="flex justify-between items-baseline">
                          <span className="font-semibold text-[#292524] dark:text-[#E7E5E4] text-xs">Spatial Geometry & Room Scale Fit</span>
                          <span className="font-serif font-bold text-base sm:text-lg text-[#1C1917] dark:text-[#FAF8F5]">99%</span>
                        </div>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B] font-normal">
                          High ceiling & architectural slat millwork
                        </p>
                        <div className="w-full h-2.5 bg-[#EAE2D3] dark:bg-[#25201B] rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#443E38] to-[#1C1917] dark:from-[#D1C8BD] dark:to-[#FAF8F5] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '99%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>

                      {/* Row 2: Aesthetic Alignment */}
                      <div className="space-y-1">
                        <div className="flex justify-between items-baseline">
                          <span className="font-semibold text-[#292524] dark:text-[#E7E5E4] text-xs">Aesthetic Alignment</span>
                          <span className="font-serif font-bold text-base sm:text-lg text-[#C48A36] dark:text-[#E8A849]">98%</span>
                        </div>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B] font-normal">
                          Japandi & neutral linen (Studio Kanso core portfolio)
                        </p>
                        <div className="w-full h-2.5 bg-[#EAE2D3] dark:bg-[#25201B] rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#D98C30] to-[#B57321] dark:from-[#F2BE66] dark:to-[#E8A849] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '98%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>

                      {/* Row 3: Budget Feasibility */}
                      <div className="space-y-1">
                        <div className="flex justify-between items-baseline">
                          <span className="font-semibold text-[#292524] dark:text-[#E7E5E4] text-xs">Budget Feasibility</span>
                          <span className="font-serif font-bold text-base sm:text-lg text-emerald-600 dark:text-emerald-400">100%</span>
                        </div>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B] font-normal">
                          Calculated: $18,400 within $19,000 budget cap
                        </p>
                        <div className="w-full h-2.5 bg-[#EAE2D3] dark:bg-[#25201B] rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#10B981] to-[#047857] dark:from-[#34D399] dark:to-[#059669] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '100%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>

                      {/* Row 4: Designer Active Capacity */}
                      <div className="space-y-1">
                        <div className="flex justify-between items-baseline">
                          <span className="font-semibold text-[#292524] dark:text-[#E7E5E4] text-xs">Designer Active Capacity</span>
                          <span className="font-serif font-bold text-sm sm:text-base text-[#1C1917] dark:text-[#FAF8F5]">Available</span>
                        </div>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B] font-normal">
                          Verified open — 2 of 4 active project slots
                        </p>
                        <div className="w-full h-2.5 bg-[#EAE2D3] dark:bg-[#25201B] rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#57534E] to-[#1C1917] dark:from-[#A8A29E] dark:to-[#FAF8F5] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '100%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>
                    </div>

                    {/* Designer Preview Badge */}
                    <div className="mt-4 p-3 bg-[#FAF5ED] dark:bg-[#1E1A16] border border-[#EAE2D3] dark:border-[#2C2723] rounded-2xl flex items-center gap-3 shadow-2xs hover:border-[#D9CFC0] dark:hover:border-[#3D352E] transition-colors">
                      <img
                        src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80"
                        alt="Kenji Mori"
                        className="w-10 h-10 rounded-full object-cover border-2 border-[#E7DFD1] dark:border-[#383028] shrink-0"
                        referrerPolicy="no-referrer"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] truncate">Kenji Mori — Studio Kanso</p>
                        <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E] truncate">Licensed Architect & Interior Designer • Top Rated</p>
                      </div>
                      <span className="text-xs font-semibold text-emerald-800 dark:text-emerald-300 bg-emerald-100/70 dark:bg-emerald-950/60 px-2.5 py-1 rounded-full border border-emerald-300/60 dark:border-emerald-800/60 shrink-0">
                        Auto-Shortlisted
                      </span>
                    </div>
                  </div>
                )}

                {activeTab === 1 && (
                  /* TAB 1: Calculated Itemized Quote Visual */
                  <div className="bg-[#FDFBF7] dark:bg-[#171412] border border-[#EAE2D3] dark:border-[#2C2622] rounded-3xl p-5 sm:p-6 space-y-4 shadow-[0_12px_32px_-12px_rgba(28,25,23,0.08),0_4px_12px_-4px_rgba(28,25,23,0.04)] dark:shadow-[0_12px_32px_-12px_rgba(0,0,0,0.5)] transition-all duration-500">
                    <div className="flex items-center justify-between pb-3.5 border-b border-[#EAE2D3] dark:border-[#28221E]">
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                          Itemized Cost Calculation
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Contract #SS-2024-88 • Fixed Price Guarantee
                        </p>
                      </div>
                      <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 shadow-2xs">
                        Ceiling Locked
                      </span>
                    </div>

                    <div className="divide-y divide-[#EAE2D3] dark:divide-[#28221E] text-xs">
                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Custom White Oak Acoustic Slat Wall</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B]">FSC Certified • Precision Millwork (180 sq ft)</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$4,850.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Bespoke Curved Linen Sectional</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B]">Belgian Flax • Custom High-Density Foam</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$6,200.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Travertine Plinth & Architectural Sconces</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B]">Italian Vein-Cut Travertine • UL Listed Brass</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$2,950.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Licensed Trade Labor & Site Staging</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B]">Carpentry, Electrical & White-Glove Installation</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$4,400.00</span>
                      </div>
                    </div>

                    <div className="pt-3 border-t-2 border-[#1C1917] dark:border-[#FAF8F5] flex justify-between items-center">
                      <div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5] uppercase tracking-wider">Total Guaranteed Quote</p>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#9C948B]">Guaranteed price cap. Zero unapproved add-ons.</p>
                      </div>
                      <span className="font-serif text-xl sm:text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">$18,400.00</span>
                    </div>
                  </div>
                )}

                {activeTab === 2 && (
                  /* TAB 2: Milestone & Material Logistics Tracking Visual */
                  <div className="bg-[#FDFBF7] dark:bg-[#171412] border border-[#EAE2D3] dark:border-[#2C2622] rounded-3xl p-5 sm:p-6 space-y-3.5 shadow-[0_12px_32px_-12px_rgba(28,25,23,0.08),0_4px_12px_-4px_rgba(28,25,23,0.04)] dark:shadow-[0_12px_32px_-12px_rgba(0,0,0,0.5)] transition-all duration-500">
                    <div className="flex items-center justify-between pb-3.5 border-b border-[#EAE2D3] dark:border-[#28221E]">
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                          Project Milestone Timeline
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          4 Distinct Progress Stages
                        </p>
                      </div>
                      <span className="text-xs font-semibold text-[#57534E] dark:text-[#D6D0C7] flex items-center gap-1.5 bg-[#FAF5EC] dark:bg-[#201B17] px-2.5 py-0.5 rounded-full border border-[#EAE2D3] dark:border-[#2F2721]">
                        <Clock className="w-3.5 h-3.5 text-[#C48A36]" /> Week 3 of 4
                      </span>
                    </div>

                    <div className="space-y-2.5 text-xs">
                      {/* Milestone 1 */}
                      <div className="p-2.5 bg-[#FAF5ED] dark:bg-[#1E1A16] border border-[#EAE2D3] dark:border-[#2C2723] rounded-xl flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">
                            ✓
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M1: Concept & 3D Spatial Renders</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#A8A29E]">Signed off by Client • Phase 1 Approved</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-sm">
                          Complete
                        </span>
                      </div>

                      {/* Milestone 2 */}
                      <div className="p-2.5 bg-[#FAF5ED] dark:bg-[#1E1A16] border border-[#EAE2D3] dark:border-[#2C2723] rounded-xl flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold">
                            ✓
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M2: Technical CAD & Material Specs</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#A8A29E]">Approved by Coordinator • Phase 2 Complete</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-sm">
                          Complete
                        </span>
                      </div>

                      {/* Milestone 3 - In Progress */}
                      <div className="p-2.5 bg-[#FAF3E8] dark:bg-[#2A221A] border border-[#EADBCA] dark:border-[#4A3B2A] rounded-xl flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-[#1C1917] dark:bg-[#FAF8F5] text-white dark:text-[#1C1917] flex items-center justify-center text-[10px] font-bold animate-pulse">
                            3
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M3: Material Delivery & On-Site Staging</p>
                            <p className="text-[10px] text-[#925C18] dark:text-[#E8A849]">Slat Wall Delivered • Sectional En Route</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-[#925C18] dark:text-[#E8A849] bg-white dark:bg-[#1F1B18] px-2 py-0.5 rounded-sm border border-[#EADBCA] dark:border-[#4A3B2A]">
                          In Inspection
                        </span>
                      </div>

                      {/* Milestone 4 - Pending */}
                      <div className="p-2.5 bg-[#F7F3EB] dark:bg-[#1A1715] border border-[#EAE2D3] dark:border-[#2E2824] rounded-xl flex items-center justify-between opacity-75">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-[#E5DCD0] dark:bg-[#2E2824] text-[#78716C] dark:text-[#A8A29E] flex items-center justify-center text-[10px] font-bold">
                            4
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M4: Final Punch List & Project Handover</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#A8A29E]">White-Glove Styling & Final Walkthrough</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-medium text-[#78716C] dark:text-[#A8A29E]">
                          Upcoming
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === 3 && (
                  /* TAB 3: Dual Human Approval Visual */
                  <div className="bg-[#FDFBF7] dark:bg-[#171412] border border-[#EAE2D3] dark:border-[#2C2622] rounded-3xl p-5 sm:p-6 space-y-3.5 shadow-[0_12px_32px_-12px_rgba(28,25,23,0.08),0_4px_12px_-4px_rgba(28,25,23,0.04)] dark:shadow-[0_12px_32px_-12px_rgba(0,0,0,0.5)] transition-all duration-500">
                    <div className="flex items-center justify-between pb-3.5 border-b border-[#EAE2D3] dark:border-[#28221E]">
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                          Dual Sign-Off Verification
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Client & Coordinator Verification
                        </p>
                      </div>
                      <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] shadow-2xs">
                        Both Required
                      </span>
                    </div>

                    <p className="text-xs text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                      StyleSync requires two human sign-offs before any milestone is marked complete. No stage advances without both approvals.
                    </p>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1">
                      {/* Key 1: Client Signature */}
                      <div className="p-3 bg-[#FAF5ED] dark:bg-[#1E1A16] border border-[#EAE2D3] dark:border-[#2E2824] rounded-xl space-y-1.5 shadow-2xs">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-[#78716C] dark:text-[#A8A29E]">Key 1: Client</span>
                          <Check className="w-3.5 h-3.5 text-emerald-600 stroke-[3]" />
                        </div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Julian Vance</p>
                        <p className="text-[10px] text-[#78716C] dark:text-[#A8A29E]">Verified via StyleSync Mobile App</p>
                        <div className="text-[9px] font-mono text-[#78716C] dark:text-[#A8A29E] bg-[#F2EDE2] dark:bg-[#141210] p-1 rounded-sm border border-[#E5DCD0] dark:border-[#2A2522]">
                          SIG: 0x8F92...B31A (Timestamped)
                        </div>
                      </div>

                      {/* Key 2: Project Coordinator */}
                      <div className="p-3 bg-[#FAF5ED] dark:bg-[#1E1A16] border border-[#EAE2D3] dark:border-[#2E2824] rounded-xl space-y-1.5 shadow-2xs">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-[#78716C] dark:text-[#A8A29E]">Key 2: Coordinator</span>
                          <Check className="w-3.5 h-3.5 text-emerald-600 stroke-[3]" />
                        </div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Marissa Chen</p>
                        <p className="text-[10px] text-[#78716C] dark:text-[#A8A29E]">Verified via StyleSync Ops Suite</p>
                        <div className="text-[9px] font-mono text-[#78716C] dark:text-[#A8A29E] bg-[#F2EDE2] dark:bg-[#141210] p-1 rounded-sm border border-[#E5DCD0] dark:border-[#2A2522]">
                          SIG: 0x4C17...E92D (Inspected)
                        </div>
                      </div>
                    </div>

                    <div className="p-2.5 bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-200 dark:border-emerald-800/60 rounded-xl flex items-center gap-2 text-xs text-emerald-800 dark:text-emerald-300 shadow-2xs">
                      <ShieldCheck className="w-4 h-4 shrink-0 text-emerald-700 dark:text-emerald-400" />
                      <span>Both signatures verified. Milestone #3 approved and project advances.</span>
                    </div>
                  </div>
                )}
              </div>

            </motion.div>
          </AnimatePresence>
        </div>

      </div>
    </section>
  );
};

