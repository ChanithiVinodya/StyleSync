import React from 'react';
import { 
  ShieldCheck, 
  Calculator, 
  Cpu, 
  FileCheck, 
  UserCheck, 
  CheckCircle2
} from 'lucide-react';

interface TrustSectionProps {
  onOpenGetStarted?: () => void;
}

export const TrustSection: React.FC<TrustSectionProps> = () => {
  return (
    <section id="trust" className="pt-8 pb-16 sm:pt-10 sm:pb-20 bg-[#F4F0E8]/40 dark:bg-[#181513]/40 border-t border-[#E7E1D7] dark:border-[#2A2522]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <div className="inline-flex items-center gap-2 px-3 py-0.5 rounded-full bg-[#EFEAE1] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">
            <ShieldCheck className="w-3.5 h-3.5 text-[#C48A36]" />
            <span>Platform Integrity & Milestone Governance</span>
          </div>
          <h2 className="font-serif text-2xl sm:text-3xl lg:text-[38px] lg:leading-tight text-[#1C1917] dark:text-[#FAF8F5] tracking-tight">
            How StyleSync Protects Every Dollar and Detail
          </h2>
          <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D0C7] max-w-2xl mx-auto leading-relaxed">
            Renovations fail when prices are guessed, communications are scattered, and payments are unprotected. StyleSync enforces deterministic business rules and human checks at every stage.
          </p>
        </div>

        {/* 4 Pillars Grid (Replacing generic integration icons!) */}
        <div className="mt-8 sm:mt-10 grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
          
          {/* Pillar 1: Dual Human Approval */}
          <div className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 space-y-6 transition-all hover:shadow-md">
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
                <UserCheck className="w-6 h-6" />
              </div>
              <span className="text-[11px] font-bold uppercase tracking-wider px-3 py-1 rounded-full bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] text-[#78716C] dark:text-[#A8A29E]">
                Pillar 01
              </span>
            </div>
            
            <div className="space-y-2">
              <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
                Dual Human Approval at Every Stage
              </h3>
              <p className="text-xs font-semibold text-[#925C18] dark:text-[#E8A849]">
                Two-Key Authorization for Every Payment & Revision
              </p>
            </div>

            <p className="text-sm text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
              No contractor invoice is paid and no design milestone is finalized by an algorithm alone. Payouts require both the client's approval and physical inspection sign-off from your assigned StyleSync Project Coordinator.
            </p>

            <div className="p-4 bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl space-y-2 text-xs">
              <div className="flex items-center gap-2 text-emerald-800 dark:text-emerald-300 font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Client signature verifies design aesthetic satisfaction</span>
              </div>
              <div className="flex items-center gap-2 text-emerald-800 dark:text-emerald-300 font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Coordinator signature verifies code compliance and material delivery</span>
              </div>
            </div>
          </div>

          {/* Pillar 2: Calculated Quotes */}
          <div className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 space-y-6 transition-all hover:shadow-md">
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
                <Calculator className="w-6 h-6" />
              </div>
              <span className="text-[11px] font-bold uppercase tracking-wider px-3 py-1 rounded-full bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] text-[#78716C] dark:text-[#A8A29E]">
                Pillar 02
              </span>
            </div>
            
            <div className="space-y-2">
              <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
                Calculated, Not Guessed, Quotations
              </h3>
              <p className="text-xs font-semibold text-[#925C18] dark:text-[#E8A849]">
                Unit-Level Sourcing with Contractually Locked Ceilings
              </p>
            </div>

            <p className="text-sm text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
              Traditional estimates inflate unexpectedly because of ballpark allowances. StyleSync pulls live trade prices from verified furniture manufacturers and regional labor indexes to output fixed-price contracts.
            </p>

            <div className="p-4 bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl space-y-2 text-xs">
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Zero unapproved change orders allowed in the contract system</span>
              </div>
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Standard 5% contingency fund pre-allocated and returned if unused</span>
              </div>
            </div>
          </div>

          {/* Pillar 3: Deterministic Rule Engine */}
          <div className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 space-y-6 transition-all hover:shadow-md">
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
                <Cpu className="w-6 h-6" />
              </div>
              <span className="text-[11px] font-bold uppercase tracking-wider px-3 py-1 rounded-full bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] text-[#78716C] dark:text-[#A8A29E]">
                Pillar 03
              </span>
            </div>
            
            <div className="space-y-2">
              <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
                Deterministic Matching, Not Loose Prompts
              </h3>
              <p className="text-xs font-semibold text-[#925C18] dark:text-[#E8A849]">
                Mathematical Spatial Compatibility Scoring
              </p>
            </div>

            <p className="text-sm text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
              Instead of generic chatbots hallucinating interior recommendations, our engine executes hard business rules: style ontology matching, room orientation, spatial constraints, and designer workload limits.
            </p>

            <div className="p-4 bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl space-y-2 text-xs">
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Capacity-regulated: Designers capped at 4 concurrent projects</span>
              </div>
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Verified licensing, insurance, and physical portfolio audits</span>
              </div>
            </div>
          </div>

          {/* Pillar 4: Full Audit History */}
          <div className="bg-[#FFFFFF] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-8 space-y-6 transition-all hover:shadow-md">
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[#925C18] dark:text-[#E8A849]">
                <FileCheck className="w-6 h-6" />
              </div>
              <span className="text-[11px] font-bold uppercase tracking-wider px-3 py-1 rounded-full bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] text-[#78716C] dark:text-[#A8A29E]">
                Pillar 04
              </span>
            </div>
            
            <div className="space-y-2">
              <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
                Full Cryptographic Audit History
              </h3>
              <p className="text-xs font-semibold text-[#925C18] dark:text-[#E8A849]">
                Immutable Ledger of Specifications & Delivery Slips
              </p>
            </div>

            <p className="text-sm text-[#57534E] dark:text-[#D6D0C7] leading-relaxed">
              Every message, room measurement, material specification sheet, shipping BOL, and milestone photo is recorded in an immutable project log. Full transparency for all parties.
            </p>

            <div className="p-4 bg-[#FAF8F5] dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl space-y-2 text-xs">
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Timestamped photo evidence logged before any milestone approval</span>
              </div>
              <div className="flex items-center gap-2 text-[#44403C] dark:text-[#D6D0C7] font-medium">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span>Full transaction history downloadable for warranty and insurance</span>
              </div>
            </div>
          </div>

        </div>

        {/* Security Flow Diagram Bar */}
        <div className="mt-12 bg-[#FAF8F5] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-8">
          <div className="text-center space-y-2 mb-8">
            <span className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              The StyleSync Guarantee Path
            </span>
            <h3 className="font-serif text-2xl text-[#1C1917] dark:text-[#FAF8F5]">
              End-to-End Milestone Governance
            </h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-5 gap-4 relative">
            <div className="p-4 bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl text-center space-y-2">
              <span className="w-7 h-7 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-xs font-bold mx-auto">
                1
              </span>
              <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Room Brief Ingest</p>
              <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">Client uploads room photos & dimensions in mobile app.</p>
            </div>

            <div className="p-4 bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl text-center space-y-2">
              <span className="w-7 h-7 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-xs font-bold mx-auto">
                2
              </span>
              <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Deterministic Match</p>
              <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">Engine shortlists designers based on style fit & live capacity.</p>
            </div>

            <div className="p-4 bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl text-center space-y-2">
              <span className="w-7 h-7 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-xs font-bold mx-auto">
                3
              </span>
              <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Calculated Quote</p>
              <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">Material & labor catalog calculation with locked ceiling.</p>
            </div>

            <div className="p-4 bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl text-center space-y-2">
              <span className="w-7 h-7 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-xs font-bold mx-auto">
                4
              </span>
              <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Tracked Milestones</p>
              <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">Shipments and on-site staging tracked live at each stage.</p>
            </div>

            <div className="p-4 bg-white dark:bg-[#25201C] border border-[#E7E1D7] dark:border-[#352F2B] rounded-2xl text-center space-y-2">
              <span className="w-7 h-7 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-xs font-bold mx-auto">
                5
              </span>
              <p className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">Dual Sign-off Approval</p>
              <p className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">Client + Coordinator sign off before stage completion.</p>
            </div>
          </div>
        </div>

      </div>
    </section>
  );
};
