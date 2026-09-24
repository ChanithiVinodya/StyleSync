import React from 'react';
import { ArrowRight, Smartphone, Sparkles } from 'lucide-react';
import { PersonaRole } from '../types';

interface CtaBannerProps {
  onOpenMobileModal: () => void;
  onOpenPortalModal: (role: PersonaRole) => void;
  onOpenGetStarted: () => void;
}

export const CtaBanner: React.FC<CtaBannerProps> = ({
  onOpenMobileModal,
  onOpenPortalModal,
  onOpenGetStarted,
}) => {
  return (
    <section className="relative overflow-hidden bg-[#1C1917] text-[#FAF8F5] py-20 lg:py-28">
      {/* Subtle ambient light glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[350px] bg-[#C48A36]/10 rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="max-w-3xl mx-auto text-center space-y-8">
          
          {/* Eyebrow */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#2B2723] border border-[#3E3832] text-xs font-semibold text-[#D49B36] uppercase tracking-wider">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Begin Your Transformation</span>
          </div>

          {/* Editorial Display Heading */}
          <h2 className="font-serif text-3xl sm:text-5xl lg:text-6xl font-normal tracking-tight text-[#FAF8F5] leading-tight">
            Ready to redesign your room with certainty and craft?
          </h2>

          <p className="text-base sm:text-lg text-[#D6D3CD] leading-relaxed max-w-2xl mx-auto">
            Experience verified spatial matchmaking, calculated itemized quotes, and guaranteed milestone tracking. No surprise bills. No loose promises.
          </p>

          {/* Action Group */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-2">
            {/* Primary CTA */}
            <button
              onClick={onOpenGetStarted}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-3 px-8 py-4 text-base font-medium text-[#1C1917] bg-[#FAF8F5] hover:bg-[#FFFFFF] rounded-full shadow-lg hover:shadow-xl transition-all group focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#FAF8F5]"
            >
              <span>Get Started</span>
              <ArrowRight className="w-4 h-4 text-[#C48A36] group-hover:translate-x-1 transition-transform" />
            </button>

            {/* Secondary CTA: Mobile App */}
            <button
              onClick={onOpenMobileModal}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-4 text-base font-medium text-[#FAF8F5] bg-[#2E2925] hover:bg-[#3D3732] border border-[#443D36] rounded-full transition-colors focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#FAF8F5]"
            >
              <Smartphone className="w-4 h-4 text-[#C48A36]" />
              <span>Get the Mobile App (iOS / Android)</span>
            </button>
          </div>

          {/* Designer / Coordinator Prompt */}
          <div className="pt-4 flex flex-wrap items-center justify-center gap-6 text-xs text-[#A8A29E]">
            <button
              onClick={() => onOpenPortalModal('designer')}
              className="hover:text-[#FAF8F5] underline underline-offset-4 decoration-[#C48A36]/60 transition-colors"
            >
              Are you an interior designer? Apply to join the verified network →
            </button>
            <span className="hidden sm:inline text-[#443D36]">•</span>
            <button
              onClick={() => onOpenPortalModal('coordinator')}
              className="hover:text-[#FAF8F5] underline underline-offset-4 decoration-[#C48A36]/60 transition-colors"
            >
              Project Coordinator Sign In →
            </button>
          </div>

        </div>
      </div>
    </section>
  );
};
