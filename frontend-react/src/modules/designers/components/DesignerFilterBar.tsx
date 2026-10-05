import React, { useState } from 'react';
import { 
  Filter, 
  SlidersHorizontal, 
  RotateCcw, 
  Check, 
  ChevronDown, 
  DollarSign, 
  Sparkles,
  ShieldCheck,
  Search
} from 'lucide-react';
import { DesignerQueryParameters } from '../types';

interface DesignerFilterBarProps {
  query: DesignerQueryParameters;
  onQueryChange: (updated: Partial<DesignerQueryParameters>) => void;
  onReset: () => void;
  totalResults: number;
}

const POPULAR_STYLES = [
  'All',
  'Tropical Modernism',
  'Minimalist',
  'Japandi',
  'Scandinavian',
  'Boho Chic',
  'Industrial',
  'Coastal',
  'Classic Luxury',
  'Contemporary',
  'Biophilic'
];

export const DesignerFilterBar: React.FC<DesignerFilterBarProps> = ({
  query,
  onQueryChange,
  onReset,
  totalResults
}) => {
  const [isBudgetOpen, setIsBudgetOpen] = useState(false);
  const [minBudgetInput, setMinBudgetInput] = useState(query.budgetMin?.toString() || '');
  const [maxBudgetInput, setMaxBudgetInput] = useState(query.budgetMax?.toString() || '');

  const activeStyle = query.style || 'All';
  const hasActiveFilters = Boolean(
    (query.style && query.style !== 'All') ||
    query.budgetMin ||
    query.budgetMax ||
    query.available !== undefined
  );

  const applyBudget = () => {
    const minVal = minBudgetInput ? parseFloat(minBudgetInput) : undefined;
    const maxVal = maxBudgetInput ? parseFloat(maxBudgetInput) : undefined;
    onQueryChange({
      budgetMin: minVal,
      budgetMax: maxVal,
      page: 1
    });
    setIsBudgetOpen(false);
  };

  const handleClearBudget = () => {
    setMinBudgetInput('');
    setMaxBudgetInput('');
    onQueryChange({ budgetMin: undefined, budgetMax: undefined, page: 1 });
    setIsBudgetOpen(false);
  };

  return (
    <div className="space-y-4">
      {/* Top Filter Controls: Budget, Availability, Sort, & Reset */}
      <div className="flex flex-wrap items-center justify-between gap-3 p-4 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xs">
        <div className="flex flex-wrap items-center gap-2.5">
          {/* Filter Label Icon */}
          <div className="flex items-center gap-1.5 text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] mr-1">
            <SlidersHorizontal className="w-4 h-4 text-[#925C18] dark:text-[#E8A849]" />
            <span>Filters:</span>
          </div>

          {/* Budget Range Dropdown */}
          <div className="relative">
            <button
              type="button"
              onClick={() => setIsBudgetOpen(!isBudgetOpen)}
              className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-medium border transition-colors cursor-pointer ${
                query.budgetMin || query.budgetMax
                  ? 'bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border-[#C48A36] font-semibold'
                  : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36]'
              }`}
            >
              <DollarSign className="w-3.5 h-3.5" />
              <span>
                {query.budgetMin || query.budgetMax
                  ? `LKR ${query.budgetMin ? (query.budgetMin / 1000) + 'k' : '0'} - ${query.budgetMax ? (query.budgetMax / 1000) + 'k' : 'Any'}`
                  : 'Budget Range'}
              </span>
              <ChevronDown className="w-3.5 h-3.5 opacity-60" />
            </button>

            {/* Budget Popup Modal */}
            {isBudgetOpen && (
              <div className="absolute top-full left-0 mt-2 w-72 p-4 rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] shadow-xl z-30 space-y-3 animate-scaleUp">
                <span className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] block">
                  Project Budget Range (LKR)
                </span>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[10px] text-[#78716C] dark:text-[#A8A29E] block mb-1">Min (LKR)</label>
                    <input
                      type="number"
                      step="50000"
                      value={minBudgetInput}
                      onChange={e => setMinBudgetInput(e.target.value)}
                      placeholder="e.g. 100000"
                      className="w-full px-2.5 py-1.5 text-xs rounded-lg bg-[#F8F5F0] dark:bg-[#24201C] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
                    />
                  </div>
                  <div>
                    <label className="text-[10px] text-[#78716C] dark:text-[#A8A29E] block mb-1">Max (LKR)</label>
                    <input
                      type="number"
                      step="50000"
                      value={maxBudgetInput}
                      onChange={e => setMaxBudgetInput(e.target.value)}
                      placeholder="e.g. 500000"
                      className="w-full px-2.5 py-1.5 text-xs rounded-lg bg-[#F8F5F0] dark:bg-[#24201C] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
                    />
                  </div>
                </div>
                <div className="flex items-center justify-between pt-2 border-t border-[#E7E1D7] dark:border-[#2C2723]">
                  <button
                    type="button"
                    onClick={handleClearBudget}
                    className="text-[11px] text-[#78716C] hover:text-[#DC2626] transition-colors"
                  >
                    Clear
                  </button>
                  <button
                    type="button"
                    onClick={applyBudget}
                    className="px-3.5 py-1.5 text-xs font-semibold rounded-lg text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] transition-colors"
                  >
                    Apply Filter
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Availability Toggle Pill */}
          <button
            type="button"
            onClick={() => {
              const nextVal = query.available === true ? undefined : true;
              onQueryChange({ available: nextVal, page: 1 });
            }}
            className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-medium border transition-colors cursor-pointer ${
              query.available === true
                ? 'bg-[#DCFCE7] dark:bg-[#143823] text-[#166534] dark:text-[#86EFAC] border-[#BBF7D0] dark:border-[#1E5638] font-semibold'
                : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#16A34A]'
            }`}
          >
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Open Capacity Only</span>
            {query.available === true && <Check className="w-3 h-3 stroke-[3]" />}
          </button>

          {/* Reset All Filters Button */}
          {hasActiveFilters && (
            <button
              type="button"
              onClick={onReset}
              className="inline-flex items-center gap-1 px-3 py-2 text-xs font-medium text-[#DC2626] hover:text-[#B91C1C] transition-colors cursor-pointer"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Reset</span>
            </button>
          )}
        </div>

        {/* Right Controls: Sort Dropdown & Result Counter */}
        <div className="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end">
          <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">
            <strong>{totalResults}</strong> {totalResults === 1 ? 'studio' : 'studios'} found
          </span>

          <div className="flex items-center gap-2">
            <span className="text-xs text-[#78716C] dark:text-[#A8A29E] hidden md:inline">Sort:</span>
            <select
              value={query.sort || 'newest'}
              onChange={e => onQueryChange({ sort: e.target.value, page: 1 })}
              className="px-3 py-2 rounded-xl text-xs font-semibold bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] cursor-pointer focus:outline-hidden focus:ring-1 focus:ring-[#C48A36]"
            >
              <option value="newest">Newest Studios</option>
              <option value="rating">Highest Rating</option>
              <option value="price_asc">Price: Low to High</option>
              <option value="price_desc">Price: High to Low</option>
            </select>
          </div>
        </div>
      </div>

      {/* Style Chips Horizontal Scroller */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
        {POPULAR_STYLES.map(style => {
          const isSelected = activeStyle.toLowerCase() === style.toLowerCase();
          return (
            <button
              key={style}
              type="button"
              onClick={() => onQueryChange({ style: style === 'All' ? undefined : style, page: 1 })}
              className={`px-3.5 py-1.5 text-xs rounded-full whitespace-nowrap transition-all cursor-pointer ${
                isSelected
                  ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917] font-semibold shadow-xs'
                  : 'bg-[#F8F5F0] dark:bg-[#1A1715] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36]'
              }`}
            >
              {style}
            </button>
          );
        })}
      </div>
    </div>
  );
};
