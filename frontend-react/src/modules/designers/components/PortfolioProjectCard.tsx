import React from 'react';
import { Sparkles, User, Tag } from 'lucide-react';
import { PortfolioItem, ListingStatus } from '../types';

interface PortfolioProjectCardProps {
  item: PortfolioItem;
  onClick: (item: PortfolioItem) => void;
}

export const PortfolioProjectCard: React.FC<PortfolioProjectCardProps> = ({ item, onClick }) => {
  const getStatusBadge = (status: ListingStatus) => {
    switch (status) {
      case ListingStatus.Published:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-950/80 text-emerald-300 border border-emerald-500/40 backdrop-blur-md shadow-xs">
            Published Project
          </span>
        );
      case ListingStatus.Draft:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-amber-950/80 text-amber-300 border border-amber-500/40 backdrop-blur-md shadow-xs">
            In Progress / Draft
          </span>
        );
      case ListingStatus.Archived:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-stone-900/80 text-stone-300 border border-stone-600/40 backdrop-blur-md shadow-xs">
            Archived
          </span>
        );
      case ListingStatus.Suspended:
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-stone-900/80 text-stone-300 border border-stone-600/40 backdrop-blur-md shadow-xs">
            Completed
          </span>
        );
    }
  };

  // Enforce privacy rule: client initials only (never full name)
  const formatClientInitials = (initials: string) => {
    if (!initials) return 'Anonymous';
    // Clean and ensure it only represents initials (max 4 characters e.g. "K.M." or "SD")
    const clean = initials.trim();
    if (clean.includes('.')) return clean;
    if (clean.length <= 3) return clean.toUpperCase();
    return clean.split(' ').map(n => n[0]).join('.').toUpperCase() + '.';
  };

  return (
    <div
      onClick={() => onClick(item)}
      className="group relative flex flex-col rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36] dark:hover:border-[#C48A36] overflow-hidden shadow-xs hover:shadow-xl transition-all duration-300 cursor-pointer transform hover:-translate-y-1"
    >
      {/* Visual Media with Hover Zoom */}
      <div className="relative h-64 w-full overflow-hidden bg-[#EAE4D9] dark:bg-[#2A2420]">
        <img
          src={item.imageUrl}
          alt={item.title}
          className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/20 to-transparent" />

        {/* Top Badges: Completion Status & Client Initials */}
        <div className="absolute top-3.5 left-3.5 right-3.5 flex items-center justify-between gap-2">
          {getStatusBadge(item.completionStatusBadge)}

          {/* Client Initials Pill (Strict privacy) */}
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#1C1917]/85 dark:bg-[#FAF8F5]/90 text-[#FAF8F5] dark:text-[#1C1917] text-[11px] font-bold backdrop-blur-md shadow-xs">
            <User className="w-3 h-3 text-[#C48A36]" />
            <span>Client: {formatClientInitials(item.clientInitials)}</span>
          </div>
        </div>

        {/* Bottom Overlay: Budget Range Label & Quick Click Cue */}
        <div className="absolute bottom-3 left-3.5 right-3.5 flex items-center justify-between text-xs text-white">
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-black/60 backdrop-blur-md font-semibold text-[11px] text-amber-200 border border-amber-500/30">
            <Tag className="w-3 h-3 text-amber-400" />
            <span>{item.budgetRangeLabel || 'Custom Budget'}</span>
          </div>

          <span className="opacity-0 group-hover:opacity-100 transition-opacity text-[11px] font-semibold text-white/90 flex items-center gap-1">
            <Sparkles className="w-3 h-3 text-amber-400" /> View Project
          </span>
        </div>
      </div>

      {/* Card Info Body */}
      <div className="p-5 flex-1 flex flex-col justify-between space-y-3">
        <div>
          <h3 className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5] group-hover:text-[#925C18] dark:group-hover:text-[#E8A849] transition-colors line-clamp-1">
            {item.title}
          </h3>
          <p className="mt-1.5 text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-2 leading-relaxed">
            {item.description}
          </p>
        </div>

        <div className="pt-3 border-t border-[#E7E1D7] dark:border-[#2C2723] flex items-center justify-between text-[11px] text-[#78716C] dark:text-[#A8A29E]">
          <span>Verified Proof of Work</span>
          <span className="font-medium text-[#925C18] dark:text-[#E8A849] group-hover:underline">
            Inspect Full Specs →
          </span>
        </div>
      </div>
    </div>
  );
};
