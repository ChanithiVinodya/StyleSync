import React from 'react';
import { ArrowRight, Smartphone, ArrowUpRight, Sparkles, ShieldCheck } from 'lucide-react';
import { HERO_DATA } from '../data/landingData';

interface HeroProps {
  onOpenMobileModal: () => void;
  onOpenGetStarted: () => void;
}

interface DesignPillar {
  id: string;
  style: string;
  sublabel: string;
  room: string;
  designer: string;
  image: string;
  alt: string;
  objectPosition: string;
  offsetClass: string;
  heightClass: string;
}

const DESIGN_PILLARS: DesignPillar[] = [
  {
    id: 'japandi-living',
    style: 'Japandi',
    sublabel: 'Japandi Calm',
    room: 'Living Room',
    designer: 'Studio Kanso',
    image: '/assets/Japandi Living Room_.jpg',
    alt: 'Serene Japandi living room with warm minimalist low-profile furniture, natural wood tones, organic textures, and peaceful diffused sunlight',
    objectPosition: 'center 50%',
    offsetClass: 'mt-10 sm:mt-14',
    heightClass: 'h-[290px] sm:h-[400px] lg:h-[440px] xl:h-[470px]',
  },
  {
    id: 'industrial-kitchen',
    style: 'Industrial',
    sublabel: 'Industrial Loft',
    room: 'Kitchen & Island',
    designer: 'Aura Architects',
    image: '/assets/industrial Kitchen & Island.jpg',
    alt: 'Contemporary industrial loft kitchen featuring dark metal fixtures, custom island cabinetry, architectural pendant lighting, and exposed masonry elements',
    objectPosition: 'center 50%',
    offsetClass: 'mt-0',
    heightClass: 'h-[340px] sm:h-[470px] lg:h-[515px] xl:h-[545px]',
  },
  {
    id: 'mid-century-modern',
    style: 'Mid-Century Modern',
    sublabel: 'Mid-Century Modern',
    room: 'Home Office / Study',
    designer: 'Vanguard Atelier',
    image: '/assets/mid-century-modern.png',
    alt: 'Warm mid-century modern home office study showcasing rich wood desk craftsmanship, tailored accent chair, built-in library shelving, and warm natural illumination',
    objectPosition: 'center 42%',
    offsetClass: 'mt-12 sm:mt-16',
    heightClass: 'h-[300px] sm:h-[415px] lg:h-[455px] xl:h-[485px]',
  },
  {
    id: 'coastal-bedroom',
    style: 'Coastal',
    sublabel: 'Coastal Light',
    room: 'Bedroom',
    designer: 'Maison Forma',
    image: '/assets/Coastal-bedroom.jpg',
    alt: 'Airy coastal bedroom retreat with light linen bedding, soothing neutral color palette, natural woven decor accents, and soft morning sunlight',
    objectPosition: 'center 50%',
    offsetClass: 'mt-4 sm:mt-6',
    heightClass: 'h-[320px] sm:h-[435px] lg:h-[475px] xl:h-[505px]',
  },
];

