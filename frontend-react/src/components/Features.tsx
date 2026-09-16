import React, { useState } from 'react';
import { 
  Check, 
  ChevronRight, 
  Sparkles, 
  ShieldCheck, 
  Clock,
  Layers,
  Calculator,
  UserCheck
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { FEATURES_DATA } from '../data/landingData';

interface FeaturesProps {
  onOpenGetStarted: () => void;
}

const TAB_ACCENTS = [
  {
    // Tab 0: Smart Matching (Amber / Gold)
    activeBorder: 'border-[#C48A36]/60 dark:border-[#E8A849]/60',
    activeGlow: 'shadow-[0_4px_20px_-2px_rgba(196,138,54,0.30)]',
    badgeBg: 'bg-[#C48A36] text-white dark:bg-[#E8A849] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#C48A36]/30 dark:ring-[#E8A849]/30',
    icon: Sparkles,
    glowGradient: 'from-[#FCEFD7]/80 via-[#F5D7A0]/50 to-[#E8A849]/30',
  },
  {
    // Tab 1: Transparent Quotes (Warm Ochre & Emerald)
    activeBorder: 'border-emerald-600/60 dark:border-emerald-400/60',
    activeGlow: 'shadow-[0_4px_20px_-2px_rgba(16,185,129,0.30)]',
    badgeBg: 'bg-emerald-600 text-white dark:bg-emerald-500 dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-emerald-500/30 dark:ring-emerald-400/30',
    icon: Calculator,
    glowGradient: 'from-[#EAF6ED]/80 via-[#D0ECD7]/50 to-[#92DBA3]/30',
  },
  {
    // Tab 2: Milestone Tracking (Terracotta & Warm Ochre)
    activeBorder: 'border-[#C25E30]/60 dark:border-[#F07844]/60',
    activeGlow: 'shadow-[0_4px_20px_-2px_rgba(194,94,48,0.30)]',
    badgeBg: 'bg-[#C25E30] text-white dark:bg-[#F07844] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#C25E30]/30 dark:ring-[#F07844]/30',
    icon: Clock,
    glowGradient: 'from-[#FDF0E9]/80 via-[#FCD7C3]/50 to-[#F4A881]/30',
  },
  {
    // Tab 3: Human Approval (Rich Bronze & Honey)
    activeBorder: 'border-[#925C18]/60 dark:border-[#E8A849]/60',
    activeGlow: 'shadow-[0_4px_20px_-2px_rgba(146,92,24,0.30)]',
    badgeBg: 'bg-[#925C18] text-white dark:bg-[#E8A849] dark:text-[#1C1917]',
    ringColor: 'ring-1 ring-[#925C18]/30 dark:ring-[#E8A849]/30',
    icon: UserCheck,
    glowGradient: 'from-[#FCF3E5]/80 via-[#F9E2BE]/50 to-[#E9BC74]/30',
  },
];

export const Features: React.FC<FeaturesProps> = ({ onOpenGetStarted }) => {
  const [activeTab, setActiveTab] = useState<number>(0);
  const [isPausedByUser, setIsPausedByUser] = useState<boolean>(false);
  const [isHovered, setIsHovered] = useState<boolean>(false);

  // Auto-slide to next card every 4.5s unless paused by user interaction or hovered
  React.useEffect(() => {
    if (isPausedByUser || isHovered) return;

    const interval = setInterval(() => {
      setActiveTab((prev) => (prev + 1) % FEATURES_DATA.length);
    }, 4500);

    return () => clearInterval(interval);
  }, [isPausedByUser, isHovered]);

  const handleTabSelect = (index: number) => {
    // User explicitly chose a tab -> stop auto-sliding so they can read at their own pace
    setIsPausedByUser(true);
    setActiveTab(index);
  };

  const activeFeature = FEATURES_DATA[activeTab];
  const CurrentIcon = TAB_ACCENTS[activeTab].icon;

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
          <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-white/70 dark:bg-white/10 backdrop-blur-md border border-white/80 dark:border-white/15 text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider shadow-2xs">
            <span>How StyleSync Works</span>
          </div>
          <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
            The Deterministic Engine for Room Makeovers
          </h2>
          <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] max-w-2xl mx-auto leading-relaxed">
            No guesswork, no vague promises. Every match, quote, and milestone is backed by a calculated, auditable process — with a real person signing off at every step.
          </p>
        </div>

        {/* Feature Navigation Tabs with smooth sliding active pill and frosted glass styling */}
        <div className="mt-6 sm:mt-7 flex items-center justify-start sm:justify-center overflow-x-auto pb-2 scrollbar-none gap-2 sm:gap-2.5">
          {FEATURES_DATA.map((feat, index) => {
            const isActive = activeTab === index;
            const accent = TAB_ACCENTS[index];
            return (
              <button
                key={feat.id}
                onClick={() => handleTabSelect(index)}
                className={`relative whitespace-nowrap px-3.5 py-2 rounded-full text-xs sm:text-sm font-medium transition-colors duration-300 flex items-center gap-2 border focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] cursor-pointer ${
                  isActive
                    ? `text-[#1C1917] dark:text-[#FAF8F5] ${accent.activeBorder} ${accent.activeGlow} ${accent.ringColor}`
                    : 'bg-white/60 dark:bg-white/5 text-[#57534E] dark:text-[#D6D0C7] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] hover:bg-white/85 dark:hover:bg-white/10 border-white/70 dark:border-white/10 backdrop-blur-md shadow-2xs'
                }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeTabPill"
                    className="absolute inset-0 bg-white/95 dark:bg-white/20 backdrop-blur-md rounded-full shadow-md -z-10"
                    transition={{ type: 'spring', stiffness: 420, damping: 32 }}
                  />
                )}
                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full transition-colors relative z-10 ${
                  isActive 
                    ? accent.badgeBg 
                    : 'bg-[#EDE5D8] dark:bg-[#2B2520] text-[#78716C] dark:text-[#A8A29E]'
                }`}>
                  {feat.number}
                </span>
                <span className="tracking-tight relative z-10">{feat.title}</span>

                {/* Subtle active timer bar if auto-sliding is active */}
                {isActive && !isPausedByUser && (
                  <motion.div
                    key={`timer-${activeTab}-${isHovered}`}
                    className="absolute bottom-0 left-3 right-3 h-[2px] bg-[#C48A36] dark:bg-[#E8A849] rounded-full overflow-hidden opacity-75"
                    initial={{ scaleX: 0, originX: 0 }}
                    animate={{ scaleX: isHovered ? undefined : 1 }}
                    transition={{ duration: isHovered ? 0 : 4.5, ease: 'linear' }}
                  />
                )}
              </button>
            );
          })}
        </div>

        {/* Dynamic Feature Deep-Dive Card with Luminous Frosted Glass Aesthetic */}
        <div 
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
          className="relative mt-6 sm:mt-7 bg-white/60 dark:bg-white/10 backdrop-blur-3xl border border-white/80 dark:border-white/20 rounded-[32px] p-6 sm:p-8 lg:p-9 shadow-[0_20px_50px_-12px_rgba(202,142,56,0.18),inset_0_1px_1px_rgba(255,255,255,0.9)] dark:shadow-[0_20px_50px_-12px_rgba(0,0,0,0.5)] transition-all duration-500 overflow-hidden"
        >
          {/* Luminous Warm Ambient Light Blobs glowing beneath the frosted glass */}
          <div className="absolute -top-20 -right-20 w-96 h-96 bg-gradient-to-br from-[#F5D8A0]/65 via-[#E8A849]/35 to-transparent rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-20 -left-20 w-96 h-96 bg-gradient-to-tr from-[#E6B873]/50 via-[#F7E1B8]/40 to-transparent rounded-full blur-3xl pointer-events-none" />

          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, x: 80 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -80 }}
              transition={{ duration: 0.46, ease: [0.22, 1, 0.36, 1] }}
              className="relative z-10 grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10 items-center"
            >
              
              {/* Feature Copy with chic squircle icon card */}
              <motion.div 
                initial={{ opacity: 0, y: 14 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.58, delay: 0.10, ease: [0.16, 1, 0.3, 1] }}
                className="lg:col-span-6 space-y-4 sm:space-y-5"
              >
                {/* Top Squircle Icon & Capability Tag */}
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-2xl bg-white/90 dark:bg-white/20 backdrop-blur-md shadow-[0_6px_20px_rgba(196,138,54,0.14)] border border-white/90 dark:border-white/25 flex items-center justify-center text-[#925C18] dark:text-[#E8A849] shrink-0">
                    <CurrentIcon className="w-5 h-5 stroke-[2.2]" />
                  </div>
                  <span className="text-xs font-semibold text-[#C48A36] dark:text-[#E8A849] uppercase tracking-wider">
                    Capability {activeFeature.number} of 04
                  </span>
                </div>

                <div className="space-y-1.5">
                  <h3 className="font-serif text-2xl sm:text-3xl text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
                    {activeFeature.title}
                  </h3>
                  <p className="text-sm font-medium text-[#78716C] dark:text-[#D6D0C7]">
                    {activeFeature.subtitle}
                  </p>
                </div>

                <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                  {activeFeature.description}
                </p>

                {/* Bullet Points */}
                <ul className="space-y-2.5 pt-1">
                  {activeFeature.bulletPoints.map((point, idx) => (
                    <li key={idx} className="flex items-start gap-3 text-sm text-[#44403C] dark:text-[#E7E5E4]">
                      <div className="w-5 h-5 rounded-full bg-white/90 dark:bg-white/20 border border-white/80 dark:border-white/20 text-[#925C18] dark:text-[#E8A849] flex items-center justify-center shrink-0 mt-0.5 shadow-xs backdrop-blur-xs">
                        <Check className="w-3 h-3 stroke-[3]" />
                      </div>
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>

                {/* Metric Stamp & Interactive Action Link */}
                <div className="pt-2 flex flex-wrap items-center gap-3">
                  <div className="px-3.5 py-2 rounded-xl bg-white/80 dark:bg-white/15 backdrop-blur-md border border-white/80 dark:border-white/20 text-xs font-medium text-[#1C1917] dark:text-[#FAF8F5] flex items-center gap-2 shadow-xs hover:border-[#C48A36]/50 transition-colors">
                    <Sparkles className="w-4 h-4 text-[#C48A36]" />
                    <span>{activeFeature.highlightMetric}</span>
                  </div>
                  <button
                    onClick={onOpenGetStarted}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 -ml-1 rounded-lg text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] hover:text-[#925C18] dark:hover:text-[#E8A849] hover:bg-white/60 dark:hover:bg-white/10 transition-all duration-200 group cursor-pointer"
                  >
                    <span>Experience this flow</span>
                    <ChevronRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform duration-200" />
                  </button>
                </div>
              </motion.div>

              {/* Feature Visual Representation - Nested Frosted Glass Card */}
              <motion.div 
                initial={{ opacity: 0, scale: 0.97, y: 16 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{ duration: 0.62, delay: 0.18, ease: [0.16, 1, 0.3, 1] }}
                className="lg:col-span-6"
              >
                {activeTab === 0 && (
                  /* TAB 0: Match-Score Engine Visual - Luminous Japandi Amber Glass */
                  <div className="relative bg-white/75 dark:bg-white/10 backdrop-blur-2xl border border-white/90 dark:border-white/20 rounded-[28px] p-5 sm:p-6 space-y-3.5 shadow-[0_16px_40px_-10px_rgba(196,138,54,0.18),inset_0_1px_1px_rgba(255,255,255,0.95)] overflow-hidden">
                    {/* Atmospheric Warm Amber Glow Blobs */}
                    <div className="absolute -top-12 -right-12 w-60 h-60 bg-gradient-to-br from-[#FCEFD7]/80 via-[#F5D7A0]/50 to-transparent rounded-full blur-2xl pointer-events-none" />
                    <div className="absolute -bottom-12 -left-12 w-64 h-64 bg-gradient-to-tr from-[#E6B873]/50 via-[#F7E1B8]/40 to-transparent rounded-full blur-2xl pointer-events-none" />
                    
                    {/* Header with Overall Match Score */}
                    <div className="relative z-10 flex items-center justify-between pb-3 border-b border-white/70 dark:border-white/15">
                      <div>
                        <p className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#D6D0C7]">
                          Match Analysis Matrix
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Client Brief #SF-409 • Japandi Living
                        </p>
                      </div>

                      <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-white/90 dark:bg-white/20 backdrop-blur-md border border-white/80 dark:border-white/25 shadow-xs">
                        <span className="w-2 h-2 rounded-full bg-[#C48A36] animate-pulse" />
                        <span className="text-xs font-bold text-[#925C18] dark:text-[#E8A849]">
                          Overall Match: 98.4%
                        </span>
                      </div>
                    </div>

                    {/* 4 Progress Metrics in Frosted Glass Capsules */}
                    <div className="relative z-10 space-y-2 text-xs">
                      {/* Row 1: Spatial Geometry */}
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-2xs">
                        <div className="flex justify-between items-baseline">
                          <div className="flex items-center gap-1.5 truncate">
                            <span className="font-semibold text-[#292524] dark:text-[#E7E5E4]">Spatial Geometry</span>
                            <span className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7] hidden sm:inline">• High ceiling & millwork scale</span>
                          </div>
                          <span className="font-serif font-bold text-sm text-[#1C1917] dark:text-[#FAF8F5] shrink-0 ml-2">99%</span>
                        </div>
                        <div className="w-full h-2 bg-white/80 dark:bg-white/10 rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#8C765E] to-[#C48A36] dark:from-[#D1C8BD] dark:to-[#E8A849] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '99%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>

                      {/* Row 2: Aesthetic Alignment */}
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-2xs">
                        <div className="flex justify-between items-baseline">
                          <div className="flex items-center gap-1.5 truncate">
                            <span className="font-semibold text-[#292524] dark:text-[#E7E5E4]">Aesthetic Alignment</span>
                            <span className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7] hidden sm:inline">• Japandi & neutral palette</span>
                          </div>
                          <span className="font-serif font-bold text-sm text-[#C48A36] dark:text-[#E8A849] shrink-0 ml-2">98%</span>
                        </div>
                        <div className="w-full h-2 bg-white/80 dark:bg-white/10 rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#E8A849] to-[#C48A36] dark:from-[#F2BE66] dark:to-[#E8A849] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '98%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>

                      {/* Row 3: Budget Feasibility */}
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-2xs">
                        <div className="flex justify-between items-baseline">
                          <div className="flex items-center gap-1.5 truncate">
                            <span className="font-semibold text-[#292524] dark:text-[#E7E5E4]">Budget Feasibility</span>
                            <span className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7] hidden sm:inline">• $18.4k within $19k cap</span>
                          </div>
                          <span className="font-serif font-bold text-sm text-emerald-700 dark:text-emerald-400 shrink-0 ml-2">100%</span>
                        </div>
                        <div className="w-full h-2 bg-white/80 dark:bg-white/10 rounded-full overflow-hidden p-0.5 shadow-inner">
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
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-2xs">
                        <div className="flex justify-between items-baseline">
                          <div className="flex items-center gap-1.5 truncate">
                            <span className="font-semibold text-[#292524] dark:text-[#E7E5E4]">Designer Capacity</span>
                            <span className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7] hidden sm:inline">• 2 of 4 project slots open</span>
                          </div>
                          <span className="font-serif font-bold text-xs text-[#1C1917] dark:text-[#FAF8F5] shrink-0 ml-2">Available</span>
                        </div>
                        <div className="w-full h-2 bg-white/80 dark:bg-white/10 rounded-full overflow-hidden p-0.5 shadow-inner">
                          <motion.div 
                            className="h-full bg-gradient-to-r from-[#C48A36] to-[#8C765E] dark:from-[#E8A849] dark:to-[#FAF8F5] rounded-full"
                            initial={{ width: 0 }}
                            whileInView={{ width: '100%' }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.9, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
                          />
                        </div>
                      </div>
                    </div>

                    {/* Designer Preview Badge */}
                    <div className="relative z-10 p-2.5 bg-white/85 dark:bg-white/15 backdrop-blur-md border border-white/80 dark:border-white/20 rounded-2xl flex items-center gap-2.5 shadow-xs">
                      <img
                        src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80"
                        alt="Kenji Mori"
                        className="w-8 h-8 rounded-full object-cover border-2 border-white dark:border-white/30 shrink-0 shadow-xs"
                        referrerPolicy="no-referrer"
                      />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] truncate">Kenji Mori — Studio Kanso</p>
                        <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7] truncate">Top Rated Architect & Designer</p>
                      </div>
                      <span className="text-[11px] font-semibold text-emerald-800 dark:text-emerald-300 bg-emerald-100/80 dark:bg-emerald-950/70 px-2.5 py-0.5 rounded-full border border-emerald-300/80 dark:border-emerald-800/80 shrink-0 shadow-2xs">
                        Auto-Shortlisted
                      </span>
                    </div>
                  </div>
                )}

                {activeTab === 1 && (
                  /* TAB 1: Calculated Itemized Quote Visual - Luminous Mineral Glass */
                  <div className="relative bg-white/75 dark:bg-white/10 backdrop-blur-2xl border border-white/90 dark:border-white/20 rounded-[28px] p-5 sm:p-6 space-y-3.5 shadow-[0_16px_40px_-10px_rgba(16,185,129,0.15),inset_0_1px_1px_rgba(255,255,255,0.95)] overflow-hidden">
                    {/* Atmospheric Emerald-Sage & Sand Glow Blobs */}
                    <div className="absolute -top-12 -right-12 w-60 h-60 bg-gradient-to-br from-[#EAF6ED]/80 via-[#D0ECD7]/50 to-transparent rounded-full blur-2xl pointer-events-none" />
                    <div className="absolute -bottom-12 -left-12 w-64 h-64 bg-gradient-to-tr from-[#F8D298]/40 via-[#E4F2E4]/40 to-transparent rounded-full blur-2xl pointer-events-none" />
                    
                    <div className="relative z-10 flex items-center justify-between pb-3 border-b border-white/70 dark:border-white/15">
                      <div>
                        <p className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#D6D0C7]">
                          Itemized Cost Calculation
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Contract #SS-2024-88 • Fixed Price
                        </p>
                      </div>
                      <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-white/90 dark:bg-white/20 text-emerald-800 dark:text-emerald-300 border border-white/80 dark:border-white/25 shadow-xs backdrop-blur-md">
                        Ceiling Locked
                      </span>
                    </div>

                    <div className="relative z-10 divide-y divide-white/60 dark:divide-white/10 text-xs">
                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Custom White Oak Acoustic Slat Wall</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7]">FSC Certified • Precision Millwork (180 sq ft)</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$4,850.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Bespoke Curved Linen Sectional</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7]">Belgian Flax • Custom High-Density Foam</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$6,200.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Travertine Plinth & Architectural Sconces</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7]">Italian Vein-Cut Travertine • UL Listed Brass</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$2,950.00</span>
                      </div>

                      <div className="py-2 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">Licensed Trade Labor & Site Staging</p>
                          <p className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7]">Carpentry, Electrical & White-Glove Staging</p>
                        </div>
                        <span className="font-mono font-medium text-sm text-[#1C1917] dark:text-[#FAF8F5]">$4,400.00</span>
                      </div>
                    </div>

                    <div className="relative z-10 pt-3 border-t border-white/80 dark:border-white/20 flex justify-between items-center bg-white/50 dark:bg-white/10 p-2.5 rounded-2xl">
                      <div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5] uppercase tracking-wider">Total Guaranteed Quote</p>
                        <p className="text-[11px] text-[#8C827A] dark:text-[#D6D0C7]">Guaranteed price cap. Zero unapproved add-ons.</p>
                      </div>
                      <span className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">$18,400.00</span>
                    </div>
                  </div>
                )}

                {activeTab === 2 && (
                  /* TAB 2: Milestone & Material Logistics Tracking Visual - Luminous Terracotta-Apricot Glass */
                  <div className="relative bg-white/75 dark:bg-white/10 backdrop-blur-2xl border border-white/90 dark:border-white/20 rounded-[28px] p-5 sm:p-6 space-y-3.5 shadow-[0_16px_40px_-10px_rgba(194,94,48,0.16),inset_0_1px_1px_rgba(255,255,255,0.95)] overflow-hidden">
                    {/* Atmospheric Apricot & Terracotta Glow Blobs */}
                    <div className="absolute -top-12 -right-12 w-60 h-60 bg-gradient-to-br from-[#FDF0E9]/80 via-[#FCD7C3]/50 to-transparent rounded-full blur-2xl pointer-events-none" />
                    <div className="absolute -bottom-12 -left-12 w-64 h-64 bg-gradient-to-tr from-[#F8D298]/40 via-[#F6E6D8]/40 to-transparent rounded-full blur-2xl pointer-events-none" />
                    
                    <div className="relative z-10 flex items-center justify-between pb-3 border-b border-white/70 dark:border-white/15">
                      <div>
                        <p className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#D6D0C7]">
                          Project Milestone Timeline
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          4 Distinct Progress Stages
                        </p>
                      </div>
                      <span className="text-xs font-semibold text-[#57534E] dark:text-[#D6D0C7] flex items-center gap-1.5 bg-white/90 dark:bg-white/20 px-2.5 py-1 rounded-full border border-white/80 dark:border-white/25 shadow-xs backdrop-blur-md">
                        <Clock className="w-3.5 h-3.5 text-[#C48A36]" /> Week 3 of 4
                      </span>
                    </div>

                    <div className="relative z-10 space-y-2 text-xs">
                      {/* Milestone 1 */}
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold shadow-xs">
                            ✓
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M1: Concept & 3D Spatial Renders</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7]">Signed off by Client • Phase 1 Approved</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-emerald-800 dark:text-emerald-300 bg-emerald-100/80 dark:bg-emerald-950/70 px-2 py-0.5 rounded-full border border-emerald-300/80">
                          Complete
                        </span>
                      </div>

                      {/* Milestone 2 */}
                      <div className="p-2.5 bg-white/70 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl flex items-center justify-between shadow-2xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px] font-bold shadow-xs">
                            ✓
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M2: Technical CAD & Material Specs</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7]">Approved by Coordinator • Phase 2 Complete</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-emerald-800 dark:text-emerald-300 bg-emerald-100/80 dark:bg-emerald-950/70 px-2 py-0.5 rounded-full border border-emerald-300/80">
                          Complete
                        </span>
                      </div>

                      {/* Milestone 3 - In Progress */}
                      <div className="p-2.5 bg-white/85 dark:bg-white/15 backdrop-blur-md border border-white/90 dark:border-white/20 rounded-2xl flex items-center justify-between shadow-xs">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-[#C48A36] text-white flex items-center justify-center text-[10px] font-bold animate-pulse shadow-xs">
                            3
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M3: Material Delivery & On-Site Staging</p>
                            <p className="text-[10px] text-[#925C18] dark:text-[#E8A849]">Slat Wall Delivered • Sectional En Route</p>
                          </div>
                        </div>
                        <span className="text-[11px] font-semibold text-[#925C18] dark:text-[#E8A849] bg-white/90 dark:bg-white/20 px-2 py-0.5 rounded-full border border-[#EADBCA] shadow-2xs">
                          In Inspection
                        </span>
                      </div>

                      {/* Milestone 4 - Pending */}
                      <div className="p-2.5 bg-white/50 dark:bg-white/5 backdrop-blur-xs border border-white/60 dark:border-white/10 rounded-2xl flex items-center justify-between opacity-80">
                        <div className="flex items-center gap-2.5">
                          <div className="w-5 h-5 rounded-full bg-[#E5DCD0] dark:bg-[#2E2824] text-[#78716C] dark:text-[#A8A29E] flex items-center justify-center text-[10px] font-bold">
                            4
                          </div>
                          <div>
                            <p className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">M4: Final Punch List & Project Handover</p>
                            <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7]">White-Glove Styling & Final Walkthrough</p>
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
                  /* TAB 3: Dual Human Approval Visual - Luminous Honey & Bronze Glass */
                  <div className="relative bg-white/75 dark:bg-white/10 backdrop-blur-2xl border border-white/90 dark:border-white/20 rounded-[28px] p-5 sm:p-6 space-y-3.5 shadow-[0_16px_40px_-10px_rgba(146,92,24,0.16),inset_0_1px_1px_rgba(255,255,255,0.95)] overflow-hidden">
                    {/* Atmospheric Honey Bronze Glow Blobs */}
                    <div className="absolute -top-12 -right-12 w-60 h-60 bg-gradient-to-br from-[#FCF3E5]/80 via-[#F9E2BE]/50 to-transparent rounded-full blur-2xl pointer-events-none" />
                    <div className="absolute -bottom-12 -left-12 w-64 h-64 bg-gradient-to-tr from-[#E6B873]/50 via-[#F2E7D5]/40 to-transparent rounded-full blur-2xl pointer-events-none" />
                    
                    <div className="relative z-10 flex items-center justify-between pb-3 border-b border-white/70 dark:border-white/15">
                      <div>
                        <p className="text-[11px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#D6D0C7]">
                          Dual Sign-Off Verification
                        </p>
                        <p className="text-sm sm:text-base font-serif font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          Client & Coordinator Verification
                        </p>
                      </div>
                      <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-white/90 dark:bg-white/20 text-[#925C18] dark:text-[#E8A849] border border-white/80 dark:border-white/25 shadow-xs backdrop-blur-md">
                        Both Required
                      </span>
                    </div>

                    <p className="relative z-10 text-xs text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                      StyleSync requires two human sign-offs before any milestone is marked complete. No stage advances without both approvals.
                    </p>

                    <div className="relative z-10 grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1">
                      {/* Key 1: Client Signature */}
                      <div className="p-3 bg-white/75 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-xs">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-[#78716C] dark:text-[#D6D0C7]">Key 1: Client</span>
                          <Check className="w-3.5 h-3.5 text-emerald-600 stroke-[3]" />
                        </div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Julian Vance</p>
                        <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7]">Verified via StyleSync Mobile App</p>
                        <div className="text-[9px] font-mono text-[#78716C] dark:text-[#D6D0C7] bg-white/80 dark:bg-white/10 p-1.5 rounded-lg border border-white/80 dark:border-white/15">
                          SIG: 0x8F92...B31A (Timestamped)
                        </div>
                      </div>

                      {/* Key 2: Project Coordinator */}
                      <div className="p-3 bg-white/75 dark:bg-white/10 backdrop-blur-sm border border-white/80 dark:border-white/15 rounded-2xl space-y-1.5 shadow-xs">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] uppercase font-bold text-[#78716C] dark:text-[#D6D0C7]">Key 2: Coordinator</span>
                          <Check className="w-3.5 h-3.5 text-emerald-600 stroke-[3]" />
                        </div>
                        <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Marissa Chen</p>
                        <p className="text-[10px] text-[#78716C] dark:text-[#D6D0C7]">Verified via StyleSync Ops Suite</p>
                        <div className="text-[9px] font-mono text-[#78716C] dark:text-[#D6D0C7] bg-white/80 dark:bg-white/10 p-1.5 rounded-lg border border-white/80 dark:border-white/15">
                          SIG: 0x4C17...E92D (Inspected)
                        </div>
                      </div>
                    </div>

                    <div className="relative z-10 p-2.5 bg-emerald-50/90 dark:bg-white/10 backdrop-blur-sm border border-emerald-200/80 dark:border-emerald-700/50 rounded-2xl flex items-center gap-2 text-xs text-emerald-800 dark:text-emerald-300 shadow-2xs">
                      <ShieldCheck className="w-4 h-4 shrink-0 text-emerald-700 dark:text-emerald-400" />
                      <span>Both signatures verified. Milestone #3 approved and project advances.</span>
                    </div>
                  </div>
                )}
              </motion.div>

            </motion.div>
          </AnimatePresence>
        </div>

      </div>
    </section>
  );
};
