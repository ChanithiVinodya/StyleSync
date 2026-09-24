import React, { useState } from 'react';
import { Navbar } from '../components/Navbar';
import { Hero } from '../components/Hero';
import { Features } from '../components/Features';
import { Audience } from '../components/Audience';
import { CaseStudies } from '../components/CaseStudies';
import { TrustSection } from '../components/TrustSection';
import { Testimonials } from '../components/Testimonials';
import { CtaBanner } from '../components/CtaBanner';
import { Footer } from '../components/Footer';
import { MobileAppModal } from '../components/MobileAppModal';
import { PortalAuthModal } from '../components/PortalAuthModal';
import { GetStartedModal } from '../components/GetStartedModal';
import { InteractiveTriangleTiles } from '../components/InteractiveTriangleTiles';
import { PersonaRole } from '../types';

export default function LandingPage() {
  const [isMobileModalOpen, setIsMobileModalOpen] = useState(false);
  const [isPortalModalOpen, setIsPortalModalOpen] = useState(false);
  const [portalRole, setPortalRole] = useState<PersonaRole>('designer');
  const [isGetStartedModalOpen, setIsGetStartedModalOpen] = useState(false);

  const handleOpenMobileModal = () => {
    setIsMobileModalOpen(true);
  };

  const handleOpenPortalModal = (role: PersonaRole = 'designer') => {
    setPortalRole(role);
    setIsPortalModalOpen(true);
  };

  const handleOpenGetStarted = () => {
    setIsGetStartedModalOpen(true);
  };

  return (
    <div className="relative min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] flex flex-col selection:bg-[#E8DDD1] dark:selection:bg-[#3E342B] selection:text-[#1C1917] dark:selection:text-[#FAF8F5] transition-colors duration-500">
      {/* Interactive Faded Triangular Background Tile Mesh */}
      <InteractiveTriangleTiles />

      {/* Editorial Navigation Header */}
      <Navbar
        onOpenPortalModal={handleOpenPortalModal}
        onOpenGetStarted={handleOpenGetStarted}
      />

      {/* Main Content Sections adhering to required flow */}
      <main className="flex-1 relative z-10">
        {/* 1. Hero Section */}
        <Hero
          onOpenMobileModal={handleOpenMobileModal}
          onOpenGetStarted={handleOpenGetStarted}
        />

        {/* 2. Features Section (Deterministic Engine, Itemized Quotes, Milestones, Dual Approval) */}
        <Features onOpenGetStarted={handleOpenGetStarted} />

        {/* 3. Audience Section (4 Personas: Clients, Designers, Coordinators, Admins) */}
        <Audience
          onOpenMobileModal={handleOpenMobileModal}
          onOpenPortalModal={handleOpenPortalModal}
        />

        {/* 4. Case Studies Section (Real interior transformations with before/after toggles) */}
        <CaseStudies onOpenGetStarted={handleOpenGetStarted} />

        {/* 5. Trust & Credibility Section (Replacing the generic cart/plug/funnel icons) */}
        <TrustSection onOpenGetStarted={handleOpenGetStarted} />

        {/* 6. Social Proof / Testimonials & Verification */}
        <Testimonials onOpenGetStarted={handleOpenGetStarted} />

        {/* 7. Final Call to Action Banner */}
        <CtaBanner
          onOpenMobileModal={handleOpenMobileModal}
          onOpenPortalModal={handleOpenPortalModal}
          onOpenGetStarted={handleOpenGetStarted}
        />
      </main>

      {/* 8. Comprehensive Editorial Footer */}
      <Footer
        onOpenMobileModal={handleOpenMobileModal}
        onOpenPortalModal={handleOpenPortalModal}
      />

      {/* Interactive Modals */}
      <MobileAppModal
        isOpen={isMobileModalOpen}
        onClose={() => setIsMobileModalOpen(false)}
      />

      <PortalAuthModal
        isOpen={isPortalModalOpen}
        defaultRole={portalRole}
        onClose={() => setIsPortalModalOpen(false)}
      />

      <GetStartedModal
        isOpen={isGetStartedModalOpen}
        onClose={() => setIsGetStartedModalOpen(false)}
        onOpenMobileModal={handleOpenMobileModal}
        onOpenPortalModal={handleOpenPortalModal}
      />
    </div>
  );
}
