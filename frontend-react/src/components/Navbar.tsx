import React, { useState, useEffect } from 'react';
import { Menu, X, ArrowRight } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { PersonaRole } from '../types';
import { Logo } from './Logo';
import { GlassThemeToggle } from './GlassThemeToggle';
import { useNavigate } from 'react-router-dom';

interface NavbarProps {
  onOpenPortalModal: (role?: PersonaRole) => void;
  onOpenGetStarted: () => void;
}

interface NavItem {
  name: string;
  href: string;
}

const NAV_ITEMS: NavItem[] = [
  { name: 'Project Requests', href: '/project-requests' },
  { name: 'How it Works', href: '#how-it-works' },
  { name: "Who It's For", href: '#who-its-for' },
  { name: 'Featured Projects', href: '#transformations' },
  { name: 'Trust & Security', href: '#trust' },
  { name: 'Reviews', href: '#reviews' },
];

export const Navbar: React.FC<NavbarProps> = ({
  onOpenPortalModal,
  onOpenGetStarted,
}) => {
  const navigate = useNavigate();
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [hoveredNav, setHoveredNav] = useState<string | null>(null);
  const [activeSection, setActiveSection] = useState<string | null>(null);

  const isManualClickRef = React.useRef(false);
  const manualClickTimeoutRef = React.useRef<number | null>(null);

  // Scroll detection for active section and header blur
  useEffect(() => {
    const handleScroll = () => {
      const scrollY = window.scrollY;
      setIsScrolled(scrollY > 20);

      // If user recently clicked a nav link, respect manual target until scroll settles
      if (isManualClickRef.current) return;

      // Bottom of page check - activate last section
      const windowHeight = window.innerHeight;
      const docHeight = document.documentElement.scrollHeight;
      if (windowHeight + scrollY >= docHeight - 80) {
        setActiveSection(NAV_ITEMS[NAV_ITEMS.length - 1].href);
        return;
      }

      // If at very top (Hero), no section is active
      if (scrollY < 200) {
        setActiveSection(null);
        return;
      }

      const sections = NAV_ITEMS.map((item) => ({
        href: item.href,
        el: document.getElementById(item.href.replace('#', '')),
      }));

      // Find the currently visible section based on top offset
      let currentSection: string | null = null;
      for (let i = sections.length - 1; i >= 0; i--) {
        const { href, el } = sections[i];
        if (el) {
          const rect = el.getBoundingClientRect();
          // Trigger when section top enters near navbar bottom
          if (rect.top <= 200) {
            currentSection = href;
            break;
          }
        }
      }

      if (currentSection) {
        setActiveSection(currentSection);
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // Initial check on mount

    return () => {
      window.removeEventListener('scroll', handleScroll);
      if (manualClickTimeoutRef.current) {
        clearTimeout(manualClickTimeoutRef.current);
      }
    };
  }, []);

  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
    e.preventDefault();
    if (!href.startsWith('#')) {
      navigate(href);
      return;
    }
    setActiveSection(href);
    setHoveredNav(null);

    isManualClickRef.current = true;
    if (manualClickTimeoutRef.current) {
      clearTimeout(manualClickTimeoutRef.current);
    }
    manualClickTimeoutRef.current = window.setTimeout(() => {
      isManualClickRef.current = false;
    }, 850);

    const targetId = href.replace('#', '');
    const element = document.getElementById(targetId);
    if (element) {
      const navOffset = isScrolled ? 70 : 86;
      const elementTop = element.getBoundingClientRect().top + window.pageYOffset;
      window.scrollTo({
        top: elementTop - navOffset,
        behavior: 'smooth',
      });
    }
  };

  return (
    <header
      id="main-navigation"
      className={`sticky top-0 z-40 transition-all duration-300 ${
        isScrolled
          ? 'bg-[#FAF8F5]/90 dark:bg-[#12100E]/90 backdrop-blur-xl shadow-xs border-b border-[#E7E1D7]/80 dark:border-[#2A2522]/80'
          : 'bg-[#FAF8F5]/70 dark:bg-[#12100E]/70 backdrop-blur-md border-b border-transparent'
      }`}
    >
      {/* Decorative top accent sheen when scrolled */}
      <div
        className={`absolute top-0 inset-x-0 h-[1px] bg-gradient-to-r from-transparent via-[#C48A36]/40 dark:via-[#E8A849]/30 to-transparent transition-opacity duration-500 pointer-events-none ${
          isScrolled ? 'opacity-100' : 'opacity-0'
        }`}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div
          className={`flex items-center justify-between transition-all duration-300 ${
            isScrolled ? 'h-16' : 'h-20'
          }`}
        >
          {/* Logo & Brand Identity with gentle hover micro-interaction */}
          <motion.a
            id="nav-logo-link"
            href="#"
            whileHover={{ scale: 1.015 }}
            whileTap={{ scale: 0.985 }}
            transition={{ type: 'spring', stiffness: 400, damping: 25 }}
            className="flex items-center group focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] dark:focus-visible:ring-[#FAF8F5] rounded-xl py-1 px-1 -ml-1"
            aria-label="StyleSync Design Marketplace Home"
          >
            <Logo variant="auto" size="md" showSubtitle={true} />
          </motion.a>

          {/* Desktop Navigation Links with animated sliding pill highlight and active section indicator */}
          <nav
            id="desktop-nav-links"
            className="hidden md:flex items-center p-1 rounded-full bg-[#FAF8F5]/60 dark:bg-[#1A1715]/60 border border-[#E7E1D7]/70 dark:border-[#2E2824]/70 backdrop-blur-md shadow-2xs"
            onMouseLeave={() => setHoveredNav(null)}
          >
            {NAV_ITEMS.map((item) => {
              const isActive = activeSection === item.href;
              const isHovered = hoveredNav === item.name;
              const showPill = isHovered || (!hoveredNav && isActive);

              return (
                <a
                  key={item.name}
                  id={`nav-link-${item.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}`}
                  href={item.href}
                  onClick={(e) => handleNavClick(e, item.href)}
                  onMouseEnter={() => setHoveredNav(item.name)}
                  className={`relative px-3.5 py-1.5 text-xs lg:text-sm transition-colors duration-200 rounded-full flex items-center gap-1.5 focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#C48A36] ${
                    isActive
                      ? 'text-[#925C18] dark:text-[#E8A849] font-semibold'
                      : isHovered
                      ? 'text-[#1C1917] dark:text-[#FAF8F5] font-medium'
                      : 'text-[#57534E] dark:text-[#A8A29E] font-medium hover:text-[#1C1917] dark:hover:text-[#FAF8F5]'
                  }`}
                >
                  {/* Sliding animated capsule highlight for hover or active */}
                  {showPill && (
                    <motion.span
                      layoutId="nav-pill"
                      className={`absolute inset-0 rounded-full border -z-10 shadow-2xs transition-colors duration-150 ${
                        isActive && !isHovered
                          ? 'bg-[#FAF3E8] dark:bg-[#2A231A] border-[#E8DEC8] dark:border-[#423525]'
                          : 'bg-[#EFEAE1] dark:bg-[#221D19] border-[#E2DAD0] dark:border-[#352E27]'
                      }`}
                      transition={{ type: 'spring', stiffness: 450, damping: 32 }}
                    />
                  )}

                  {/* Active gold micro-dot indicator */}
                  {isActive && (
                    <motion.span
                      layoutId="nav-active-dot"
                      className="w-1.5 h-1.5 rounded-full bg-[#C48A36] dark:bg-[#E8A849] shrink-0"
                      transition={{ type: 'spring', stiffness: 450, damping: 30 }}
                    />
                  )}

                  <span>{item.name}</span>
                </a>
              );
            })}
          </nav>

          {/* Desktop Actions */}
          <div className="hidden md:flex items-center space-x-2.5">
            {/* Secondary CTA: Portals Log In */}
            <motion.button
              id="nav-login-btn"
              onClick={() => onOpenPortalModal('designer')}
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              transition={{ type: 'spring', stiffness: 400, damping: 25 }}
              className="px-4 py-2 text-sm font-medium text-[#1C1917] dark:text-[#E7E1D7] hover:text-[#000000] dark:hover:text-[#FFFFFF] hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] rounded-full transition-colors focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] dark:focus-visible:ring-[#FAF8F5]"
            >
              Log In
            </motion.button>

            {/* PRIMARY CTA: Get Started with spring hover and arrow glide */}
            <motion.button
              id="nav-get-started-btn"
              onClick={onOpenGetStarted}
              whileHover={{ scale: 1.03, y: -0.5 }}
              whileTap={{ scale: 0.97 }}
              transition={{ type: 'spring', stiffness: 400, damping: 25 }}
              className="relative inline-flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#E7E0D3] rounded-full shadow-xs hover:shadow-md transition-shadow group focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#1C1917] dark:focus-visible:ring-[#FAF8F5] overflow-hidden"
            >
              {/* Subtle light sweep reflection */}
              <span className="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-700 bg-gradient-to-r from-transparent via-white/10 dark:via-black/5 to-transparent pointer-events-none" />
              <span>Get Started</span>
              <ArrowRight className="w-4 h-4 text-[#E7E1D7] dark:text-[#322C27] group-hover:translate-x-1 transition-transform" />
            </motion.button>

            {/* Light/Dark Glass Toggle Button */}
            <GlassThemeToggle />
          </div>

          {/* Mobile controls */}
          <div className="flex md:hidden items-center gap-2">
            <motion.button
              id="mobile-nav-get-started"
              onClick={onOpenGetStarted}
              whileTap={{ scale: 0.95 }}
              className="px-3.5 py-1.5 text-xs font-semibold text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] rounded-full shadow-2xs"
            >
              Get Started
            </motion.button>

            {/* Mobile Glass Theme Toggle */}
            <GlassThemeToggle size="sm" />

            {/* Animated Mobile Toggle Button */}
            <motion.button
              id="mobile-menu-toggle-btn"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              whileTap={{ scale: 0.9 }}
              className="w-9 h-9 rounded-full flex items-center justify-center text-[#44403C] dark:text-[#D6D3D1] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] hover:bg-[#EFEAE1]/60 dark:hover:bg-[#25201C]/60 transition-colors focus:outline-hidden"
              aria-label="Toggle Menu"
            >
              <AnimatePresence mode="wait" initial={false}>
                {mobileMenuOpen ? (
                  <motion.div
                    key="close"
                    initial={{ rotate: -90, opacity: 0 }}
                    animate={{ rotate: 0, opacity: 1 }}
                    exit={{ rotate: 90, opacity: 0 }}
                    transition={{ duration: 0.18 }}
                  >
                    <X className="w-5 h-5" />
                  </motion.div>
                ) : (
                  <motion.div
                    key="menu"
                    initial={{ rotate: 90, opacity: 0 }}
                    animate={{ rotate: 0, opacity: 1 }}
                    exit={{ rotate: -90, opacity: 0 }}
                    transition={{ duration: 0.18 }}
                  >
                    <Menu className="w-5 h-5" />
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.button>
          </div>
        </div>
      </div>

      {/* Animated Mobile Menu Dropdown with slide and staggered items */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            id="mobile-dropdown-menu"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
            className="md:hidden overflow-hidden bg-[#FAF8F5]/98 dark:bg-[#141210]/98 backdrop-blur-2xl border-b border-[#E7E1D7] dark:border-[#2A2522] shadow-lg"
          >
            <div className="px-5 pt-3 pb-6 space-y-4">
              <div className="flex flex-col space-y-1">
                {NAV_ITEMS.map((item, idx) => {
                  const isActive = activeSection === item.href;
                  return (
                    <motion.a
                      key={item.name}
                      id={`mobile-nav-link-${item.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}`}
                      href={item.href}
                      onClick={(e) => {
                        handleNavClick(e, item.href);
                        setMobileMenuOpen(false);
                      }}
                      initial={{ opacity: 0, x: -12 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.04 * idx, duration: 0.2 }}
                      className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                        isActive
                          ? 'bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] font-semibold border border-[#EADBCA] dark:border-[#423525]'
                          : 'text-[#44403C] dark:text-[#D6D3D1] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] hover:bg-[#EFEAE1] dark:hover:bg-[#201C19] border border-transparent'
                      }`}
                    >
                      <span className="flex items-center gap-2">
                        {isActive && (
                          <span className="w-1.5 h-1.5 rounded-full bg-[#C48A36] dark:bg-[#E8A849]" />
                        )}
                        <span>{item.name}</span>
                      </span>
                      {isActive && (
                        <span className="text-[11px] font-semibold text-[#C48A36] dark:text-[#E8A849] uppercase tracking-wider">
                          Active
                        </span>
                      )}
                    </motion.a>
                  );
                })}
              </div>

              <div className="pt-3 border-t border-[#E7E1D7] dark:border-[#2A2522] flex flex-col space-y-2.5">
                <motion.button
                  id="mobile-team-login-btn"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onOpenPortalModal('designer');
                  }}
                  whileTap={{ scale: 0.98 }}
                  className="w-full py-2.5 text-sm font-medium text-[#57534E] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] border border-[#E7E1D7] dark:border-[#2E2824] bg-white dark:bg-[#1C1815] rounded-full transition-colors"
                >
                  Designer & Team Log In
                </motion.button>

                <motion.button
                  id="mobile-primary-get-started-btn"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onOpenGetStarted();
                  }}
                  whileTap={{ scale: 0.98 }}
                  className="w-full py-3 text-sm font-medium text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] rounded-full flex items-center justify-center gap-2 shadow-xs"
                >
                  <span>Get Started</span>
                  <ArrowRight className="w-4 h-4 text-[#C48A36]" />
                </motion.button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
};

