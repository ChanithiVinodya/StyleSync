import React from 'react';
import { Star, Image as ImageIcon, ArrowRight, ShieldAlert, ShieldCheck } from 'lucide-react';
import { DesignerListingItem } from '../types';

interface DesignerListingCardProps {
  designer: DesignerListingItem;
  onSelect: (designerId: number) => void;
}

export const DesignerListingCard: React.FC<DesignerListingCardProps> = ({ designer, onSelect }) => {
  const formattedMinPrice = designer.priceRangeMin >= 1000000 
    ? `LKR ${(designer.priceRangeMin / 1000000).toFixed(1)}M` 
    : `LKR ${(designer.priceRangeMin / 1000).toLocaleString()}k`;

  const formattedMaxPrice = designer.priceRangeMax >= 1000000
    ? `LKR ${(designer.priceRangeMax / 1000000).toFixed(1)}M`
    : `LKR ${(designer.priceRangeMax / 1000).toLocaleString()}k`;

  const fallbackImage = "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80";

  return (
    <div 
      onClick={() => onSelect(designer.id)}
      className="group relative flex flex-col rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36] dark:hover:border-[#C48A36] shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden cursor-pointer transform hover:-translate-y-1"
    >
      {/* Card Header Media */}
      <div className="relative h-52 w-full overflow-hidden bg-[#EAE4D9] dark:bg-[#2A2420]">
        <img
          src={designer.featuredImageUrl || fallbackImage}
          alt={designer.displayName}
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />

        {/* Rating Badge */}
        <div className="absolute top-3.5 left-3.5 flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#1C1917]/80 dark:bg-[#FAF8F5]/90 backdrop-blur-md text-[#FAF8F5] dark:text-[#1C1917] text-xs font-semibold shadow-md">
          <Star className="w-3.5 h-3.5 fill-[#EAB308] text-[#EAB308]" />
          <span>
            {designer.averageRating !== null && designer.averageRating !== undefined
              ? designer.averageRating.toFixed(2)
              : 'New Studio'}
          </span>
        </div>

        {/* Read-Only Capacity Badge (Sourced directly from Backend DTO) */}
        <div className="absolute top-3.5 right-3.5">
          {designer.isAtCapacity ? (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-900/90 text-amber-200 border border-amber-600/40 backdrop-blur-md text-[11px] font-bold tracking-wide shadow-md">
              <ShieldAlert className="w-3.5 h-3.5 text-amber-300" />
              At Capacity
            </span>
          ) : designer.isAvailable ? (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-emerald-950/80 text-emerald-300 border border-emerald-500/40 backdrop-blur-md text-[11px] font-semibold tracking-wide shadow-md">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
              Accepting Projects
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-stone-900/80 text-stone-300 border border-stone-600/40 backdrop-blur-md text-[11px] font-semibold tracking-wide shadow-md">
              Unavailable
            </span>
          )}
        </div>

        {/* Project Count Pill */}
        <div className="absolute bottom-3 left-3.5 flex items-center gap-1.5 text-[11px] text-white/90 font-medium drop-shadow-sm">
          <ImageIcon className="w-3.5 h-3.5" />
          <span>{designer.publishedPortfolioCount} {designer.publishedPortfolioCount === 1 ? 'project' : 'projects'} in gallery</span>
        </div>
      </div>

      {/* Card Content Body */}
      <div className="flex flex-col flex-1 p-5 space-y-4">
        {/* Title & Bio */}
        <div>
          <h3 className="text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5] group-hover:text-[#925C18] dark:group-hover:text-[#E8A849] transition-colors line-clamp-1">
            {designer.displayName}
          </h3>
          <p className="mt-1.5 text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-2 leading-relaxed">
            {designer.bio || "Crafting signature interior spaces with refined aesthetics, sustainable materials, and bespoke tailoring."}
          </p>
        </div>

        {/* Style Tags */}
        <div className="flex flex-wrap gap-1.5 pt-1">
          {designer.styleTags.slice(0, 3).map((tag, idx) => (
            <span
              key={idx}
              className="px-2 py-0.5 rounded-md text-[10px] font-medium bg-[#F0ECE1] dark:bg-[#28221D] text-[#78716C] dark:text-[#D6D3D1] border border-[#E7E1D7]/80 dark:border-[#38312B]"
            >
              {tag}
            </span>
          ))}
          {designer.styleTags.length > 3 && (
            <span className="px-1.5 py-0.5 rounded-md text-[10px] font-medium text-[#78716C] dark:text-[#A8A29E] bg-[#F8F5F0] dark:bg-[#221E1A]">
              +{designer.styleTags.length - 3}
            </span>
          )}
        </div>

        {/* Pricing Metrics Footer */}
        <div className="mt-auto pt-4 border-t border-[#E7E1D7] dark:border-[#2C2723] flex items-center justify-between">
          <div>
            <span className="text-[10px] uppercase font-semibold text-[#78716C] dark:text-[#A8A29E] tracking-wider block">
              Budget Range
            </span>
            <span className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              {formattedMinPrice} – {formattedMaxPrice}
            </span>
          </div>

          <div className="text-right">
            <span className="text-[10px] uppercase font-semibold text-[#78716C] dark:text-[#A8A29E] tracking-wider block">
              Rate / sq.ft
            </span>
            <span className="text-xs font-bold text-[#925C18] dark:text-[#E8A849]">
              LKR {designer.ratePerSqFt.toLocaleString()}
            </span>
          </div>
        </div>

        {/* Action Link */}
        <div className="pt-2 flex items-center justify-between text-xs font-semibold text-[#925C18] dark:text-[#E8A849] group-hover:translate-x-0.5 transition-transform">
          <span>View Profile & Gallery</span>
          <ArrowRight className="w-4 h-4 transform group-hover:translate-x-1 transition-transform" />
        </div>
      </div>
    </div>
  );
};
