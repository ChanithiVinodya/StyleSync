import React from 'react';
import { ArrowUp, Smartphone } from 'lucide-react';
import { PersonaRole } from '../types';
import { Logo } from './Logo';

interface FooterProps {
  onOpenMobileModal: () => void;
  onOpenPortalModal: (role: PersonaRole) => void;
}

export const Footer: React.FC<FooterProps> = ({
  onOpenMobileModal,
  onOpenPortalModal,
}) => {
  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <footer className="bg-[#141210] text-[#A8A29E] border-t border-[#292522] pt-16 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Main Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 pb-12 border-b border-[#292522]">
          
          {/* Col 1: Brand & Architecture Summary */}
          <div className="lg:col-span-2 space-y-4">
            <Logo variant="light" size="md" showSubtitle={true} />

            <p className="text-sm text-[#8C8681] leading-relaxed max-w-sm">
              The verified interior design and room makeover marketplace. Pairing discerning homeowners with elite designers through deterministic matching, calculated quotations, and milestone verification.
            </p>

            <div className="p-3.5 bg-[#1C1917] border border-[#2B2622] rounded-xl text-xs space-y-1 max-w-sm">
              <div className="flex items-center gap-1.5 text-[#FAF8F5] font-semibold">
                <Smartphone className="w-3.5 h-3.5 text-[#C48A36]" />
                <span>Client Experience</span>
              </div>
              <p className="text-[#8C8681] text-[11px] leading-snug">
                Homeowners submit room photos and track makeovers via the iOS & Android mobile application.
              </p>
            </div>
          </div>

          {/* Col 2: Product & Engine */}
          <div className="space-y-3">
            <h4 className="text-xs uppercase tracking-widest text-[#FAF8F5] font-semibold">
              The Engine
            </h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="#how-it-works" className="hover:text-[#FAF8F5] transition-colors">
                  Match-Score Algorithm
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="hover:text-[#FAF8F5] transition-colors">
                  Calculated Quotations
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="hover:text-[#FAF8F5] transition-colors">
                  Milestone Tracking
                </a>
              </li>
              <li>
                <a href="#how-it-works" className="hover:text-[#FAF8F5] transition-colors">
                  Material Delivery Tracking
                </a>
              </li>
              <li>
                <a href="#trust" className="hover:text-[#FAF8F5] transition-colors">
                  Dual Human Approval
                </a>
              </li>
            </ul>
          </div>

          {/* Col 3: Personas & Portals */}
          <div className="space-y-3">
            <h4 className="text-xs uppercase tracking-widest text-[#FAF8F5] font-semibold">
              Portals & Roles
            </h4>
            <ul className="space-y-2 text-sm">
              <li>
                <button
                  onClick={onOpenMobileModal}
                  className="hover:text-[#FAF8F5] transition-colors flex items-center gap-1.5"
                >
                  <span>Clients (Mobile App)</span>
                  <span className="text-[10px] text-[#C48A36] bg-[#2E2925] px-1.5 py-0.5 rounded-sm">iOS/Android</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenPortalModal('designer')}
                  className="hover:text-[#FAF8F5] transition-colors"
                >
                  Designers (Web Studio)
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenPortalModal('coordinator')}
                  className="hover:text-[#FAF8F5] transition-colors"
                >
                  Project Coordinators
                </button>
              </li>
              <li>
                <button
                  onClick={() => onOpenPortalModal('admin')}
                  className="hover:text-[#FAF8F5] transition-colors"
                >
                  Platform Governance / Admin
                </button>
              </li>
              <li>
                <a href="#transformations" className="hover:text-[#FAF8F5] transition-colors">
                  Room Case Studies
                </a>
              </li>
            </ul>
          </div>

          {/* Col 4: Trust & Standards */}
          <div className="space-y-3">
            <h4 className="text-xs uppercase tracking-widest text-[#FAF8F5] font-semibold">
              Trust & Standards
            </h4>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="#trust" className="hover:text-[#FAF8F5] transition-colors">
                  Designer Verification Protocol
                </a>
              </li>
              <li>
                <a href="#trust" className="hover:text-[#FAF8F5] transition-colors">
                  Locked Price Ceilings
                </a>
              </li>
              <li>
                <a href="#trust" className="hover:text-[#FAF8F5] transition-colors">
                  Cryptographic Audit Ledger
                </a>
              </li>
              <li>
                <a href="#trust" className="hover:text-[#FAF8F5] transition-colors">
                  Project Terms & Conditions
                </a>
              </li>
              <li>
                <a href="#reviews" className="hover:text-[#FAF8F5] transition-colors">
                  Verified Client Reviews
                </a>
              </li>
            </ul>
          </div>

        </div>

        {/* Bottom Bar: Copyright, Back to Top */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#78716C]">
          <div className="flex flex-wrap items-center gap-4">
            <span>&copy; {new Date().getFullYear()} StyleSync Technologies, Inc. All rights reserved.</span>
            <span className="hidden sm:inline">•</span>
            <span>Privacy Policy</span>
            <span className="hidden sm:inline">•</span>
            <span>Terms of Service</span>
            <span className="hidden sm:inline">•</span>
            <span>Dispute Mediation Rules</span>
          </div>

          <button
            onClick={scrollToTop}
            className="flex items-center gap-1 text-[#A8A29E] hover:text-[#FAF8F5] transition-colors px-3 py-1.5 rounded-full border border-[#292522] bg-[#1C1917]"
          >
            <span>Back to Top</span>
            <ArrowUp className="w-3.5 h-3.5" />
          </button>
        </div>

      </div>
    </footer>
  );
};