export const Hero: React.FC<HeroProps> = ({ onOpenMobileModal, onOpenGetStarted }) => {
  return (
    <section className="relative overflow-hidden pt-4 sm:pt-6 pb-12 lg:pt-6 lg:pb-16">
      {/* Subtle atmospheric golden ambient lighting in background - removed white gradient in dark mode */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[900px] h-[550px] bg-gradient-to-b from-[#F3ECE0]/70 via-[#EFE6D5]/30 to-transparent dark:hidden rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10 items-center">

          {/* Left Column: Editorial Value Proposition & Actions */}
          <div className="lg:col-span-7 xl:col-span-6 space-y-6 sm:space-y-6.5 text-left">

            {/* Tagline Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#F4F0E8] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-medium text-[#78716C] dark:text-[#A8A29E] shadow-2xs transition-colors duration-500">
              <span className="w-2 h-2 rounded-full bg-[#C48A36] animate-pulse" />
              <span className="tracking-wide uppercase text-[11px] font-semibold text-[#57534E] dark:text-[#D6D0C7]">
                {HERO_DATA.eyebrow}
              </span>
            </div>

            {/* Main Headline */}
            <h1 className="font-serif text-[22px] min-[380px]:text-[24px] sm:text-3xl md:text-4xl lg:text-[40px] xl:text-[46px] font-normal tracking-tight text-[#1C1917] dark:text-[#FAF8F5] leading-[1.14] transition-colors duration-500">
              <span className="block whitespace-nowrap">
                Interior design,{' '}
                <span className="relative inline-block">
                  <span className="italic font-normal text-[#925C18] dark:text-[#E8A849] transition-colors duration-500">perfectly matched.</span>
                  <span className="absolute -bottom-1 left-0 w-full h-[2.5px] bg-gradient-to-r from-[#C48A36] via-[#D49B36] to-transparent rounded-full" />
                </span>
              </span>
              <span className="block mt-1 sm:mt-1.5 text-[#1C1917] dark:text-[#FAF8F5] transition-colors duration-500">
                Reliably delivered.
              </span>
            </h1>

            {/* Value Proposition Description with Eye-Catching Journey Micro-Flow */}
            <div className="space-y-3.5 max-w-xl">
              <p className="text-base sm:text-[17px] text-[#57534E] dark:text-[#A8A29E] leading-relaxed font-normal transition-colors duration-500">
                Share your room and your style. Get matched with a designer who fits. Watch your renovation move forward, milestone by milestone, with human sign-off at every stage.
              </p>

              {/* Eye-catching 3-Beat Visual Progression Card */}
              <div className="p-3 sm:p-3.5 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xs hover:border-[#D6CAB8] dark:hover:border-[#3E3731] transition-colors duration-500">
                <div className="grid grid-cols-3 gap-2 sm:gap-3 text-left">
                  {/* Step 1 */}
                  <div className="space-y-0.5">
                    <div className="flex items-center gap-1.5">
                      <span className="w-5 h-5 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[10px] font-bold text-[#925C18] dark:text-[#E8A849]">
                        1
                      </span>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                        Your Style
                      </span>
                    </div>
                    <p className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] leading-tight pt-0.5">
                      Share room & vision
                    </p>
                  </div>

                  {/* Step 2 */}
                  <div className="space-y-0.5 border-l border-[#E7E1D7] dark:border-[#2C2723] pl-2 sm:pl-3">
                    <div className="flex items-center gap-1.5">
                      <span className="w-5 h-5 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[10px] font-bold text-[#925C18] dark:text-[#E8A849]">
                        2
                      </span>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                        Match Fit
                      </span>
                    </div>
                    <p className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] leading-tight pt-0.5">
                      Matched with designer
                    </p>
                  </div>

                  {/* Step 3 */}
                  <div className="space-y-0.5 border-l border-[#E7E1D7] dark:border-[#2C2723] pl-2 sm:pl-3">
                    <div className="flex items-center gap-1.5">
                      <span className="w-5 h-5 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] flex items-center justify-center text-[10px] font-bold text-[#925C18] dark:text-[#E8A849]">
                        3
                      </span>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                        Milestones
                      </span>
                    </div>
                    <p className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] leading-tight pt-0.5">
                      Human sign-off per stage
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons: Unified Primary CTA + Secondary Mobile CTA */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3.5 pt-0.5">
              {/* PRIMARY CTA - Repeated consistently */}
              <button
                onClick={onOpenGetStarted}
                className="inline-flex items-center justify-center gap-2.5 px-7 py-3.5 text-sm sm:text-base font-medium text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] rounded-full shadow-md hover:shadow-lg transition-all group focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] dark:focus-visible:ring-[#FAF8F5]"
              >
                <span>Get Started</span>
                <ArrowRight className="w-4 h-4 text-[#C48A36] group-hover:translate-x-1 transition-transform" />
              </button>

              {/* SECONDARY CTA - Client Mobile App */}
              <button
                onClick={onOpenMobileModal}
                className="inline-flex items-center justify-center gap-2 px-5 py-3.5 text-sm sm:text-base font-medium text-[#1C1917] dark:text-[#FAF8F5] bg-[#F4F0E8] dark:bg-[#1E1B18] hover:bg-[#EAE4D7] dark:hover:bg-[#2A2521] border border-[#E7E1D7] dark:border-[#2E2824] rounded-full transition-colors duration-500 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] dark:focus-visible:ring-[#FAF8F5]"
              >
                <Smartphone className="w-4 h-4 text-[#C48A36]" />
                <span>Get the Mobile App</span>
              </button>
            </div>

            {/* Client / Designer Scope Indicator */}
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E] flex items-center gap-2 transition-colors duration-500">
              <ShieldCheck className="w-4 h-4 text-[#C48A36] shrink-0" />
              <span>
                <strong>Clients:</strong> Submit & track on iOS & Android.{' '}
                <strong>Designers & Staff:</strong> Sign in via Web.
              </span>
            </p>

            {/* Credibility Metric Counters */}
            <div className="grid grid-cols-3 gap-3 pt-5 border-t border-[#E7E1D7]/80 dark:border-[#2C2723] transition-colors duration-500">
              {HERO_DATA.stats.map((stat, index) => (
                <div key={index} className="space-y-0.5">
                  <div className="font-serif text-2xl sm:text-[26px] font-semibold text-[#1C1917] dark:text-[#FAF8F5] transition-colors duration-500">
                    {stat.value}
                  </div>
                  <div className="text-xs font-medium text-[#44403C] dark:text-[#D6D0C7] transition-colors duration-500">
                    {stat.label}
                  </div>
                  <div className="text-[11px] text-[#78716C] dark:text-[#8C8681] transition-colors duration-500">
                    {stat.subtext}
                  </div>
                </div>
              ))}
            </div>

          </div>

          {/* Right Column: 4 Ellipse Shape Interior Design Pillars with Staggered Rhythms */}
          <div className="lg:col-span-5 xl:col-span-6 relative">
            {/* Gallery Container */}
            <div className="relative mx-auto max-w-xl lg:max-w-none pt-2 pb-4 px-1 sm:px-2">

              {/* Decorative Subtle Underlay Warm Glow - removed white gradient in dark mode */}
              <div className="absolute -inset-4 bg-gradient-to-tr from-[#C48A36]/12 via-[#F4F0E8]/60 to-transparent dark:from-[#C48A36]/8 dark:via-transparent dark:to-transparent rounded-[50px] blur-2xl pointer-events-none" />

              {/* 4 Ellipse Pillars Grid */}
              <div className="relative grid grid-cols-4 gap-2 sm:gap-3.5 lg:gap-3 xl:gap-4 items-start">

                {DESIGN_PILLARS.map((pillar, index) => {
                  const isSecond = index === 1;

                  return (
                    <div
                      key={pillar.id}
                      className={`relative flex flex-col items-center ${pillar.offsetClass}`}
                    >
                      {/* Floating Interactive Circle Arrow Button (Anchored on Pillar 2, exactly as in reference image) */}
                      {isSecond && (
                        <button
                          type="button"
                          onClick={onOpenGetStarted}
                          aria-label="Match room style and explore designers"
                          className="absolute top-[38%] -left-4 sm:-left-6 z-30 w-10 h-10 sm:w-13 sm:h-13 rounded-full bg-[#1C1917] dark:bg-[#FAF8F5] text-[#FAF8F5] dark:text-[#1C1917] flex items-center justify-center shadow-xl border-2 border-[#FAF8F5] dark:border-[#1C1917] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] hover:scale-110 active:scale-95 transition-all duration-300 cursor-pointer group/arrow"
                          title="Match your interior style"
                        >
                          <ArrowUpRight className="w-4 h-4 sm:w-5 sm:h-5 text-[#FAF8F5] dark:text-[#1C1917] group-hover/arrow:text-[#C48A36] group-hover/arrow:translate-x-0.5 group-hover/arrow:-translate-y-0.5 transition-all" />
                        </button>
                      )}

                      {/* Ellipse / Capsule Image Container */}
                      <div
                        onClick={onOpenGetStarted}
                        className={`group relative w-full ${pillar.heightClass} rounded-full overflow-hidden border border-[#E7E1D7] dark:border-[#2E2824] bg-[#EFEAE1] dark:bg-[#1F1B18] shadow-lg hover:shadow-2xl hover:border-[#C48A36]/70 transition-all duration-500 cursor-pointer`}
                      >
                        <img
                          src={pillar.image}
                          alt={pillar.alt}
                          style={{ objectPosition: pillar.objectPosition }}
                          className="w-full h-full object-cover transition-transform duration-700 ease-out group-hover:scale-110 will-change-transform"
                          referrerPolicy="no-referrer"
                        />

                        {/* Subtle darkening gradient at bottom for style badge contrast */}
                        <div className="absolute inset-0 bg-gradient-to-t from-[#1C1917]/75 via-transparent to-transparent opacity-40 group-hover:opacity-80 transition-opacity duration-500 pointer-events-none" />

                        {/* Floating style sublabel card on hover */}
                        <div className="absolute bottom-3.5 sm:bottom-5 inset-x-1.5 sm:inset-x-2 flex justify-center opacity-0 group-hover:opacity-100 transition-all duration-300 transform translate-y-2 group-hover:translate-y-0 pointer-events-none">
                          <span className="text-[10px] sm:text-[11px] font-semibold text-[#FAF8F5] bg-[#1C1917]/90 dark:bg-[#FAF8F5]/95 dark:text-[#1C1917] backdrop-blur-md px-2.5 py-1 rounded-full text-center leading-tight shadow-lg border border-[#FAF8F5]/20 dark:border-[#1C1917]/20 max-w-[94%] truncate">
                            {pillar.sublabel}
                          </span>
                        </div>
                      </div>

                      {/* Discreet Room & Style Label under ellipse */}
                      <div className="mt-2.5 text-center">
                        <span className="text-[11px] sm:text-xs font-semibold text-[#292524] dark:text-[#FAF8F5] block leading-tight transition-colors duration-500">
                          {pillar.room}
                        </span>
                        <span className="text-[10px] sm:text-[11px] text-[#78716C] dark:text-[#A8A29E] block mt-0.5 transition-colors duration-500">
                          {pillar.style}
                        </span>
                      </div>
                    </div>
                  );
                })}

              </div>

              {/* Bottom Subtle Trust Micro-Banner */}
              <div className="mt-6 sm:mt-7 flex items-center justify-center">
                <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#FAF8F5]/90 dark:bg-[#1A1715]/90 backdrop-blur-md border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xs transition-colors duration-500">
                  <Sparkles className="w-3.5 h-3.5 text-[#C48A36]" />
                  <span className="text-xs font-medium text-[#57534E] dark:text-[#D6D0C7] transition-colors duration-500">
                    40+ architectural aesthetics matched deterministically
                  </span>
                </div>
              </div>

            </div>
          </div>

        </div>
      </div>
    </section>
  );
};

