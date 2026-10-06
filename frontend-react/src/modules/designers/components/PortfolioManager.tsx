import React, { useState } from 'react';
import { 
  Plus, 
  Trash2, 
  Image as ImageIcon, 
  ExternalLink, 
  Sparkles, 
  X, 
  AlertCircle, 
  CheckCircle2,
  Lock,
  Eye,
  EyeOff
} from 'lucide-react';
import { 
  PortfolioItem, 
  ListingStatus, 
  CreatePortfolioItemRequest, 
  PortfolioItemFormState, 
  PortfolioItemValidationErrors 
} from '../types';

interface PortfolioManagerProps {
  designerId: number;
  items: PortfolioItem[];
  onAddItem: (request: CreatePortfolioItemRequest) => Promise<void>;
  onDeleteItem: (itemId: number) => Promise<void>;
  isLoading?: boolean;
}

const INITIAL_ITEM_STATE: PortfolioItemFormState = {
  title: '',
  description: '',
  imageUrl: '',
  budgetRangeLabel: '',
  clientInitials: '',
  completionStatusBadge: ListingStatus.Published
};

export const PortfolioManager: React.FC<PortfolioManagerProps> = ({
  designerId,
  items,
  onAddItem,
  onDeleteItem,
  isLoading = false
}) => {
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [formState, setFormState] = useState<PortfolioItemFormState>(INITIAL_ITEM_STATE);
  const [errors, setErrors] = useState<PortfolioItemValidationErrors>({});
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [previewError, setPreviewError] = useState(false);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  const validateItemForm = (): boolean => {
    const newErrors: PortfolioItemValidationErrors = {};

    if (!formState.title.trim()) {
      newErrors.title = 'Project title is required.';
    } else if (formState.title.trim().length > 200) {
      newErrors.title = 'Project title cannot exceed 200 characters.';
    }

    if (!formState.description.trim()) {
      newErrors.description = 'Project description is required.';
    } else if (formState.description.trim().length > 2000) {
      newErrors.description = 'Description cannot exceed 2000 characters.';
    }

    if (!formState.imageUrl.trim()) {
      newErrors.imageUrl = 'Image URL is required.';
    } else {
      try {
        new URL(formState.imageUrl.trim());
      } catch {
        newErrors.imageUrl = 'Please provide a valid image URL.';
      }
    }

    if (!formState.budgetRangeLabel.trim()) {
      newErrors.budgetRangeLabel = 'Budget range label is required (e.g. "LKR 200k-350k").';
    } else if (formState.budgetRangeLabel.trim().length > 100) {
      newErrors.budgetRangeLabel = 'Budget range label cannot exceed 100 characters.';
    }

    if (!formState.clientInitials.trim()) {
      newErrors.clientInitials = 'Client initials are required (e.g. "K.M.").';
    } else if (formState.clientInitials.trim().length > 10) {
      newErrors.clientInitials = 'Client initials cannot exceed 10 characters.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleCreateItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateItemForm()) return;

    try {
      await onAddItem({
        title: formState.title.trim(),
        description: formState.description.trim(),
        imageUrl: formState.imageUrl.trim(),
        budgetRangeLabel: formState.budgetRangeLabel.trim(),
        clientInitials: formState.clientInitials.trim(),
        completionStatusBadge: formState.completionStatusBadge
      });

      setIsAddModalOpen(false);
      setFormState(INITIAL_ITEM_STATE);
      setErrors({});
      setActionSuccess('Portfolio project published successfully!');
      setTimeout(() => setActionSuccess(null), 3500);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to add portfolio item.';
      setErrors(prev => ({ ...prev, general: message }));
    }
  };

  const handleDelete = async (itemId: number) => {
    try {
      setDeletingId(itemId);
      await onDeleteItem(itemId);
      setActionSuccess('Portfolio project deleted.');
      setTimeout(() => setActionSuccess(null), 3500);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to delete item.';
      alert(message);
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Add Button */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="font-serif text-xl font-medium text-[#1C1917] dark:text-[#FAF8F5]">
            Portfolio Showcase ({items.length})
          </h3>
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
            Highlight completed spaces to attract client style matches and demonstrate past room transformations.
          </p>
        </div>

        <button
          type="button"
          onClick={() => {
            setFormState(INITIAL_ITEM_STATE);
            setErrors({});
            setPreviewError(false);
            setIsAddModalOpen(true);
          }}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-xs font-semibold text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] shadow-sm hover:shadow-md transition-all cursor-pointer shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>Add Portfolio Project</span>
        </button>
      </div>

      {/* Success Notification */}
      {actionSuccess && (
        <div className="flex items-center gap-2 p-3.5 rounded-xl bg-[#DCFCE7] dark:bg-[#143823] border border-[#BBF7D0] dark:border-[#1E5638] text-[#166534] dark:text-[#86EFAC] text-xs font-medium animate-fadeIn">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          <span>{actionSuccess}</span>
        </div>
      )}

      {/* Grid of Portfolio Items */}
      {items.length === 0 ? (
        <div className="p-12 text-center rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-dashed border-[#D6CAB8] dark:border-[#382F26] space-y-3">
          <div className="w-12 h-12 rounded-full bg-[#EFEAE1] dark:bg-[#28221D] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] mx-auto">
            <ImageIcon className="w-6 h-6" />
          </div>
          <h4 className="font-serif text-base font-medium text-[#1C1917] dark:text-[#FAF8F5]">
            No portfolio projects added yet
          </h4>
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E] max-w-md mx-auto">
            Upload images and descriptions of your completed interiors to establish credibility and showcase your aesthetic signature.
          </p>
          <button
            type="button"
            onClick={() => setIsAddModalOpen(true)}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full text-xs font-semibold text-[#925C18] dark:text-[#E8A849] bg-[#FAF3E8] dark:bg-[#2A231C] border border-[#EADBCA] dark:border-[#3D3328] hover:bg-[#F2E5D3] dark:hover:bg-[#382F24] transition-colors"
          >
            <Plus className="w-3.5 h-3.5" />
            Add First Project
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
          {items.map(item => (
            <div
              key={item.id}
              className="group rounded-2xl overflow-hidden bg-[#FAF8F5] dark:bg-[#1E1B18] border border-[#E7E1D7] dark:border-[#2C2723] hover:border-[#C48A36]/60 dark:hover:border-[#C48A36]/60 shadow-xs hover:shadow-lg transition-all duration-300 flex flex-col"
            >
              {/* Image Container */}
              <div className="relative aspect-4/3 w-full overflow-hidden bg-[#EFEAE1] dark:bg-[#26211C]">
                <img
                  src={item.imageUrl}
                  alt={item.title}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=800&q=80';
                  }}
                />

                {/* Status Badge */}
                <div className="absolute top-3 left-3 flex items-center gap-1.5">
                  <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider backdrop-blur-md shadow-xs border ${
                    item.completionStatusBadge === ListingStatus.Published
                      ? 'bg-[#142C1D]/90 text-[#4ADE80] border-[#1E4E30]'
                      : item.completionStatusBadge === ListingStatus.Draft
                      ? 'bg-[#342F15]/90 text-[#FDE047] border-[#4D451E]'
                      : 'bg-[#2A2A2A]/90 text-[#A3A3A3] border-[#404040]'
                  }`}>
                    {ListingStatus[item.completionStatusBadge]}
                  </span>
                </div>

                {/* Client Initials Pill */}
                <div className="absolute top-3 right-3">
                  <span className="px-2 py-0.5 rounded-md text-[10px] font-semibold bg-[#1C1917]/85 text-[#FAF8F5] backdrop-blur-md border border-[#FAF8F5]/20 shadow-xs" title={`Client: ${item.clientInitials}`}>
                    Client {item.clientInitials}
                  </span>
                </div>

                {/* Budget Range Label Floating Overlay */}
                <div className="absolute bottom-3 left-3">
                  <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-[#1C1917]/90 text-[#FAF8F5] backdrop-blur-md border border-[#FAF8F5]/20">
                    {item.budgetRangeLabel}
                  </span>
                </div>
              </div>

              {/* Card Body */}
              <div className="p-4 sm:p-5 flex-1 flex flex-col justify-between space-y-3">
                <div className="space-y-1.5">
                  <h4 className="font-serif text-base font-semibold text-[#1C1917] dark:text-[#FAF8F5] leading-snug">
                    {item.title}
                  </h4>
                  <p className="text-xs text-[#57534E] dark:text-[#A8A29E] line-clamp-2 leading-relaxed">
                    {item.description}
                  </p>
                </div>

                {/* Action Bar */}
                <div className="flex items-center justify-between pt-2 border-t border-[#E7E1D7] dark:border-[#2C2723] text-xs">
                  <span className="text-[11px] text-[#78716C] dark:text-[#8C8681]">
                    Added {new Date(item.createdAtUtc).toLocaleDateString()}
                  </span>

                  <button
                    type="button"
                    onClick={() => {
                      if (window.confirm(`Are you sure you want to delete "${item.title}"?`)) {
                        handleDelete(item.id);
                      }
                    }}
                    disabled={deletingId === item.id || isLoading}
                    className="inline-flex items-center gap-1 text-xs text-[#DC2626] hover:text-[#B91C1C] dark:text-[#F87171] dark:hover:text-[#EF4444] font-medium transition-colors cursor-pointer disabled:opacity-50"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>{deletingId === item.id ? 'Deleting...' : 'Delete'}</span>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Item Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fadeIn">
          <div 
            className="w-full max-w-xl max-h-[90vh] overflow-y-auto rounded-2xl bg-[#FAF8F5] dark:bg-[#1C1917] border border-[#E7E1D7] dark:border-[#2C2723] shadow-2xl p-6 sm:p-8 space-y-5 animate-scaleUp"
            onClick={e => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex items-center justify-between pb-3 border-b border-[#E7E1D7] dark:border-[#2C2723]">
              <div className="flex items-center gap-2.5">
                <ImageIcon className="w-5 h-5 text-[#925C18] dark:text-[#E8A849]" />
                <h3 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
                  Add Portfolio Project
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setIsAddModalOpen(false)}
                className="p-1 rounded-lg text-[#78716C] hover:text-[#1C1917] dark:text-[#A8A29E] dark:hover:text-[#FAF8F5] transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {errors.general && (
              <div className="flex items-center gap-2 p-3 rounded-xl bg-[#FEE2E2] dark:bg-[#451A1A] border border-[#FECACA] dark:border-[#7F1D1D] text-[#991B1B] dark:text-[#FCA5A5] text-xs">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{errors.general}</span>
              </div>
            )}

            <form onSubmit={handleCreateItem} className="space-y-4 text-left">
              {/* Title */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                  Project Title <span className="text-[#DC2626]">*</span>
                </label>
                <input
                  type="text"
                  value={formState.title}
                  onChange={e => {
                    setFormState(prev => ({ ...prev, title: e.target.value }));
                    setErrors(prev => ({ ...prev, title: undefined }));
                  }}
                  placeholder="e.g. Bawa-Inspired Courtyard Residence"
                  className={`w-full px-3.5 py-2.5 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border ${
                    errors.title ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
                  } text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
                />
                {errors.title && <p className="mt-1 text-xs text-[#DC2626]">{errors.title}</p>}
              </div>

              {/* Image URL & Live Preview */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                  Image URL <span className="text-[#DC2626]">*</span>
                </label>
                <input
                  type="url"
                  value={formState.imageUrl}
                  onChange={e => {
                    setFormState(prev => ({ ...prev, imageUrl: e.target.value }));
                    setErrors(prev => ({ ...prev, imageUrl: undefined }));
                    setPreviewError(false);
                  }}
                  placeholder="https://images.unsplash.com/..."
                  className={`w-full px-3.5 py-2.5 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border ${
                    errors.imageUrl ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
                  } text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
                />
                {errors.imageUrl && <p className="mt-1 text-xs text-[#DC2626]">{errors.imageUrl}</p>}

                {/* Live Image Preview */}
                {formState.imageUrl && (
                  <div className="mt-2.5 rounded-xl overflow-hidden border border-[#E7E1D7] dark:border-[#2C2723] aspect-16/9 bg-[#EFEAE1] dark:bg-[#201D1A] flex items-center justify-center relative">
                    {!previewError ? (
                      <img
                        src={formState.imageUrl}
                        alt="Project Preview"
                        className="w-full h-full object-cover"
                        onError={() => setPreviewError(true)}
                      />
                    ) : (
                      <span className="text-xs text-[#DC2626] flex items-center gap-1.5">
                        <AlertCircle className="w-4 h-4" /> Unable to load image preview from URL.
                      </span>
                    )}
                  </div>
                )}
              </div>

              {/* Description */}
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                  Description & Materials <span className="text-[#DC2626]">*</span>
                </label>
                <textarea
                  rows={3}
                  value={formState.description}
                  onChange={e => {
                    setFormState(prev => ({ ...prev, description: e.target.value }));
                    setErrors(prev => ({ ...prev, description: undefined }));
                  }}
                  placeholder="Details regarding spatial layout, joinery, lighting, and finishes applied..."
                  className={`w-full px-3.5 py-2.5 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border ${
                    errors.description ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
                  } text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
                />
                {errors.description && <p className="mt-1 text-xs text-[#DC2626]">{errors.description}</p>}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {/* Budget Range Label */}
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                    Budget Label <span className="text-[#DC2626]">*</span>
                  </label>
                  <input
                    type="text"
                    value={formState.budgetRangeLabel}
                    onChange={e => {
                      setFormState(prev => ({ ...prev, budgetRangeLabel: e.target.value }));
                      setErrors(prev => ({ ...prev, budgetRangeLabel: undefined }));
                    }}
                    placeholder="e.g. LKR 150k-250k"
                    className={`w-full px-3 py-2 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border ${
                      errors.budgetRangeLabel ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
                    } text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
                  />
                  {errors.budgetRangeLabel && <p className="mt-1 text-[11px] text-[#DC2626]">{errors.budgetRangeLabel}</p>}
                </div>

                {/* Client Initials */}
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                    Client Initials <span className="text-[#DC2626]">*</span>
                  </label>
                  <input
                    type="text"
                    maxLength={10}
                    value={formState.clientInitials}
                    onChange={e => {
                      setFormState(prev => ({ ...prev, clientInitials: e.target.value.toUpperCase() }));
                      setErrors(prev => ({ ...prev, clientInitials: undefined }));
                    }}
                    placeholder="e.g. A.R."
                    className={`w-full px-3 py-2 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border ${
                      errors.clientInitials ? 'border-[#DC2626]' : 'border-[#E7E1D7] dark:border-[#2C2723]'
                    } text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:ring-2 focus:ring-[#C48A36]`}
                  />
                  {errors.clientInitials && <p className="mt-1 text-[11px] text-[#DC2626]">{errors.clientInitials}</p>}
                </div>

                {/* Status Badge */}
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-1">
                    Status Badge
                  </label>
                  <select
                    value={formState.completionStatusBadge}
                    onChange={e => setFormState(prev => ({ ...prev, completionStatusBadge: parseInt(e.target.value, 10) as ListingStatus }))}
                    className="w-full px-3 py-2 rounded-xl bg-[#F8F5F0] dark:bg-[#24201C] border border-[#E7E1D7] dark:border-[#2C2723] text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5]"
                  >
                    <option value={ListingStatus.Published}>Published</option>
                    <option value={ListingStatus.Draft}>Draft</option>
                    <option value={ListingStatus.Archived}>Archived</option>
                  </select>
                </div>
              </div>

              {/* Form Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t border-[#E7E1D7] dark:border-[#2C2723]">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-5 py-2.5 rounded-full text-xs font-semibold text-[#57534E] dark:text-[#A8A29E] hover:bg-[#EFEAE1] dark:hover:bg-[#2C2723] transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isLoading}
                  className="px-6 py-2.5 rounded-full text-xs font-semibold text-[#FAF8F5] dark:text-[#1C1917] bg-[#1C1917] dark:bg-[#FAF8F5] hover:bg-[#322C27] dark:hover:bg-[#EAE4D9] shadow-md transition-all cursor-pointer disabled:opacity-50"
                >
                  {isLoading ? 'Publishing...' : 'Save & Publish Item'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
