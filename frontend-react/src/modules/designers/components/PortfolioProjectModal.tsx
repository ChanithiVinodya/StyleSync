import React, { useEffect } from 'react';
import { X, User, Tag, Layers, CheckCircle2, ShieldAlert, Sparkles, ExternalLink } from 'lucide-react';
import { PortfolioItem, ListingStatus } from '../types';

interface PortfolioProjectModalProps {
  item: PortfolioItem;
  designerDisplayName?: string;
  onClose: () => void;
}

export const PortfolioProjectModal: React.FC<PortfolioProjectModalProps> = ({
  item,
  designerDisplayName,
  onClose
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  const getStatusBadge = (status: ListingStatus) => {
    switch (status) {
      case ListingStatus.Published:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 dark:bg-emerald-950/70 text-emerald-800 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-800">
            <CheckCircle2 className="w-3.5 h-3.5" /> Published Project
          </span>
        );
      case ListingStatus.Draft:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 dark:bg-amber-950/70 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-800">
            <ShieldAlert className="w-3.5 h-3.5" /> In Progress (Draft)
          </span>
        );
      case ListingStatus.Archived:
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-stone-100 dark:bg-stone-800 text-stone-800 dark:text-stone-300 border border-stone-300 dark:border-stone-700">
            Archived Project
          </span>
        );
    }
  };

  const formatClientInitials = (initials: string) => {
    if (!initials) return 'Anonymous';
    const clean = initials.trim();
    if (clean.includes('.')) return clean;
    if (clean.length <= 3) return clean.toUpperCase();
    return clean.split(' ').map(n => n[0]).join('.').toUpperCase() + '.';
  };

  return (
    <div 
      className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/80 backdrop-blur-sm animate-fadeIn"
      onClick={onClose}
    >
      <div 
        className="relative max-w-4xl w-full rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] overflow-hidden shadow-2xl flex flex-col max-h-[92vh] animate-scaleUp"
        onClick={e => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between p-5 px-6 border-b border-[#E7E1D7] dark:border-[#2C2723] bg-[#F8F5F0] dark:bg-[#1E1A17]">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-[11px] font-bold tracking-wider uppercase text-[#925C18] dark:text-[#E8A849]">
                Portfolio Showcase & Proof of Work
              </span>
            </div>
            <h2 className="text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5] mt-0.5">
              {item.title}
            </h2>
            {designerDisplayName && (
              <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                Designed & Delivered by <strong className="text-[#1C1917] dark:text-[#FAF8F5]">{designerDisplayName}</strong>
              </span>
            )}
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-full hover:bg-[#EAE4D9] dark:hover:bg-[#2C2723] text-[#78716C] dark:text-[#A8A29E] transition-colors cursor-pointer"
            aria-label="Close project view"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Content Scroll Area */}
        <div className="overflow-y-auto p-6 space-y-6">
          {/* Main High-Res Image Container */}
          <div className="relative rounded-2xl overflow-hidden bg-black/95 max-h-[55vh] flex items-center justify-center border border-black/10 dark:border-white/10 shadow-inner">
            <img
              src={item.imageUrl}
              alt={item.title}
              className="max-h-[55vh] w-auto object-contain transition-all"
            />
          </div>

          {/* Project Metadata Pills */}
          <div className="flex flex-wrap items-center justify-between gap-4 p-4 rounded-2xl bg-[#F8F5F0] dark:bg-[#221D19] border border-[#E7E1D7] dark:border-[#2C2723]">
            <div className="flex flex-wrap items-center gap-3">
              {getStatusBadge(item.completionStatusBadge)}

              <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF8F5] dark:bg-[#1A1715] text-[#1C1917] dark:text-[#FAF8F5] border border-[#E7E1D7] dark:border-[#2C2723]">
                <User className="w-3.5 h-3.5 text-[#C48A36]" />
                <span>Client: {formatClientInitials(item.clientInitials)}</span>
              </div>

              {item.budgetRangeLabel && (
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30">
                  <Tag className="w-3.5 h-3.5" />
                  <span>Budget Tier: {item.budgetRangeLabel}</span>
                </div>
              )}
            </div>

            <div className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
              Project ID: #{item.id}
            </div>
          </div>

          {/* Project Full Description */}
          <div className="space-y-2">
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Project Overview & Architectural Details
            </h4>
            <p className="text-sm sm:text-base text-[#57534E] dark:text-[#D6D3D1] leading-relaxed whitespace-pre-line">
              {item.description}
            </p>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="p-4 px-6 border-t border-[#E7E1D7] dark:border-[#2C2723] bg-[#F8F5F0] dark:bg-[#1E1A17] flex items-center justify-end">
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2 text-xs font-semibold rounded-xl bg-[#1C1917] dark:bg-[#FAF8F5] text-[#FAF8F5] dark:text-[#1C1917] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] transition-colors cursor-pointer"
          >
            Close Project
          </button>
        </div>
      </div>
    </div>
  );
};
