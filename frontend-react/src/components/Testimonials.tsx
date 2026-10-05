import React from 'react';
import { Star } from 'lucide-react';
import { TESTIMONIALS, FAQ_ITEMS } from '../data/landingData';

interface TestimonialsProps {
  onOpenGetStarted?: () => void;
}

export const Testimonials: React.FC<TestimonialsProps> = () => {
  return (
    <section id="reviews" className="pt-8 pb-16 sm:pt-10 sm:pb-20 bg-transparent border-t border-[#E7E1D7] dark:border-[#2A2522]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-[#F4F0E8] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">
            <span>Verified Perspectives</span>
          </div>
          <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
            Trusted by Homeowners, Designers & Coordinators
          </h2>
          <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] max-w-2xl mx-auto leading-relaxed">
            Real stories from clients who renovated with zero budget surprises and designers who gained protected milestone payouts.
          </p>
        </div>

        {/* Testimonials 3-Card Grid */}
        <div className="mt-8 sm:mt-10 grid grid-cols-1 lg:grid-cols-3 gap-6 sm:gap-8">
          {TESTIMONIALS.map((t) => (
            <div
              key={t.id}
              className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-7 sm:p-8 flex flex-col justify-between transition-all duration-300 hover:shadow-md hover:-translate-y-1"
            >
              <div className="space-y-4">
                {/* 5-Star Rating */}
                <div className="flex items-center gap-1 text-[#C48A36]">
                  {[...Array(t.rating)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-[#C48A36]" />
                  ))}
                </div>

                {/* Quote Body */}
                <p className="font-serif text-lg text-[#1C1917] dark:text-[#FAF8F5] leading-relaxed italic">
                  "{t.quote}"
                </p>
              </div>

              {/* Author Attribution */}
              <div className="pt-6 mt-6 border-t border-[#E7E1D7] dark:border-[#2A2522] flex items-center gap-3.5">
                <img
                  src={t.avatar}
                  alt={t.author}
                  className="w-12 h-12 rounded-full object-cover border border-[#E7E1D7] dark:border-[#352F2B]"
                  referrerPolicy="no-referrer"
                />
                <div>
                  <h4 className="text-sm font-semibold text-[#1C1917] dark:text-[#FAF8F5] leading-tight">
                    {t.author}
                  </h4>
                  <p className="text-xs text-[#925C18] dark:text-[#E8A849] font-medium mt-0.5">
                    {t.role}
                  </p>
                  <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
                    {t.project}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Architectural Studio Partners Strip */}
        <div className="mt-16 pt-12 border-t border-[#E7E1D7] dark:border-[#2A2522]">
          <p className="text-center text-xs uppercase tracking-widest text-[#78716C] dark:text-[#A8A29E] font-semibold mb-8">
            Verified Studios & Architectural Practices On the Platform
          </p>

          <div className="flex flex-wrap items-center justify-center gap-8 sm:gap-14 text-sm font-serif text-[#78716C] dark:text-[#A8A29E]">
            <div className="flex items-center gap-2 hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors">
              <span className="font-bold text-base tracking-widest">STUDIO KANSO</span>
              <span className="text-[10px] font-sans uppercase text-[#C48A36]">Verified</span>
            </div>
            <div className="flex items-center gap-2 hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors">
              <span className="font-bold text-base tracking-widest">ATELIER VANE</span>
              <span className="text-[10px] font-sans uppercase text-[#C48A36]">Verified</span>
            </div>
            <div className="flex items-center gap-2 hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors">
              <span className="font-bold text-base tracking-widest">ROSTOVA GROUP</span>
              <span className="text-[10px] font-sans uppercase text-[#C48A36]">Verified</span>
            </div>
            <div className="flex items-center gap-2 hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors">
              <span className="font-bold text-base tracking-widest">LUMINA ARCHITECTURE</span>
              <span className="text-[10px] font-sans uppercase text-[#C48A36]">Verified</span>
            </div>
            <div className="flex items-center gap-2 hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors">
              <span className="font-bold text-base tracking-widest">FORMA WORKSHOP</span>
              <span className="text-[10px] font-sans uppercase text-[#C48A36]">Verified</span>
            </div>
          </div>
        </div>

        {/* Frequently Asked Questions */}
        <div className="mt-20 max-w-4xl mx-auto space-y-6">
          <div className="text-center space-y-2 mb-10">
            <span className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Clarity & Standards
            </span>
            <h3 className="font-serif text-2xl sm:text-3xl text-[#1C1917] dark:text-[#FAF8F5]">
              Frequently Asked Questions
            </h3>
          </div>

          <div className="space-y-4">
            {FAQ_ITEMS.map((item, idx) => (
              <div
                key={idx}
                className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl p-6 space-y-2 transition-all hover:border-[#C48A36]/40"
              >
                <h4 className="font-serif text-lg font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                  {item.q}
                </h4>
                <p className="text-sm text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
                  {item.a}
                </p>
              </div>
            ))}
          </div>
        </div>

      </div>
    </section>
  );
};
