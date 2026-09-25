import { useState } from 'react';
import { createProjectRequest } from '../services/api';
import type { ProjectRequest } from '../services/api';
import { Sparkles, Image, ArrowRight, Save, Send, Check } from 'lucide-react';

// ─── Types ────────────────────────────────────────────────────────────────

interface WizardFormData {
  roomType: string;
  lengthFeet: number | string;
  widthFeet: number | string;
  heightFeet: number | string;
  budgetLkr: number | string;
  preferredStyles: string[];
  description: string;
  photoUrls: string[];
}

interface CreateRequestWizardProps {
  onRequestCreated: (req: ProjectRequest) => void;
}

// ─── Constants ────────────────────────────────────────────────────────────

const SUPPORTED_STYLES: string[] = [
  'Modern',
  'Minimalist',
  'Industrial',
  'Luxury',
  'Traditional',
  'Mid Century Modern',
];

// ─── Component ────────────────────────────────────────────────────────────

export default function CreateRequestWizard({ onRequestCreated }: CreateRequestWizardProps) {
  const [step, setStep] = useState<number>(1);
  const [loading, setLoading] = useState<boolean>(false);

  const [formData, setFormData] = useState<WizardFormData>({
    roomType: 'Bedroom',
    lengthFeet: 15,
    widthFeet: 12,
    heightFeet: 10,
    budgetLkr: 250000,
    preferredStyles: ['Industrial'],
    description: 'Exposed brick wall with raw timber beams and steel frames.',
    photoUrls: [
      'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=800&auto=format&fit=crop',
    ],
  });

  const [newPhotoUrl, setNewPhotoUrl] = useState<string>('');

  const addPhotoUrl = (): void => {
    if (newPhotoUrl.trim()) {
      setFormData((prev) => ({
        ...prev,
        photoUrls: [...prev.photoUrls, newPhotoUrl.trim()],
      }));
      setNewPhotoUrl('');
    }
  };

  const removePhotoUrl = (index: number): void => {
    setFormData((prev) => ({
      ...prev,
      photoUrls: prev.photoUrls.filter((_, i) => i !== index),
    }));
  };

  const toggleStyle = (style: string): void => {
    setFormData((prev) => {
      const exists = prev.preferredStyles.includes(style);
      const updated = exists
        ? prev.preferredStyles.filter((s) => s !== style)
        : [...prev.preferredStyles, style];
      return { ...prev, preferredStyles: updated };
    });
  };

  const handleCreate = async (submitImmediately: boolean): Promise<void> => {
    setLoading(true);
    try {
      const newReq = await createProjectRequest({
        roomType: formData.roomType,
        lengthFeet: Number(formData.lengthFeet),
        widthFeet: Number(formData.widthFeet),
        heightFeet: Number(formData.heightFeet),
        budgetLkr: Number(formData.budgetLkr),
        preferredStyles: formData.preferredStyles,
        description: formData.description,
        photoUrls: formData.photoUrls,
        submitImmediately,
      });
      onRequestCreated(newReq);
    } catch (err) {
      alert('Error creating request: ' + (err instanceof Error ? err.message : String(err)));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl p-6 sm:p-10 shadow-xl max-w-3xl mx-auto transition-colors">
      {/* Header */}
      <div className="flex items-center gap-3.5 mb-8">
        <div className="w-11 h-11 rounded-2xl bg-[#FAF3E8] dark:bg-[#2A231A] border border-[#E8DEC8] dark:border-[#423525] flex items-center justify-center text-[#C48A36]">
          <Sparkles className="w-6 h-6" />
        </div>
        <div>
          <h2 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
            New Room Makeover Request
          </h2>
          <p className="text-xs text-[#78716C] dark:text-[#A8A29E] mt-0.5">
            Submit room specs &amp; photos to kick off Style Analysis AI Agent
          </p>
        </div>
      </div>

      {/* Progress Steps Header */}
      <div className="flex items-center justify-between mb-8 pb-4 border-b border-[#E7E1D7] dark:border-[#2E2824]">
        {([1, 2, 3] as const).map((num) => {
          const isActive = step >= num;
          const isCurrent = step === num;
          return (
            <div
              key={num}
              className={`flex items-center gap-2.5 text-xs font-semibold transition-colors ${
                isActive
                  ? 'text-[#C48A36]'
                  : 'text-[#A8A29E] dark:text-[#78716C]'
              }`}
            >
              <span
                className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all ${
                  isCurrent
                    ? 'bg-[#C48A36] text-white shadow-xs scale-105'
                    : isActive
                    ? 'bg-[#FAF3E8] dark:bg-[#2A231A] text-[#C48A36] border border-[#E8DEC8] dark:border-[#423525]'
                    : 'bg-[#FAF8F5] dark:bg-[#25201C] text-[#78716C] border border-[#E7E1D7] dark:border-[#2E2824]'
                }`}
              >
                {step > num ? <Check className="w-3.5 h-3.5" /> : num}
              </span>
              <span className="hidden sm:inline">
                {num === 1 ? 'Room Specs' : num === 2 ? 'Budget & Style' : 'Photos & Action'}
              </span>
            </div>
          );
        })}
      </div>

      <div>
        {/* Step 1: Room Specs */}
        {step === 1 && (
          <div className="space-y-6">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                Room Type
              </label>
              <select
                className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm font-medium text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                value={formData.roomType}
                onChange={(e) => setFormData({ ...formData, roomType: e.target.value })}
              >
                <option value="Bedroom">Bedroom</option>
                <option value="LivingRoom">Living Room</option>
                <option value="Kitchen">Kitchen</option>
                <option value="DiningRoom">Dining Room</option>
                <option value="Office">Home Office</option>
                <option value="Bathroom">Bathroom</option>
              </select>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                  Length (ft)
                </label>
                <input
                  type="number"
                  className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                  value={formData.lengthFeet}
                  onChange={(e) => setFormData({ ...formData, lengthFeet: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                  Width (ft)
                </label>
                <input
                  type="number"
                  className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                  value={formData.widthFeet}
                  onChange={(e) => setFormData({ ...formData, widthFeet: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                  Height (ft)
                </label>
                <input
                  type="number"
                  className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                  value={formData.heightFeet}
                  onChange={(e) => setFormData({ ...formData, heightFeet: e.target.value })}
                />
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                className="inline-flex items-center gap-2 px-6 py-3 text-xs font-semibold text-white bg-[#C48A36] hover:bg-[#A87226] rounded-xl transition shadow-xs"
                onClick={() => setStep(2)}
              >
                <span>Next: Budget &amp; Style</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Budget & Style */}
        {step === 2 && (
          <div className="space-y-6">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                Maximum Budget (LKR)
              </label>
              <input
                type="number"
                className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                value={formData.budgetLkr}
                onChange={(e) => setFormData({ ...formData, budgetLkr: e.target.value })}
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                Preferred Style Aesthetics (Select one or more)
              </label>
              <div className="flex flex-wrap gap-2.5 pt-1">
                {SUPPORTED_STYLES.map((style) => {
                  const isSelected = formData.preferredStyles.includes(style);
                  return (
                    <button
                      key={style}
                      type="button"
                      onClick={() => toggleStyle(style)}
                      className={`px-4 py-2 rounded-full text-xs font-semibold border transition-all ${
                        isSelected
                          ? 'bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border-[#C48A36] shadow-xs'
                          : 'bg-[#FAF8F5] dark:bg-[#12100E] text-[#57534E] dark:text-[#A8A29E] border-[#E7E1D7] dark:border-[#2E2824] hover:border-[#C48A36]/60'
                      }`}
                    >
                      {isSelected ? '✓ ' : '+ '} {style}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="flex justify-between items-center pt-4">
              <button
                type="button"
                className="px-5 py-2.5 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition"
                onClick={() => setStep(1)}
              >
                Back
              </button>
              <button
                type="button"
                className="inline-flex items-center gap-2 px-6 py-3 text-xs font-semibold text-white bg-[#C48A36] hover:bg-[#A87226] rounded-xl transition shadow-xs"
                onClick={() => setStep(3)}
              >
                <span>Next: Photos &amp; Action</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Photos & Action */}
        {step === 3 && (
          <div className="space-y-6">
            <div className="border border-dashed border-[#C48A36]/50 bg-[#FAF3E8]/40 dark:bg-[#2A231A]/30 p-5 rounded-2xl space-y-4">
              <div className="flex items-center gap-2 text-xs font-semibold text-[#925C18] dark:text-[#E8A849]">
                <Image className="w-4 h-4 text-[#C48A36]" />
                <span>Room Photos ({formData.photoUrls.length} attached)</span>
              </div>

              {formData.photoUrls.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {formData.photoUrls.map((url, idx) => (
                    <div
                      key={`${url}-${idx}`}
                      className="inline-flex items-center gap-2 px-3 py-1 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-lg text-xs text-[#57534E] dark:text-[#A8A29E]"
                    >
                      <span>Photo #{idx + 1}</span>
                      <button
                        type="button"
                        onClick={() => removePhotoUrl(idx)}
                        className="text-rose-500 hover:text-rose-700 font-bold ml-1"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="flex gap-2">
                <input
                  type="text"
                  className="flex-1 px-4 py-2.5 bg-white dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-xs text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36]"
                  placeholder="Paste photo image URL..."
                  value={newPhotoUrl}
                  onChange={(e) => setNewPhotoUrl(e.target.value)}
                />
                <button
                  type="button"
                  onClick={addPhotoUrl}
                  className="px-4 py-2.5 bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition"
                >
                  + Add Photo
                </button>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#78716C] dark:text-[#A8A29E] mb-2">
                Design Preferences &amp; Notes
              </label>
              <textarea
                className="w-full px-4 py-3 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl text-sm text-[#1C1917] dark:text-[#FAF8F5] focus:outline-hidden focus:border-[#C48A36] transition-colors"
                rows={3}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="flex justify-between items-center pt-4">
              <button
                type="button"
                className="px-5 py-2.5 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition"
                onClick={() => setStep(2)}
              >
                Back
              </button>

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  disabled={loading}
                  onClick={() => handleCreate(false)}
                  className="inline-flex items-center gap-2 px-4 py-2.5 bg-white dark:bg-[#1A1715] border border-[#C48A36]/60 text-xs font-semibold text-[#925C18] dark:text-[#E8A849] rounded-xl hover:bg-[#FAF3E8] dark:hover:bg-[#2A231A] transition"
                >
                  <Save className="w-4 h-4" />
                  <span>Save as Draft</span>
                </button>

                <button
                  type="button"
                  disabled={loading}
                  onClick={() => handleCreate(true)}
                  className="inline-flex items-center gap-2 px-6 py-2.5 text-xs font-semibold text-white bg-[#C48A36] hover:bg-[#A87226] rounded-xl transition shadow-xs"
                >
                  <Send className="w-4 h-4" />
                  <span>{loading ? 'Analyzing Style...' : 'Submit & Analyze Style'}</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
