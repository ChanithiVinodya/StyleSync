import React, { useState, useEffect, useCallback } from 'react';
import { 
  Search, 
  Sparkles, 
  Layers, 
  ChevronLeft, 
  ChevronRight, 
  SlidersHorizontal,
  Compass,
  Briefcase
} from 'lucide-react';
import { DesignerListingItem, DesignerQueryParameters, PagedResult } from '../types';
import { designerApi } from '../services/designerApi';
import { DesignerFilterBar } from '../components/DesignerFilterBar';
import { DesignerListingCard } from '../components/DesignerListingCard';

interface DesignerDirectoryPageProps {
  onSelectDesigner: (designerId: number) => void;
  onOpenStudio?: () => void;
  onOpenAdmin?: () => void;
}

const DEFAULT_QUERY: DesignerQueryParameters = {
  style: undefined,
  budgetMin: undefined,
  budgetMax: undefined,
  available: undefined,
  sort: 'newest',
  page: 1,
  pageSize: 6
};

export const DesignerDirectoryPage: React.FC<DesignerDirectoryPageProps> = ({
  onSelectDesigner,
  onOpenStudio,
  onOpenAdmin
}) => {
  const [query, setQuery] = useState<DesignerQueryParameters>(DEFAULT_QUERY);
  const [result, setResult] = useState<PagedResult<DesignerListingItem> | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const fetchListings = useCallback(async (currentQuery: DesignerQueryParameters) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await designerApi.getListings(currentQuery);
      setResult(data);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unable to load published designer listings.';
      setErrorMessage(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchListings(query);
  }, [query, fetchListings]);

  const handleQueryChange = (updated: Partial<DesignerQueryParameters>) => {
    setQuery(prev => ({
      ...prev,
      ...updated
    }));
  };

  const handleResetFilters = () => {
    setQuery(DEFAULT_QUERY);
  };

  const handlePageChange = (newPage: number) => {
    if (!result) return;
    if (newPage >= 1 && newPage <= result.totalPages) {
      setQuery(prev => ({ ...prev, page: newPage }));
      window.scrollTo({ top: 320, behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] pb-24 transition-colors">
      {/* Hero Header Banner */}
      <div className="relative overflow-hidden bg-gradient-to-b from-[#F3EEE5] dark:from-[#1A1715] to-[#FDFBF7] dark:to-[#12100E] border-b border-[#E7E1D7] dark:border-[#2C2723] pt-14 pb-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-end md:justify-between gap-6">
          <div className="space-y-3 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30">
              <Compass className="w-3.5 h-3.5" />
              <span>Public Directory & Portfolio Showcase</span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#1C1917] dark:text-[#FAF8F5]">
              Discover Certified Interior Designers
            </h1>
            <p className="text-sm sm:text-base text-[#57534E] dark:text-[#A8A29E] leading-relaxed">
              Explore curated portfolios from vetted architecture and interior studios. Filter by design aesthetics, project budget, and real-time studio availability.
            </p>
          </div>

          {/* Quick Action Navigation */}
          <div className="flex flex-wrap items-center gap-2.5 self-start md:self-auto">
            {onOpenStudio && (
              <button
                type="button"
                onClick={onOpenStudio}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36] shadow-xs transition-colors cursor-pointer"
              >
                <Briefcase className="w-4 h-4 text-[#925C18] dark:text-[#E8A849]" />
                <span>Designer Studio</span>
              </button>
            )}

            {onOpenAdmin && (
              <button
                type="button"
                onClick={onOpenAdmin}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-[#925C18] dark:text-[#E8A849] bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#C48A36]/30 hover:border-[#C48A36] shadow-xs transition-colors cursor-pointer"
              >
                <SlidersHorizontal className="w-4 h-4" />
                <span>Admin Governance</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-8">
        {/* Filter & Sorting Controls */}
        <DesignerFilterBar
          query={query}
          onQueryChange={handleQueryChange}
          onReset={handleResetFilters}
          totalResults={result?.totalCount ?? 0}
        />

        {/* Error Notification */}
        {errorMessage && (
          <div className="p-4 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900/50 text-red-700 dark:text-red-300 text-sm flex items-center justify-between">
            <span>{errorMessage}</span>
            <button 
              onClick={() => fetchListings(query)}
              className="underline font-semibold hover:text-red-800"
            >
              Retry
            </button>
          </div>
        )}

        {/* Loading Skeletons */}
        {isLoading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3, 4, 5, 6].map(skeletonId => (
              <div 
                key={skeletonId}
                className="flex flex-col rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] overflow-hidden animate-pulse"
              >
                <div className="h-52 bg-[#EAE4D9] dark:bg-[#2A2420]" />
                <div className="p-5 space-y-4 flex-1 flex flex-col">
                  <div className="h-5 bg-[#EAE4D9] dark:bg-[#2A2420] rounded w-3/4" />
                  <div className="space-y-1.5">
                    <div className="h-3 bg-[#EAE4D9] dark:bg-[#2A2420] rounded w-full" />
                    <div className="h-3 bg-[#EAE4D9] dark:bg-[#2A2420] rounded w-5/6" />
                  </div>
                  <div className="flex gap-2 pt-2">
                    <div className="h-5 w-16 bg-[#EAE4D9] dark:bg-[#2A2420] rounded-full" />
                    <div className="h-5 w-20 bg-[#EAE4D9] dark:bg-[#2A2420] rounded-full" />
                  </div>
                  <div className="mt-auto pt-4 border-t border-[#E7E1D7] dark:border-[#2C2723] flex justify-between">
                    <div className="h-6 w-24 bg-[#EAE4D9] dark:bg-[#2A2420] rounded" />
                    <div className="h-6 w-20 bg-[#EAE4D9] dark:bg-[#2A2420] rounded" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Empty State */}
        {!isLoading && result && result.items.length === 0 && (
          <div className="flex flex-col items-center justify-center p-12 sm:p-16 rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-dashed border-[#E7E1D7] dark:border-[#2C2723] text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] flex items-center justify-center shadow-inner">
              <Search className="w-8 h-8" />
            </div>
            <div className="max-w-md space-y-1">
              <h3 className="text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                No published designers found
              </h3>
              <p className="text-xs sm:text-sm text-[#78716C] dark:text-[#A8A29E] leading-relaxed">
                We couldn't find any designer listings matching your selected style, budget range, or availability filters.
              </p>
            </div>
            <button
              type="button"
              onClick={handleResetFilters}
              className="mt-2 px-5 py-2.5 rounded-xl text-xs font-semibold text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] shadow-sm transition-colors cursor-pointer"
            >
              Reset All Filters
            </button>
          </div>
        )}

        {/* Results Grid */}
        {!isLoading && result && result.items.length > 0 && (
          <div className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {result.items.map(designer => (
                <DesignerListingCard
                  key={designer.id}
                  designer={designer}
                  onSelect={onSelectDesigner}
                />
              ))}
            </div>

            {/* Pagination Bar */}
            {result.totalPages > 1 && (
              <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-6 border-t border-[#E7E1D7] dark:border-[#2C2723]">
                <div className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                  Showing <span className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">{(result.page - 1) * result.pageSize + 1}</span> to{' '}
                  <span className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                    {Math.min(result.page * result.pageSize, result.totalCount)}
                  </span>{' '}
                  of <span className="font-semibold text-[#1C1917] dark:text-[#FAF8F5]">{result.totalCount}</span> studios
                </div>

                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => handlePageChange(result.page - 1)}
                    disabled={!result.hasPreviousPage}
                    className="p-2 rounded-xl text-xs font-medium border border-[#E7E1D7] dark:border-[#2C2723] bg-[#FAF8F5] dark:bg-[#1C1917] text-[#57534E] dark:text-[#A8A29E] hover:border-[#C48A36] disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    aria-label="Previous page"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>

                  {Array.from({ length: result.totalPages }, (_, i) => i + 1).map(pageNum => (
                    <button
                      key={pageNum}
                      type="button"
                      onClick={() => handlePageChange(pageNum)}
                      className={`min-w-9 h-9 px-3 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                        result.page === pageNum
                          ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917] shadow-xs'
                          : 'bg-[#FAF8F5] dark:bg-[#1C1917] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36]'
                      }`}
                    >
                      {pageNum}
                    </button>
                  ))}

                  <button
                    type="button"
                    onClick={() => handlePageChange(result.page + 1)}
                    disabled={!result.hasNextPage}
                    className="p-2 rounded-xl text-xs font-medium border border-[#E7E1D7] dark:border-[#2C2723] bg-[#FAF8F5] dark:bg-[#1C1917] text-[#57534E] dark:text-[#A8A29E] hover:border-[#C48A36] disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer"
                    aria-label="Next page"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
};
