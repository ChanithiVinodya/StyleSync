import React, { useState } from 'react';
import { X, Sparkles, Smartphone, ArrowRight } from 'lucide-react';
import { PersonaRole } from '../types';

interface GetStartedModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenMobileModal: () => void;
  onOpenPortalModal: (role: PersonaRole) => void;
}

export const GetStartedModal: React.FC<GetStartedModalProps> = ({
  isOpen,
  onClose,
  onOpenMobileModal,
  onOpenPortalModal,
}) => {
  const [step, setStep] = useState<number>(1);
  const [roomType, setRoomType] = useState('Living Room');
  const [designStyle, setDesignStyle] = useState('Japandi');
  const [budgetTier, setBudgetTier] = useState('$15,000 - $25,000');

  if (!isOpen) return null;

  const handleFinish = () => {
    onClose();
    onOpenMobileModal();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C1917]/70 backdrop-blur-xs">
      <div 
        className="relative w-full max-w-lg bg-[#FAF8F5] border border-[#E7E1D7] rounded-3xl p-6 sm:p-8 shadow-2xl overflow-hidden"
        role="dialog"
        aria-modal="true"
        aria-labelledby="get-started-title"
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 text-[#78716C] hover:text-[#1C1917] hover:bg-[#EFEAE1] rounded-full transition-colors focus:outline-hidden"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="space-y-6">
          {/* Header */}
          <div className="space-y-1.5 pr-8">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#C48A36] flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Deterministic Match Preview</span>
            </span>
            <h3 id="get-started-title" className="font-serif text-2xl sm:text-3xl text-[#1C1917]">
              Start Your Room Transformation
            </h3>
            <p className="text-xs sm:text-sm text-[#57534E]">
              Preview how StyleSync calculates your designer match score and itemized price ceiling.
            </p>
          </div>

          {step === 1 && (
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="text-xs font-semibold text-[#1C1917] block">
                  1. Which space are you transforming?
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {['Living Room', 'Primary Suite', 'Kitchen & Dining', 'Open-Concept Loft'].map((type) => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setRoomType(type)}
                      className={`p-3 rounded-xl border text-xs font-medium text-left transition-all ${
                        roomType === type
                          ? 'bg-[#1C1917] text-[#FAF8F5] border-[#1C1917] shadow-xs'
                          : 'bg-white text-[#44403C] hover:bg-[#F4F0E8] border-[#E7E1D7]'
                      }`}
                    >
                      {type}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <label className="text-xs font-semibold text-[#1C1917] block">
                  2. Preferred aesthetic direction:
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {['Japandi', 'Warm Minimalist', 'Mid-Century Modern', 'Organic Mediterranean'].map((style) => (
                    <button
                      key={style}
                      type="button"
                      onClick={() => setDesignStyle(style)}
                      className={`p-3 rounded-xl border text-xs font-medium text-left transition-all ${
                        designStyle === style
                          ? 'bg-[#1C1917] text-[#FAF8F5] border-[#1C1917] shadow-xs'
                          : 'bg-white text-[#44403C] hover:bg-[#F4F0E8] border-[#E7E1D7]'
                      }`}
                    >
                      {style}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <label className="text-xs font-semibold text-[#1C1917] block">
                  3. Anticipated budget range:
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {['$8k - $15k', '$15k - $25k', '$25k+'].map((budget) => (
                    <button
                      key={budget}
                      type="button"
                      onClick={() => setBudgetTier(budget)}
                      className={`p-2.5 rounded-xl border text-xs font-medium text-center transition-all ${
                        budgetTier === budget
                          ? 'bg-[#1C1917] text-[#FAF8F5] border-[#1C1917] shadow-xs'
                          : 'bg-white text-[#44403C] hover:bg-[#F4F0E8] border-[#E7E1D7]'
                      }`}
                    >
                      {budget}
                    </button>
                  ))}
                </div>
              </div>

              <button
                type="button"
                onClick={() => setStep(2)}
                className="w-full mt-4 py-3 bg-[#1C1917] hover:bg-[#322C27] text-[#FAF8F5] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs"
              >
                <span>Calculate Match & Preview Estimate</span>
                <ArrowRight className="w-4 h-4 text-[#C48A36]" />
              </button>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-5">
              <div className="p-5 bg-white border border-[#E7E1D7] rounded-2xl space-y-4">
                <div className="flex items-center justify-between pb-3 border-b border-[#E7E1D7]">
                  <div>
                    <span className="text-[10px] uppercase tracking-wider text-[#78716C] font-semibold">
                      Match Result
                    </span>
                    <h4 className="font-serif text-lg text-[#1C1917]">
                      {roomType} • {designStyle}
                    </h4>
                  </div>
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#FAF3E8] text-[#925C18] border border-[#EADBCA]">
                    98.2% Match
                  </span>
                </div>

                <div className="space-y-2 text-xs">
                  <div className="flex justify-between text-[#57534E]">
                    <span>Target Range:</span>
                    <span className="font-semibold text-[#1C1917]">{budgetTier}</span>
                  </div>
                  <div className="flex justify-between text-[#57534E]">
                    <span>Eligible Verified Studios:</span>
                    <span className="font-semibold text-[#1C1917]">3 Studios with open capacity</span>
                  </div>
                  <div className="flex justify-between text-[#57534E]">
                    <span>Lead Studio Recommendation:</span>
                    <span className="font-semibold text-[#C48A36]">Studio Kanso / Atelier Vane</span>
                  </div>
                  <div className="flex justify-between text-[#57534E]">
                    <span>Contract Model:</span>
                    <span className="font-semibold text-emerald-700">Locked Price Ceiling Guarantee</span>
                  </div>
                </div>
              </div>

              <div className="p-4 bg-[#FAF3E8] border border-[#EADBCA] rounded-2xl space-y-2">
                <div className="flex items-center gap-2 text-xs font-semibold text-[#925C18]">
                  <Smartphone className="w-4 h-4 text-[#925C18]" />
                  <span>Next Step: Complete in StyleSync Mobile</span>
                </div>
                <p className="text-xs text-[#57534E] leading-relaxed">
                  To capture actual room photos, receive your formal calculated contract, and track milestones, open the mobile app.
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="px-4 py-3 bg-white border border-[#E7E1D7] text-[#1C1917] rounded-xl text-xs font-semibold hover:bg-[#F4F0E8] transition-colors"
                >
                  Adjust Filters
                </button>

                <button
                  type="button"
                  onClick={handleFinish}
                  className="flex-1 py-3 bg-[#1C1917] hover:bg-[#322C27] text-[#FAF8F5] rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-colors shadow-xs"
                >
                  <Smartphone className="w-4 h-4 text-[#C48A36]" />
                  <span>Get Mobile App to Submit Room</span>
                </button>
              </div>
            </div>
          )}

          {/* Designer link */}
          <div className="pt-3 border-t border-[#E7E1D7] text-center">
            <button
              onClick={() => {
                onClose();
                onOpenPortalModal('designer');
              }}
              className="text-xs text-[#78716C] hover:text-[#1C1917] underline decoration-[#C48A36]"
            >
              Are you an interior designer instead? Join the verified network →
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
