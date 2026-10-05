import React, { useState } from 'react';
import { Sparkles, ArrowRight, ArrowLeftRight, MapPin, User } from 'lucide-react';
import { CASE_STUDIES } from '../data/landingData';

interface CaseStudiesProps {
  onOpenGetStarted: () => void;
}

export const CaseStudies: React.FC<CaseStudiesProps> = ({ onOpenGetStarted }) => {
  const [viewBeforeState, setViewBeforeState] = useState<Record<string, boolean>>({});

  const toggleViewBefore = (id: string) => {
    setViewBeforeState((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  return (
    <section id="transformations" className="pt-8 pb-16 sm:pt-10 sm:pb-20 bg-transparent border-t border-[#E7E1D7] dark:border-[#2A2522]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-8 sm:mb-10 gap-5">
          <div className="space-y-2.5 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-[#F4F0E8] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">
              <span>Verified Transformations</span>
            </div>
            <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
              Real Rooms. Matched Designers. Zero Budget Creep.
            </h2>
            <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
              Every room transformation on StyleSync is backed by calculated material costs, certified trade installation, and milestone verification.
            </p>
          </div>

          <button
            onClick={onOpenGetStarted}
            className="self-start md:self-auto inline-flex items-center gap-2 px-5 py-2.5 text-xs sm:text-sm font-medium text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] rounded-full shadow-xs transition-all group"
          >
            <span>Match Your Room</span>
            <ArrowRight className="w-4 h-4 text-[#C48A36] group-hover:translate-x-1 transition-transform" />
          </button>
        </div>

        {/* 3 Case Study Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {CASE_STUDIES.map((study) => {
            const isShowingBefore = !!viewBeforeState[study.id];

            return (
              <div
                key={study.id}
                className="bg-[#FFFFFF] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2A2522] rounded-3xl overflow-hidden flex flex-col justify-between transition-all duration-300 hover:shadow-lg hover:-translate-y-1 group"
              >
                {/* Image Container with Before/After Toggle */}
                <div className="relative aspect-4/3 overflow-hidden bg-[#EFEAE1] dark:bg-[#25201C]">
                  <img
                    src={isShowingBefore ? study.beforeImage : study.afterImage}
                    alt={`${study.title} ${isShowingBefore ? 'before renovation' : 'completed makeover'}`}
                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-103"
                    referrerPolicy="no-referrer"
                  />

                  {/* Gradient Overlay */}
                  <div className="absolute inset-0 bg-gradient-to-t from-[#1C1917]/70 via-transparent to-transparent pointer-events-none" />

                  {/* Status Indicator Tag */}
                  <div className="absolute top-4 left-4">
                    <span
                      className={`text-[11px] font-bold uppercase tracking-wider px-3 py-1 rounded-full backdrop-blur-md shadow-xs ${
                        isShowingBefore
                          ? 'bg-amber-950/80 text-amber-200 border border-amber-600/40'
                          : 'bg-[#1C1917]/80 text-[#FAF8F5] border border-white/20'
                      }`}
                    >
                      {isShowingBefore ? 'Original State (Before)' : 'StyleSync Makeover'}
                    </span>
                  </div>

                  {/* Match Score Badge */}
                  <div className="absolute top-4 right-4 bg-[#FAF8F5]/95 dark:bg-[#1E1B18]/95 backdrop-blur-md px-2.5 py-1 rounded-full border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5] flex items-center gap-1 shadow-xs">
                    <Sparkles className="w-3.5 h-3.5 text-[#C48A36]" />
                    <span>{study.matchScore}% Match</span>
                  </div>

                  {/* Interactive Before/After Toggle Button */}
                  <div className="absolute bottom-3 right-3">
                    <button
                      onClick={() => toggleViewBefore(study.id)}
                      className="px-3 py-1.5 rounded-full bg-[#FAF8F5]/90 hover:bg-[#FFFFFF] dark:bg-[#25201C]/90 dark:hover:bg-[#2F2925] text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] backdrop-blur-md shadow-md flex items-center gap-1.5 transition-all border border-[#E7E1D7] dark:border-[#3E3731] active:scale-95"
                      title="Click to toggle before/after photos"
                    >
                      <ArrowLeftRight className="w-3.5 h-3.5 text-[#C48A36]" />
                      <span>{isShowingBefore ? 'View Makeover' : 'View Before'}</span>
                    </button>
                  </div>

                  {/* Room Type Pill */}
                  <div className="absolute bottom-3 left-4 text-[#FAF8F5]">
                    <p className="text-xs font-medium text-white/90 drop-shadow-xs">{study.roomType}</p>
                  </div>
                </div>

                {/* Content Details */}
                <div className="p-6 sm:p-7 space-y-4 flex-1 flex flex-col justify-between">
                  <div className="space-y-3">
                    {/* Tags */}
                    <div className="flex flex-wrap gap-1.5">
                      {study.tags.map((t, idx) => (
                        <span
                          key={idx}
                          className="text-[10px] font-medium px-2 py-0.5 rounded-md bg-[#F4F0E8] dark:bg-[#24201D] text-[#57534E] dark:text-[#D6D0C7] border border-[#E7E1D7] dark:border-[#352F2B]"
                        >
                          {t}
                        </span>
                      ))}
                    </div>

                    {/* Title & Location */}
                    <div>
                      <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5] leading-tight">
                        {study.title}
                      </h3>
                      <p className="text-xs text-[#78716C] dark:text-[#A8A29E] flex items-center gap-1 mt-1">
                        <MapPin className="w-3.5 h-3.5 text-[#C48A36]" />
                        <span>{study.location}</span>
                      </p>
                    </div>

                    {/* Designer Attribution */}
                    <div className="p-3 bg-[#FAF8F5] dark:bg-[#221E1B] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <User className="w-3.5 h-3.5 text-[#78716C] dark:text-[#A8A29E]" />
                        <div>
                          <span className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">{study.designerName}</span>
                          <span className="text-[11px] text-[#78716C] dark:text-[#A8A29E]"> • {study.designerStudio}</span>
                        </div>
                      </div>
                      <span className="text-[10px] font-semibold text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-sm">
                        Verified Pro
                      </span>
                    </div>

                    {/* Key Highlight */}
                    <p className="text-xs text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                      {study.highlight}
                    </p>
                  </div>

                  {/* Financial & Timeline Metrics Bar */}
                  <div className="pt-4 border-t border-[#E7E1D7] dark:border-[#2A2522] space-y-3">
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div className="p-2.5 rounded-xl bg-[#FAF8F5] dark:bg-[#221E1B] border border-[#E7E1D7] dark:border-[#2E2824]">
                        <span className="text-[10px] uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] font-semibold block">
                          Contract Ceiling
                        </span>
                        <span className="font-serif text-base font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          {study.finalBudget}
                        </span>
                        <span className="block text-[10px] text-emerald-700 dark:text-emerald-400 font-medium">
                          100% on budget
                        </span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-[#FAF8F5] dark:bg-[#221E1B] border border-[#E7E1D7] dark:border-[#2E2824]">
                        <span className="text-[10px] uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] font-semibold block">
                          Timeline
                        </span>
                        <span className="font-serif text-base font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                          {study.timelineWeeks} Weeks
                        </span>
                        <span className="block text-[10px] text-emerald-700 dark:text-emerald-400 font-medium">
                          All milestones met
                        </span>
                      </div>
                    </div>

                    {/* Verified Quote Snippet */}
                    <p className="text-[11px] italic text-[#78716C] dark:text-[#D6D0C7] border-l-2 border-[#C48A36] pl-2.5 leading-snug">
                      "{study.clientQuote}"
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

      </div>
    </section>
  );
};
