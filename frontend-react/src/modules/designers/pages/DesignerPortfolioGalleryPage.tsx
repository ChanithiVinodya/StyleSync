import React, { useState, useEffect } from 'react';
import { 
  ArrowLeft, 
  Layers, 
  Sparkles, 
  Briefcase, 
  Tag, 
  CheckCircle2, 
  Filter,
  Eye,
  Building2
} from 'lucide-react';
import { DesignerProfile, PortfolioItem, ListingStatus } from '../types';
import { designerApi } from '../services/designerApi';
import { PortfolioProjectCard } from '../components/PortfolioProjectCard';
import { PortfolioProjectModal } from '../components/PortfolioProjectModal';

interface DesignerPortfolioGalleryPageProps {
  designerId: number;
  onBack: () => void;
  onViewProfile?: () => void;
}

export const DesignerPortfolioGalleryPage: React.FC<DesignerPortfolioGalleryPageProps> = ({
  designerId,
  onBack,
  onViewProfile
}) => {
  const [profile, setProfile] = useState<DesignerProfile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [selectedItem, setSelectedItem] = useState<PortfolioItem | null>(null);
  const [statusFilter, setStatusFilter] = useState<'ALL' | ListingStatus>('ALL');

  useEffect(() => {
    let isMounted = true;
    async function loadPortfolio() {
      setIsLoading(true);
      setErrorMessage(null);
      try {
        const data = await designerApi.getProfile(designerId);
        if (isMounted) {
          setProfile(data);
        }
      } catch (err: unknown) {
        if (isMounted) {
          const msg = err instanceof Error ? err.message : 'Unable to load designer portfolio gallery';
          setErrorMessage(msg);
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }
    loadPortfolio();
    return () => { isMounted = false; };
  }, [designerId]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-8 flex flex-col items-center justify-center space-y-4">
        <div className="w-12 h-12 border-4 border-[#C48A36] border-t-transparent rounded-full animate-spin" />
        <span className="text-sm font-medium text-[#78716C] dark:text-[#A8A29E]">
          Loading verified portfolio gallery...
        </span>
      </div>
    );
  }

  if (errorMessage || !profile) {
    return (
      <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] p-8 flex flex-col items-center justify-center space-y-4">
        <p className="text-red-600 font-semibold">{errorMessage || 'Designer portfolio not found.'}</p>
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold bg-[#1C1917] text-[#FAF8F5]"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Directory
        </button>
      </div>
    );
  }

  // Filter portfolio items if user toggles status filter
  const items = profile.portfolioItems || [];
  const filteredItems = statusFilter === 'ALL'
    ? items
    : items.filter(item => item.completionStatusBadge === statusFilter);

  return (
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] pb-24 transition-colors">
      {/* Top Header & Navigation Bar */}
      <div className="border-b border-[#E7E1D7] dark:border-[#2C2723] bg-[#FAF8F5]/90 dark:bg-[#1A1715]/90 backdrop-blur-md sticky top-0 z-20 px-4 sm:px-6 lg:px-8 py-3.5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <button
            type="button"
            onClick={onBack}
            className="inline-flex items-center gap-2 text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to All Studios</span>
          </button>

          {onViewProfile && (
            <button
              type="button"
              onClick={onViewProfile}
              className="text-xs text-[#925C18] dark:text-[#E8A849] font-semibold hover:underline cursor-pointer"
            >
              View Studio Profile Overview →
            </button>
          )}
        </div>
      </div>

      {/* Hero Showcase Header */}
      <div className="bg-gradient-to-b from-[#F3EEE5] dark:from-[#1A1715] to-[#FDFBF7] dark:to-[#12100E] border-b border-[#E7E1D7] dark:border-[#2C2723] pt-12 pb-10 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30">
            <Building2 className="w-3.5 h-3.5" />
            <span>Dedicated Proof of Work Gallery</span>
          </div>

          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div>
              <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#1C1917] dark:text-[#FAF8F5]">
                {profile.displayName} — Portfolio Gallery
              </h1>
              <p className="mt-1.5 text-sm sm:text-base text-[#57534E] dark:text-[#A8A29E] max-w-3xl leading-relaxed">
                Authentic project deliverables and high-resolution architectural works showcasing tailored interior designs, material palettes, and spatial executions.
              </p>
            </div>

            {/* Total items badge */}
            <div className="px-4 py-2 rounded-2xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723] text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] self-start md:self-auto shrink-0 shadow-xs">
              <strong className="text-[#925C18] dark:text-[#E8A849] text-sm">{items.length}</strong> {items.length === 1 ? 'project' : 'projects'} in showcase
            </div>
          </div>
        </div>
      </div>

      {/* Gallery Filter & Grid Container */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-6">
        {/* Status Category Tabs */}
        <div className="flex flex-wrap items-center justify-between gap-4 p-3.5 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xs">
          <div className="flex items-center gap-1.5">
            <Filter className="w-4 h-4 text-[#925C18] dark:text-[#E8A849] mr-1 hidden sm:inline" />
            <span className="text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] mr-2">Filter Projects:</span>

            <div className="flex flex-wrap items-center gap-1.5">
              <button
                type="button"
                onClick={() => setStatusFilter('ALL')}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                  statusFilter === 'ALL'
                    ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917]'
                    : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723]'
                }`}
              >
                All ({items.length})
              </button>

              <button
                type="button"
                onClick={() => setStatusFilter(ListingStatus.Published)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                  statusFilter === ListingStatus.Published
                    ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917]'
                    : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723]'
                }`}
              >
                Published ({items.filter(i => i.completionStatusBadge === ListingStatus.Published).length})
              </button>

              <button
                type="button"
                onClick={() => setStatusFilter(ListingStatus.Draft)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                  statusFilter === ListingStatus.Draft
                    ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917]'
                    : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723]'
                }`}
              >
                Draft / In Progress ({items.filter(i => i.completionStatusBadge === ListingStatus.Draft).length})
              </button>

              <button
                type="button"
                onClick={() => setStatusFilter(ListingStatus.Archived)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-colors cursor-pointer ${
                  statusFilter === ListingStatus.Archived
                    ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917]'
                    : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723]'
                }`}
              >
                Archived ({items.filter(i => i.completionStatusBadge === ListingStatus.Archived).length})
              </button>
            </div>
          </div>

          <div className="text-xs text-[#78716C] dark:text-[#A8A29E]">
            Showing <strong>{filteredItems.length}</strong> works
          </div>
        </div>

        {/* Empty State */}
        {filteredItems.length === 0 && (
          <div className="p-16 text-center rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-dashed border-[#E7E1D7] dark:border-[#2C2723] space-y-3">
            <Layers className="w-12 h-12 text-[#78716C] mx-auto opacity-40" />
            <h3 className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              No portfolio projects found
            </h3>
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-sm mx-auto">
              There are no portfolio items in this category for {profile.displayName}.
            </p>
            {statusFilter !== 'ALL' && (
              <button
                type="button"
                onClick={() => setStatusFilter('ALL')}
                className="mt-2 px-4 py-2 rounded-xl text-xs font-semibold bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917]"
              >
                View All Projects
              </button>
            )}
          </div>
        )}

        {/* Grid of Portfolio Project Cards */}
        {filteredItems.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredItems.map(item => (
              <PortfolioProjectCard
                key={item.id}
                item={item}
                onClick={clicked => setSelectedItem(clicked)}
              />
            ))}
          </div>
        )}
      </main>

      {/* Full Project Detail Modal (Opens on card click) */}
      {selectedItem && (
        <PortfolioProjectModal
          item={selectedItem}
          designerDisplayName={profile.displayName}
          onClose={() => setSelectedItem(null)}
        />
      )}
    </div>
  );
};
