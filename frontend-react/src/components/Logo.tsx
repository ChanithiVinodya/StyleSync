import React from 'react';
import { useTheme } from '../context/ThemeContext';

interface LogoProps {
  variant?: 'dark' | 'light' | 'auto'; // 'dark' = dark mark for light bg, 'light' = light mark for dark bg, 'auto' = reacts to theme
  size?: 'sm' | 'md' | 'lg';
  showSubtitle?: boolean;
  className?: string;
}

export const Logo: React.FC<LogoProps> = ({
  variant = 'auto',
  size = 'md',
  showSubtitle = true,
  className = '',
}) => {
  const { theme } = useTheme();
  
  // Resolve active display mode
  const effectiveMode = variant === 'auto' ? (theme === 'dark' ? 'light' : 'dark') : variant;
  const isDark = effectiveMode === 'dark'; // on light background

  // Size dimensions
  const iconDimensions = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12',
  }[size];

  const titleSize = {
    sm: 'text-xl',
    md: 'text-[22px] sm:text-2xl',
    lg: 'text-2xl sm:text-3xl',
  }[size];

  const subtitleSize = {
    sm: 'text-[8.5px] tracking-[0.18em]',
    md: 'text-[9.5px] sm:text-[10px] tracking-[0.2em]',
    lg: 'text-[11px] tracking-[0.22em]',
  }[size];

  return (
    <div className={`flex items-center gap-3 group ${className}`}>
      {/* Architectural Logo Mark */}
      <div
        className={`${iconDimensions} rounded-xl relative flex items-center justify-center transition-all duration-300 transform group-hover:scale-105 group-hover:shadow-lg bg-gradient-to-br from-[#1C1917] via-[#24201D] to-[#141210] border border-[#3E3834] shadow-md shadow-black/30`}
      >
        {/* Ambient Warm Golden Sheen */}
        <div
          className="absolute inset-0 rounded-xl pointer-events-none opacity-40 transition-opacity group-hover:opacity-75 bg-gradient-to-tr from-transparent via-transparent to-[#C48A36]/35"
        />

        {/* Custom SVG Architectural Sync Monogram */}
        <svg
          viewBox="0 0 36 36"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-[68%] h-[68%] relative z-10 transition-transform duration-500 group-hover:rotate-6"
          aria-hidden="true"
        >
          <defs>
            {/* Primary Arc Gradient */}
            <linearGradient id={`ss-primary-${variant}`} x1="8" y1="8" x2="28" y2="28" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stopColor="#FFFFFF" />
              <stop offset="60%" stopColor="#FAF8F5" />
              <stop offset="100%" stopColor="#D9D2C7" />
            </linearGradient>

            {/* Gold Accent Gradient */}
            <linearGradient id={`ss-gold-${variant}`} x1="10" y1="10" x2="26" y2="26" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stopColor="#F5D28E" />
              <stop offset="45%" stopColor="#C48A36" />
              <stop offset="100%" stopColor="#9C6517" />
            </linearGradient>
          </defs>

          {/* Architectural Curved Plane 1 (Upper ribbon representing space & craft) */}
          <path
            d="M25 10.5C25 8.2 22.2 6.5 18 6.5C13.2 6.5 9.5 9.2 9.5 12.8C9.5 17 14.5 18 18 18"
            stroke={`url(#ss-primary-${variant})`}
            strokeWidth="2.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Architectural Curved Plane 2 (Lower ribbon representing structure & delivery) */}
          <path
            d="M11 25.5C11 27.8 13.8 29.5 18 29.5C22.8 29.5 26.5 26.8 26.5 23.2C26.5 19 21.5 18 18 18"
            stroke={`url(#ss-primary-${variant})`}
            strokeWidth="2.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Golden Synchronizing Wave Accent (Flows through the center connecting the two planes) */}
          <path
            d="M14 14.5C15.2 13.2 16.5 12.8 18 12.8C20.5 12.8 22.5 14.2 22.5 16C22.5 17.5 21 18 18 18C15 18 13.5 18.5 13.5 20C13.5 21.8 15.5 23.2 18 23.2C19.5 23.2 20.8 22.8 22 21.5"
            stroke={`url(#ss-gold-${variant})`}
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            opacity="0.9"
          />

          {/* Center Precision Synchronization Dot */}
          <circle
            cx="18"
            cy="18"
            r="1.8"
            fill={`url(#ss-gold-${variant})`}
          />

          {/* Architectural Drafting Corner Mark */}
          <circle
            cx="27.5"
            cy="8.5"
            r="1"
            fill={`url(#ss-gold-${variant})`}
            opacity="0.75"
          />
        </svg>
      </div>

      {/* Brand Typography & Improved Airy Descriptor Gap */}
      <div className="flex flex-col justify-center gap-1 sm:gap-1.25">
        <span
          className={`font-serif ${titleSize} font-semibold tracking-[-0.015em] leading-none transition-colors ${
            isDark ? 'text-[#1C1917] group-hover:text-[#000000]' : 'text-[#FAF8F5] group-hover:text-[#FFFFFF]'
          }`}
        >
          StyleSync
        </span>
        {showSubtitle && (
          <span
            className={`font-sans ${subtitleSize} font-medium uppercase leading-none pl-0.5 transition-colors ${
              isDark ? 'text-[#857B72] group-hover:text-[#57534E]' : 'text-[#A8A29E] group-hover:text-[#D6D3D1]'
            }`}
          >
            Design Marketplace
          </span>
        )}
      </div>
    </div>
  );
};
