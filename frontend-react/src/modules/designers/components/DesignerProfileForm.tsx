import React, { useState, useEffect } from 'react';
import { 
  Check, 
  X, 
  Plus, 
  Sparkles, 
  Building2, 
  DollarSign, 
  Sliders, 
  Save, 
  AlertCircle, 
  CheckCircle2,
  Info
} from 'lucide-react';
import { 
  DesignerProfile, 
  ListingStatus, 
  DesignerProfileFormState, 
  FormValidationErrors,
  UpdateDesignerProfileRequest 
} from '../types';

interface DesignerProfileFormProps {
  initialProfile: DesignerProfile;
  onSave: (updated: UpdateDesignerProfileRequest) => Promise<void>;
  isLoading?: boolean;
}

const SUGGESTED_STYLES: string[] = [
  'Tropical Modernism',
  'Minimalist',
  'Japandi',
  'Scandinavian',
  'Boho Chic',
  'Industrial',
  'Coastal',
  'Classic Luxury',
  'Contemporary',
  'Biophilic',
  'Traditional Sri Lankan',
  'Art Deco'
];

const AVAILABLE_CATEGORIES: string[] = [
  'Full Home Interior',
  'Living Room',
  'Bedroom Design',
  'Kitchen & Dining',
  'Bathroom Renovation',
  'Studio Apartment',
  'Villa & Boutique Hotel',
  'Commercial & Office',
  'Color Consultation'
];

