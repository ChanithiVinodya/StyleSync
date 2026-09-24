import React from 'react';
import { Sun, Moon } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';

interface GlassThemeToggleProps {
  className?: string;
  size?: 'sm' | 'md';
}

export const GlassThemeToggle: React.FC<GlassThemeToggleProps> = ({
  className = '',
  size = 'md',
}) => {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark';

  const sizeClasses = size === 'sm' ? 'w-8 h-8' : 'w-10 h-10';
  const iconSize = size === 'sm' ? 'w-4 h-4' : 'w-[18px] h-[18px]';

  return (
    <button
      type="button"
      onClick={toggleTheme}
      className={`relative ${sizeClasses} rounded-full flex items-center justify-center transition-all duration-400 ease-out group cursor-pointer select-none focus:outline-hidden focus-visible:ring-2 focus-visible:ring-[#C48A36] ${
        isDark
          ? 'bg-[#1C1917]/60 hover:bg-[#1C1917]/80 text-[#FAF8F5] border border-white/20 shadow-[inset_0_1px_1px_rgba(255,255,255,0.2),0_4px_12px_rgba(0,0,0,0.35)] hover:shadow-[0_0_16px_rgba(196,138,54,0.35)]'
          : 'bg-white/60 hover:bg-white/80 text-[#1C1917] border border-black/10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),0_2px_8px_rgba(0,0,0,0.06)] hover:shadow-[0_0_14px_rgba(196,138,54,0.2)]'
      } backdrop-blur-md active:scale-95 ${className}`}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {/* Specular glass reflection pill */}
      <span
        className="absolute top-1 inset-x-2 h-[1px] bg-gradient-to-r from-transparent via-white/50 to-transparent dark:via-transparent pointer-events-none rounded-full"
        aria-hidden="true"
      />

      {/* Sun Icon (Rotates out smoothly in dark mode) */}
      <div
        className={`absolute inset-0 flex items-center justify-center transition-all duration-500 transform ${
          isDark
            ? 'opacity-0 rotate-90 scale-50 pointer-events-none'
            : 'opacity-100 rotate-0 scale-100'
        }`}
      >
        <Sun className={`${iconSize} text-[#C48A36] group-hover:rotate-45 transition-transform duration-500`} />
      </div>

      {/* Moon Icon (Rotates in smoothly in dark mode) */}
      <div
        className={`absolute inset-0 flex items-center justify-center transition-all duration-500 transform ${
          isDark
            ? 'opacity-100 rotate-0 scale-100'
            : 'opacity-0 -rotate-90 scale-50 pointer-events-none'
        }`}
      >
        <Moon className={`${iconSize} text-[#E8D4B0] group-hover:-rotate-12 transition-transform duration-500 fill-[#E8D4B0]/20`} />
      </div>
    </button>
  );
};
