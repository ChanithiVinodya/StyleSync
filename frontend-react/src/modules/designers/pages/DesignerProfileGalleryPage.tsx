import React, { useState, useEffect } from 'react';
import { 
  ArrowLeft, 
  Star, 
  ShieldAlert, 
  ShieldCheck, 
  Image as ImageIcon, 
  DollarSign, 
  Tag, 
  Layers, 
  User, 
  CheckCircle2, 
  X,
  ExternalLink,
  Sparkles
} from 'lucide-react';
import { DesignerProfile, PortfolioItem, ListingStatus } from '../types';
import { designerApi } from '../services/designerApi';
import { CapacityStatusCard } from '../components/CapacityStatusCard';

interface DesignerProfileGalleryPageProps {
  designerId: number;
  onBack: () => void;
  onOpenStudio?: () => void;
  onOpenProofOfWork?: () => void;
}

export const DesignerProfileGalleryPage: React.FC<DesignerProfileGalleryPageProps> = ({
  designerId,
  onBack,
  onOpenStudio,
  onOpenProofOfWork
}) => {
  const [profile, setProfile] = useState<DesignerProfile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [selectedPhoto, setSelectedPhoto] = useState<PortfolioItem | null>(null);

  useEffect(() => {
    let isMounted = true;
    async function load() {
      setIsLoading(true);
      setErrorMessage(null);
      try {
        const data = await designerApi.getProfile(designerId);
        if (isMounted) {
          setProfile(data);
        }
      } catch (err: unknown) {
        if (isMounted) {
          const msg = err instanceof Error ? err.message : 'Failed to load designer profile';
          setErrorMessage(msg);
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }
    load();
    return () => { isMounted = false; };
  }, [designerId]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-8 flex flex-col items-center justify-center space-y-4">
        <div className="w-12 h-12 border-4 border-[#C48A36] border-t-transparent rounded-full animate-spin" />
        <span className="text-sm font-medium text-[#78716C] dark:text-[#A8A29E]">
          Loading designer portfolio...
        </span>
      </div>
    );
  }

  if (errorMessage || !profile) {
    return (
      <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] p-8 flex flex-col items-center justify-center space-y-4">
        <p className="text-red-600 font-semibold">{errorMessage || 'Designer profile not found.'}</p>
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold bg-[#1C1917] text-[#FAF8F5]"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Directory
        </button>
      </div>
    );
  }

  const publishedItems = profile.portfolioItems.filter(
    item => item.completionStatusBadge === ListingStatus.Published
  );

  return (
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] pb-24 transition-colors">
      {/* Top Breadcrumb Bar */}
      <div className="border-b border-[#E7E1D7] dark:border-[#2C2723] bg-[#FAF8F5] dark:bg-[#1A1715]/80 backdrop-blur-md sticky top-0 z-20 px-4 sm:px-6 lg:px-8 py-3.5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <button
            type="button"
            onClick={onBack}
            className="inline-flex items-center gap-2 text-xs font-semibold text-[#78716C] dark:text-[#A8A29E] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to All Designers</span>
          </button>

          {onOpenStudio && (
            <button
              type="button"
              onClick={onOpenStudio}
              className="text-xs text-[#925C18] dark:text-[#E8A849] font-semibold hover:underline cursor-pointer"
            >
              Open Studio Workspace
            </button>
          )}
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-10">
        {/* Profile Header Hero Card */}
        <div className="p-6 sm:p-8 rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] shadow-xs">
          <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-8">
            {/* Left: Bio & Studio Info */}
            <div className="space-y-4 max-w-3xl">
              <div className="flex flex-wrap items-center gap-3">
                <h1 className="text-2xl sm:text-3xl font-extrabold text-[#1C1917] dark:text-[#FAF8F5]">
                  {profile.displayName}
                </h1>

                {/* Rating Badge */}
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30 text-xs font-bold shadow-2xs">
                  <Star className="w-3.5 h-3.5 fill-[#EAB308] text-[#EAB308]" />
                  <span>
                    {profile.averageRating !== null && profile.averageRating !== undefined
                      ? `${profile.averageRating.toFixed(2)} Rating`
                      : 'New Studio'}
                  </span>
                </div>

                {/* Capacity Badge */}
                {profile.isAtCapacity ? (
                  <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 border border-amber-300 dark:border-amber-800 text-xs font-bold">
                    <ShieldAlert className="w-3.5 h-3.5" />
                    At Capacity ({profile.activeProjectCount}/{profile.maxConcurrentProjects} active)
                  </span>
                ) : profile.isAvailable ? (
                  <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-800 text-xs font-semibold">
                    <ShieldCheck className="w-3.5 h-3.5" />
                    Available ({profile.remainingCapacity} slots open)
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-stone-200 dark:bg-stone-800 text-stone-700 dark:text-stone-300 text-xs font-semibold">
                    Unavailable
                  </span>
                )}
              </div>

              <p className="text-sm sm:text-base text-[#57534E] dark:text-[#A8A29E] leading-relaxed">
                {profile.bio || "Crafting signature interior spaces with refined aesthetics, sustainable materials, and bespoke tailoring."}
              </p>

              {/* Style Tags */}
              <div className="space-y-1.5 pt-2">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                  Aesthetic Style Tags
                </span>
                <div className="flex flex-wrap gap-2">
                  {profile.styleTags.map((tag, i) => (
                    <span
                      key={i}
                      className="px-3 py-1 rounded-lg text-xs font-medium bg-[#F0ECE1] dark:bg-[#28221D] text-[#1C1917] dark:text-[#D6D3D1] border border-[#E7E1D7] dark:border-[#38312B]"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>

              {/* Service Categories */}
              {profile.serviceCategories && profile.serviceCategories.length > 0 && (
                <div className="space-y-1.5 pt-1">
                  <span className="text-[11px] font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
                    Services Offered
                  </span>
                  <div className="flex flex-wrap gap-2">
                    {profile.serviceCategories.map((cat, i) => (
                      <span
                        key={i}
                        className="px-2.5 py-0.5 rounded-md text-xs font-medium bg-[#F8F5F0] dark:bg-[#201D1A] text-[#78716C] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723]"
                      >
                        {cat}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Right: Quick Pricing & Key Figures Card */}
            <div className="w-full lg:w-80 flex flex-col gap-4 p-5 rounded-2xl bg-[#F8F5F0] dark:bg-[#221D19] border border-[#E7E1D7] dark:border-[#2C2723]">
              <span className="text-xs font-bold uppercase tracking-wider text-[#925C18] dark:text-[#E8A849]">
                Studio Pricing Structure
              </span>

              <div className="space-y-3">
                <div>
                  <span className="text-[10px] text-[#78716C] dark:text-[#A8A29E] block">Typical Project Budget</span>
                  <span className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                    LKR {profile.priceRangeMin.toLocaleString()} – {profile.priceRangeMax.toLocaleString()}
                  </span>
                </div>

                <div>
                  <span className="text-[10px] text-[#78716C] dark:text-[#A8A29E] block">Consultation & Design Rate</span>
                  <span className="text-base font-bold text-[#925C18] dark:text-[#E8A849]">
                    LKR {profile.ratePerSqFt.toLocaleString()} <span className="text-xs font-normal text-[#78716C]">/ sq.ft</span>
                  </span>
                </div>

                <div className="pt-2 border-t border-[#E7E1D7] dark:border-[#2C2723]">
                  <span className="text-[10px] text-[#78716C] dark:text-[#A8A29E] block">Active Workload Capacity</span>
                  <span className="text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5]">
                    {profile.activeProjectCount} of {profile.maxConcurrentProjects} active contracts
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Studio Capacity Guard Breakdown */}
        <div className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold text-[#1C1917] dark:text-[#FAF8F5]">
            <Layers className="w-4 h-4 text-[#925C18] dark:text-[#E8A849]" />
            <span>Capacity & Overbooking Guard Status</span>
          </div>
          <CapacityStatusCard profile={profile} />
        </div>

        {/* Portfolio Gallery Section */}
        <div className="space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 border-b border-[#E7E1D7] dark:border-[#2C2723] pb-4">
            <div>
              <h2 className="text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
                Published Portfolio Gallery
              </h2>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                High-resolution architectural renders and finished project showcases ({publishedItems.length} items)
              </p>
            </div>

            {onOpenProofOfWork && (
              <button
                type="button"
                onClick={onOpenProofOfWork}
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30 hover:border-[#C48A36] transition-colors self-start sm:self-auto cursor-pointer"
              >
                <Sparkles className="w-3.5 h-3.5" />
                <span>Dedicated Proof-of-Work Gallery Screen →</span>
              </button>
            )}
          </div>

          {publishedItems.length === 0 ? (
            <div className="p-12 text-center rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-dashed border-[#E7E1D7] dark:border-[#2C2723] space-y-2">
              <ImageIcon className="w-10 h-10 text-[#78716C] mx-auto opacity-50" />
              <h3 className="text-sm font-bold text-[#1C1917] dark:text-[#FAF8F5]">No published projects yet</h3>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                This designer has not yet published showcase projects to their public gallery.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {publishedItems.map(item => (
                <div
                  key={item.id}
                  onClick={() => setSelectedPhoto(item)}
                  className="group relative flex flex-col rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36] overflow-hidden shadow-xs hover:shadow-lg transition-all duration-300 cursor-pointer"
                >
                  <div className="relative h-60 w-full overflow-hidden bg-[#EAE4D9] dark:bg-[#2A2420]">
                    <img
                      src={item.imageUrl}
                      alt={item.title}
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      loading="lazy"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-4">
                      <span className="text-xs font-semibold text-white flex items-center gap-1.5">
                        <Sparkles className="w-3.5 h-3.5" /> Click to enlarge
                      </span>
                    </div>

                    {/* Client Initials Pill */}
                    {item.clientInitials && (
                      <span className="absolute top-3 left-3 px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#1C1917]/80 text-[#FAF8F5] backdrop-blur-xs">
                        Client: {item.clientInitials}
                      </span>
                    )}

                    {/* Budget Range Label */}
                    {item.budgetRangeLabel && (
                      <span className="absolute top-3 right-3 px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#FAF3E8]/90 text-[#925C18] border border-[#C48A36]/30 backdrop-blur-xs">
                        {item.budgetRangeLabel}
                      </span>
                    )}
                  </div>

                  <div className="p-5 space-y-2 flex-1 flex flex-col">
                    <h3 className="text-base font-bold text-[#1C1917] dark:text-[#FAF8F5] group-hover:text-[#925C18] dark:group-hover:text-[#E8A849] transition-colors">
                      {item.title}
                    </h3>
                    <p className="text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-3 leading-relaxed">
                      {item.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Lightbox / Project Details Modal */}
      {selectedPhoto && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/80 backdrop-blur-sm animate-fadeIn">
          <div className="relative max-w-4xl w-full rounded-3xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="flex items-center justify-between p-4 px-6 border-b border-[#E7E1D7] dark:border-[#2C2723]">
              <div>
                <h3 className="text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">{selectedPhoto.title}</h3>
                <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                  Designed by {profile.displayName}
                </span>
              </div>
              <button
                onClick={() => setSelectedPhoto(null)}
                className="p-2 rounded-full hover:bg-[#EAE4D9] dark:hover:bg-[#2A2420] text-[#78716C] dark:text-[#A8A29E] transition-colors cursor-pointer"
                aria-label="Close modal"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Image Body */}
            <div className="overflow-y-auto p-6 space-y-4">
              <div className="rounded-2xl overflow-hidden bg-black max-h-[60vh] flex items-center justify-center">
                <img
                  src={selectedPhoto.imageUrl}
                  alt={selectedPhoto.title}
                  className="max-h-[60vh] w-auto object-contain"
                />
              </div>

              <div className="flex flex-wrap items-center justify-between gap-3 pt-2">
                <div className="flex items-center gap-3">
                  {selectedPhoto.clientInitials && (
                    <span className="px-3 py-1 rounded-full text-xs font-semibold bg-[#F0ECE1] dark:bg-[#28221D] text-[#1C1917] dark:text-[#FAF8F5]">
                      Client: {selectedPhoto.clientInitials}
                    </span>
                  )}
                  {selectedPhoto.budgetRangeLabel && (
                    <span className="px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#C48A36]/30">
                      Budget: {selectedPhoto.budgetRangeLabel}
                    </span>
                  )}
                </div>
              </div>

              <p className="text-sm text-[#57534E] dark:text-[#A8A29E] leading-relaxed pt-2">
                {selectedPhoto.description}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