export const DesignerProfileForm: React.FC<DesignerProfileFormProps> = ({
  initialProfile,
  onSave,
  isLoading = false,
}) => {
  const [formState, setFormState] = useState<DesignerProfileFormState>({
    displayName: initialProfile.displayName || '',
    bio: initialProfile.bio || '',
    styleTags: initialProfile.styleTags || [],
    serviceCategories: initialProfile.serviceCategories || [],
    priceRangeMin: initialProfile.priceRangeMin?.toString() || '100000',
    priceRangeMax: initialProfile.priceRangeMax?.toString() || '500000',
    ratePerSqFt: initialProfile.ratePerSqFt?.toString() || '400',
    isAvailable: initialProfile.isAvailable ?? true,
    maxConcurrentProjects: initialProfile.maxConcurrentProjects?.toString() || '3',
    listingStatus: initialProfile.listingStatus ?? ListingStatus.Published,
  });

  const [customTagInput, setCustomTagInput] = useState('');
  const [errors, setErrors] = useState<FormValidationErrors>({});
  const [saveSuccess, setSaveSuccess] = useState(false);

  useEffect(() => {
    setFormState({
      displayName: initialProfile.displayName || '',
      bio: initialProfile.bio || '',
      styleTags: initialProfile.styleTags || [],
      serviceCategories: initialProfile.serviceCategories || [],
      priceRangeMin: initialProfile.priceRangeMin?.toString() || '100000',
      priceRangeMax: initialProfile.priceRangeMax?.toString() || '500000',
      ratePerSqFt: initialProfile.ratePerSqFt?.toString() || '400',
      isAvailable: initialProfile.isAvailable ?? true,
      maxConcurrentProjects: initialProfile.maxConcurrentProjects?.toString() || '3',
      listingStatus: initialProfile.listingStatus ?? ListingStatus.Published,
    });
  }, [initialProfile]);

  const validateForm = (): boolean => {
    const newErrors: FormValidationErrors = {};

    if (!formState.displayName.trim()) {
      newErrors.displayName = 'Studio/Display Name is required.';
    } else if (formState.displayName.trim().length > 200) {
      newErrors.displayName = 'Display Name cannot exceed 200 characters.';
    }

    if (!formState.bio.trim()) {
      newErrors.bio = 'Bio/Studio Description is required.';
    } else if (formState.bio.trim().length > 2000) {
      newErrors.bio = 'Bio cannot exceed 2000 characters.';
    }

    const minPrice = parseFloat(formState.priceRangeMin);
    const maxPrice = parseFloat(formState.priceRangeMax);
    const sqFtRate = parseFloat(formState.ratePerSqFt);
    const maxProjects = parseInt(formState.maxConcurrentProjects, 10);

    if (isNaN(minPrice) || minPrice < 0) {
      newErrors.priceRangeMin = 'Minimum price must be a non-negative number.';
    }

    if (isNaN(maxPrice) || maxPrice < 0) {
      newErrors.priceRangeMax = 'Maximum price must be a non-negative number.';
    }

    if (!isNaN(minPrice) && !isNaN(maxPrice) && minPrice > maxPrice) {
      newErrors.priceRangeMin = 'PriceRangeMin cannot be greater than PriceRangeMax.';
      newErrors.priceRangeMax = 'PriceRangeMax must be greater than or equal to PriceRangeMin.';
    }

    if (isNaN(sqFtRate) || sqFtRate < 0) {
      newErrors.ratePerSqFt = 'Rate per sq.ft must be a non-negative number.';
    }

    if (isNaN(maxProjects) || maxProjects < 1) {
      newErrors.maxConcurrentProjects = 'Max concurrent projects must be at least 1.';
    }

    if (formState.styleTags.length === 0) {
      newErrors.styleTags = 'Please select at least one design style tag.';
    }

    if (formState.serviceCategories.length === 0) {
      newErrors.serviceCategories = 'Please select at least one service category.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleAddTag = (tag: string) => {
    const trimmed = tag.trim();
    if (!trimmed) return;
    if (!formState.styleTags.includes(trimmed)) {
      setFormState(prev => ({
        ...prev,
        styleTags: [...prev.styleTags, trimmed]
      }));
      setErrors(prev => ({ ...prev, styleTags: undefined }));
    }
    setCustomTagInput('');
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormState(prev => ({
      ...prev,
      styleTags: prev.styleTags.filter(t => t !== tagToRemove)
    }));
  };

  const handleToggleCategory = (category: string) => {
    setFormState(prev => {
      const exists = prev.serviceCategories.includes(category);
      const updated = exists 
        ? prev.serviceCategories.filter(c => c !== category)
        : [...prev.serviceCategories, category];
      return { ...prev, serviceCategories: updated };
    });
    setErrors(prev => ({ ...prev, serviceCategories: undefined }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaveSuccess(false);

    if (!validateForm()) {
      return;
    }

    const payload: UpdateDesignerProfileRequest = {
      displayName: formState.displayName.trim(),
      bio: formState.bio.trim(),
      styleTags: formState.styleTags,
      serviceCategories: formState.serviceCategories,
      priceRangeMin: parseFloat(formState.priceRangeMin),
      priceRangeMax: parseFloat(formState.priceRangeMax),
      ratePerSqFt: parseFloat(formState.ratePerSqFt),
      isAvailable: formState.isAvailable,
      listingStatus: formState.listingStatus,
    };

    try {
      await onSave(payload);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 4000);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to save profile.';
      setErrors(prev => ({ ...prev, general: message }));
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6 sm:space-y-8">
      {/* Alert / Feedback */}
      {saveSuccess && (
        <div className="flex items-center gap-3 p-4 rounded-xl bg-[#DCFCE7] dark:bg-[#143823] border border-[#BBF7D0] dark:border-[#1E5638] text-[#166534] dark:text-[#86EFAC] text-sm animate-fadeIn">
          <CheckCircle2 className="w-5 h-5 shrink-0" />
          <span>Designer profile updated successfully! All match scores and directory filters updated in real-time.</span>
        </div>
      )}

      {errors.general && (
        <div className="flex items-center gap-3 p-4 rounded-xl bg-[#FEE2E2] dark:bg-[#451A1A] border border-[#FECACA] dark:border-[#7F1D1D] text-[#991B1B] dark:text-[#FCA5A5] text-sm">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{errors.general}</span>
        </div>
      )}

      {/* 1. Basic Identity */}
      <div className="p-5 sm:p-7 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] space-y-5">
        <div className="flex items-center gap-2.5 pb-3 border-b border-[#E7E1D7] dark:border-[#2C2723]">
          <Building2 className="w-5 h-5 text-[#925C18] dark:text-[#E8A849]" />
          <h4 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
            Studio Identity & Biography
          </h4>
        </div>

        {/* Display Name */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1.5">
            Studio / Display Name <span className="text-[#DC2626]">*</span>
          </label>
          <input
            type="text"
            value={formState.displayName}
            onChange={e => {
              setFormState(prev => ({ ...prev, displayName: e.target.value }));
              setErrors(prev => ({ ...prev, displayName: undefined }));
            }}
            placeholder="e.g. Jayawardena Architecture & Interiors"
            className={`w-full px-4 py-3 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border ${
              errors.displayName ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
            } text-[#1C1917] dark:text-[#FAF8F5] text-sm focus:outline-hidden focus:ring-2 focus:ring-[#C48A36] transition-colors`}
          />
          {errors.displayName && (
            <p className="mt-1.5 text-xs text-[#DC2626]">{errors.displayName}</p>
          )}
        </div>

        {/* Bio */}
        <div>
          <div className="flex justify-between items-center mb-1.5">
            <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E]">
              Design Philosophy & Biography <span className="text-[#DC2626]">*</span>
            </label>
            <span className="text-[11px] text-[#78716C] dark:text-[#A8A29E]">
              {formState.bio.length} / 2000
            </span>
          </div>
          <textarea
            rows={4}
            value={formState.bio}
            onChange={e => {
              setFormState(prev => ({ ...prev, bio: e.target.value }));
              setErrors(prev => ({ ...prev, bio: undefined }));
            }}
            placeholder="Describe your design ethos, architectural background, craftsmanship materials, and types of spaces you love transforming..."
            className={`w-full px-4 py-3 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border ${
              errors.bio ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
            } text-[#1C1917] dark:text-[#FAF8F5] text-sm focus:outline-hidden focus:ring-2 focus:ring-[#C48A36] transition-colors`}
          />
          {errors.bio && (
            <p className="mt-1.5 text-xs text-[#DC2626]">{errors.bio}</p>
          )}
        </div>
      </div>

      {/* 2. Aesthetics & Services */}
      <div className="p-5 sm:p-7 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] space-y-6">
        <div className="flex items-center gap-2.5 pb-3 border-b border-[#E7E1D7] dark:border-[#2C2723]">
          <Sparkles className="w-5 h-5 text-[#925C18] dark:text-[#E8A849]" />
          <div>
            <h4 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
              Style Signatures & Service Offerings
            </h4>
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              Used directly by the deterministic match-score engine (40% style weight)
            </p>
          </div>
        </div>

        {/* Style Tags */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
            Selected Style Tags <span className="text-[#DC2626]">*</span>
          </label>

          {/* Active Tags */}
          <div className="flex flex-wrap gap-2 mb-3 min-h-[38px] p-2.5 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
            {formState.styleTags.length === 0 ? (
              <span className="text-xs text-[#A8A29E] italic self-center">No styles added yet. Select from suggestions below or add custom tags.</span>
            ) : (
              formState.styleTags.map(tag => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border border-[#EADBCA] dark:border-[#3D3328]"
                >
                  {tag}
                  <button
                    type="button"
                    onClick={() => handleRemoveTag(tag)}
                    className="hover:text-[#DC2626] transition-colors cursor-pointer"
                    aria-label={`Remove ${tag}`}
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </span>
              ))
            )}
          </div>
          {errors.styleTags && <p className="text-xs text-[#DC2626] mb-2">{errors.styleTags}</p>}

          {/* Add custom tag input */}
          <div className="flex gap-2 mb-3">
            <input
              type="text"
              value={customTagInput}
              onChange={e => setCustomTagInput(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  handleAddTag(customTagInput);
                }
              }}
              placeholder="Add custom style tag (press Enter)..."
              className="flex-1 px-3.5 py-2 text-xs rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723] text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]"
            />
            <button
              type="button"
              onClick={() => handleAddTag(customTagInput)}
              className="inline-flex items-center gap-1 px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-[#EFEAE1] dark:bg-[#2C2723] hover:bg-[#E4DDD1] dark:hover:bg-[#38312B] rounded-xl border border-[#E2D8C9] dark:border-[#382F26] transition-colors"
            >
              <Plus className="w-3.5 h-3.5" />
              Add
            </button>
          </div>

          {/* Quick Add Suggestions */}
          <div>
            <span className="text-[11px] font-medium text-[#78716C] dark:text-[#A8A29E] block mb-1.5">
              Popular Architectural Styles (click to toggle):
            </span>
            <div className="flex flex-wrap gap-1.5">
              {SUGGESTED_STYLES.map(style => {
                const isSelected = formState.styleTags.includes(style);
                return (
                  <button
                    key={style}
                    type="button"
                    onClick={() => isSelected ? handleRemoveTag(style) : handleAddTag(style)}
                    className={`px-2.5 py-1 text-xs rounded-lg transition-all ${
                      isSelected
                        ? 'bg-[#1C1917] text-[#FAF8F5] dark:bg-[#FAF8F5] dark:text-[#1C1917] font-semibold'
                        : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36]'
                    }`}
                  >
                    {isSelected && '✓ '}
                    {style}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Service Categories */}
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
            Service Categories Offered <span className="text-[#DC2626]">*</span>
          </label>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
            {AVAILABLE_CATEGORIES.map(category => {
              const isSelected = formState.serviceCategories.includes(category);
              return (
                <button
                  key={category}
                  type="button"
                  onClick={() => handleToggleCategory(category)}
                  className={`flex items-center gap-2 p-2.5 rounded-xl text-left text-xs transition-all border ${
                    isSelected
                      ? 'bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border-[#C48A36] font-semibold'
                      : 'bg-[#FAF8F5] dark:bg-[#201D1A] text-[#57534E] dark:text-[#A8A29E] border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#D6CAB8]'
                  }`}
                >
                  <div className={`w-4 h-4 rounded-md flex items-center justify-center border ${
                    isSelected ? 'bg-[#925C18] dark:bg-[#E8A849] border-transparent text-white' : 'border-[#A8A29E]'
                  }`}>
                    {isSelected && <Check className="w-3 h-3 stroke-[3]" />}
                  </div>
                  <span>{category}</span>
                </button>
              );
            })}
          </div>
          {errors.serviceCategories && <p className="text-xs text-[#DC2626] mt-1.5">{errors.serviceCategories}</p>}
        </div>
      </div>

      {/* 3. Pricing & Rates */}
      <div className="p-5 sm:p-7 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] space-y-5">
        <div className="flex items-center gap-2.5 pb-3 border-b border-[#E7E1D7] dark:border-[#2C2723]">
          <DollarSign className="w-5 h-5 text-[#925C18] dark:text-[#E8A849]" />
          <div>
            <h4 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
              Pricing & Rate Structure
            </h4>
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              RatePerSqFt is saved with your designer profile and consumed by Component 3 quotation tools
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {/* Price Range Min */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1.5">
              Min Project Budget (LKR) <span className="text-[#DC2626]">*</span>
            </label>
            <input
              type="number"
              step="1000"
              value={formState.priceRangeMin}
              onChange={e => {
                setFormState(prev => ({ ...prev, priceRangeMin: e.target.value }));
                setErrors(prev => ({ ...prev, priceRangeMin: undefined }));
              }}
              className={`w-full px-4 py-3 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border ${
                errors.priceRangeMin ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
              } text-[#1C1917] dark:text-[#FAF8F5] text-sm focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
            />
            {errors.priceRangeMin && <p className="mt-1 text-xs text-[#DC2626]">{errors.priceRangeMin}</p>}
          </div>

          {/* Price Range Max */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1.5">
              Max Project Budget (LKR) <span className="text-[#DC2626]">*</span>
            </label>
            <input
              type="number"
              step="1000"
              value={formState.priceRangeMax}
              onChange={e => {
                setFormState(prev => ({ ...prev, priceRangeMax: e.target.value }));
                setErrors(prev => ({ ...prev, priceRangeMax: undefined }));
              }}
              className={`w-full px-4 py-3 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border ${
                errors.priceRangeMax ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
              } text-[#1C1917] dark:text-[#FAF8F5] text-sm focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
            />
            {errors.priceRangeMax && <p className="mt-1 text-xs text-[#DC2626]">{errors.priceRangeMax}</p>}
          </div>

          {/* Rate Per Sq Ft */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1.5">
              Rate / Sq.Ft (LKR) <span className="text-[#DC2626]">*</span>
            </label>
            <input
              type="number"
              step="10"
              value={formState.ratePerSqFt}
              onChange={e => {
                setFormState(prev => ({ ...prev, ratePerSqFt: e.target.value }));
                setErrors(prev => ({ ...prev, ratePerSqFt: undefined }));
              }}
              className={`w-full px-4 py-3 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border ${
                errors.ratePerSqFt ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
              } text-[#1C1917] dark:text-[#FAF8F5] text-sm focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
            />
            {errors.ratePerSqFt && <p className="mt-1 text-xs text-[#DC2626]">{errors.ratePerSqFt}</p>}
          </div>
        </div>
      </div>

      {/* 4. Availability & Publishing Status */}
      <div className="p-5 sm:p-7 rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] space-y-5">
        <div className="flex items-center gap-2.5 pb-3 border-b border-[#E7E1D7] dark:border-[#2C2723]">
          <Sliders className="w-5 h-5 text-[#925C18] dark:text-[#E8A849]" />
          <h4 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
            Listing Lifecycle & Availability
          </h4>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
          {/* Availability Toggle */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
            <div className="space-y-0.5">
              <span className="text-sm font-semibold text-[#1C1917] dark:text-[#FAF8F5] block">
                Accept New Inquiries (isAvailable)
              </span>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                Turn off to temporarily pause new client matches while keeping portfolio visible.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setFormState(prev => ({ ...prev, isAvailable: !prev.isAvailable }))}
              className={`w-12 h-6 flex items-center rounded-full p-1 transition-colors cursor-pointer shrink-0 ml-3 ${
                formState.isAvailable ? 'bg-[#16A34A]' : 'bg-[#D6D3D1] dark:bg-[#44403C]'
              }`}
            >
              <div
                className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                  formState.isAvailable ? 'translate-x-6' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          {/* Listing Status Toggle */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
            <div className="space-y-0.5">
              <span className="text-sm font-semibold text-[#1C1917] dark:text-[#FAF8F5] block">
                Publish Status
              </span>
              <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
                Published listings appear in search directories and matching pools.
              </p>
            </div>
            <select
              value={formState.listingStatus}
              onChange={e => setFormState(prev => ({ ...prev, listingStatus: parseInt(e.target.value, 10) as ListingStatus }))}
              className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-[#FAF8F5] dark:bg-[#26211C] border border-[#E7E1D7] dark:border-[#382F26] text-[#1C1917] dark:text-[#FAF8F5]"
            >
              <option value={ListingStatus.Draft}>Draft (Private)</option>
              <option value={ListingStatus.Published}>Published (Live)</option>
            </select>
          </div>
        </div>

        <div className="flex items-start gap-2 p-3 rounded-xl bg-[#FAF3E8] dark:bg-[#241F1A] border border-[#EADBCA] dark:border-[#382F24] text-[11px] text-[#925C18] dark:text-[#E8A849]">
          <Info className="w-4 h-4 shrink-0 mt-0.5" />
          <span>
            <strong>Capacity Guard Notice:</strong> Your concurrent project limit is currently set to <strong>{initialProfile.maxConcurrentProjects}</strong> (configured by Administrator). If your active projects reach this limit, the system will automatically hold new candidate assignments regardless of availability status.
          </span>
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex justify-end pt-2">
        <button
          type="submit"
          disabled={isLoading}
          className="inline-flex items-center gap-2 px-8 py-3.5 rounded-full font-medium text-sm text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] shadow-md hover:shadow-lg transition-all cursor-pointer disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          <span>{isLoading ? 'Saving Changes...' : 'Save Profile Changes'}</span>
        </button>
      </div>
    </form>
  );
};
