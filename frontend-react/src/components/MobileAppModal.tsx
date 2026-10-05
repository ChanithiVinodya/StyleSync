import React, { useState } from 'react';
import { X, Smartphone, CheckCircle2, Apple, Play } from 'lucide-react';

interface MobileAppModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const MobileAppModal: React.FC<MobileAppModalProps> = ({ isOpen, onClose }) => {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [smsSent, setSmsSent] = useState(false);

  if (!isOpen) return null;

  const handleSendSms = (e: React.FormEvent) => {
    e.preventDefault();
    if (phoneNumber.trim()) {
      setSmsSent(true);
      setTimeout(() => setSmsSent(false), 5000);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C1917]/70 backdrop-blur-xs">
      <div 
        className="relative w-full max-w-lg bg-[#FAF8F5] border border-[#E7E1D7] rounded-3xl p-6 sm:p-8 shadow-2xl overflow-hidden"
        role="dialog"
        aria-modal="true"
        aria-labelledby="mobile-modal-title"
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
          <div className="space-y-2 pr-8">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FAF3E8] border border-[#EADBCA] text-[11px] font-semibold text-[#925C18]">
              <Smartphone className="w-3.5 h-3.5" />
              <span>For Homeowners & Clients</span>
            </div>
            <h3 id="mobile-modal-title" className="font-serif text-2xl sm:text-3xl text-[#1C1917]">
              Get the StyleSync Mobile App
            </h3>
            <p className="text-xs sm:text-sm text-[#57534E] leading-relaxed">
              Clients capture room dimensions with their phone camera, receive deterministic designer matches, inspect calculated quotes, and track makeover milestones.
            </p>
          </div>

          {/* QR Code and App Badges */}
          <div className="grid grid-cols-1 sm:grid-cols-12 gap-6 items-center p-5 bg-[#FFFFFF] border border-[#E7E1D7] rounded-2xl">
            {/* Simulated QR Code */}
            <div className="sm:col-span-5 flex flex-col items-center justify-center p-3 bg-[#FAF8F5] border border-[#E7E1D7] rounded-xl">
              {/* QR Pattern visual */}
              <div className="w-28 h-28 bg-[#FFFFFF] p-2 border border-[#E7E1D7] rounded-lg flex flex-col items-center justify-center relative shadow-xs">
                <div className="grid grid-cols-5 gap-1 w-full h-full p-1 opacity-90">
                  <div className="bg-[#1C1917] rounded-xs col-span-2 row-span-2" />
                  <div className="bg-[#C48A36] rounded-xs" />
                  <div className="bg-[#1C1917] rounded-xs col-span-2 row-span-2" />
                  <div className="bg-[#1C1917] rounded-xs" />
                  <div className="bg-[#1C1917] rounded-xs" />
                  <div className="bg-[#C48A36] rounded-xs col-span-3" />
                  <div className="bg-[#1C1917] rounded-xs col-span-2 row-span-2" />
                  <div className="bg-[#1C1917] rounded-xs" />
                  <div className="bg-[#C48A36] rounded-xs col-span-2 row-span-2" />
                </div>
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-7 h-7 bg-[#1C1917] text-[#FAF8F5] rounded-full flex items-center justify-center font-serif text-[11px] font-bold shadow-xs">
                    S
                  </div>
                </div>
              </div>
              <span className="text-[10px] text-[#78716C] mt-2 font-medium">
                Scan with smartphone camera
              </span>
            </div>

            {/* App Store Buttons */}
            <div className="sm:col-span-7 space-y-3">
              <p className="text-xs font-semibold text-[#1C1917]">
                Direct Download Links:
              </p>

              {/* iOS App Store */}
              <a
                href="#app-store-placeholder"
                onClick={(e) => {
                  e.preventDefault();
                  alert("StyleSync Mobile for iOS (Flutter App) build ready for App Store test distribution.");
                }}
                className="flex items-center gap-3 px-4 py-2.5 bg-[#1C1917] hover:bg-[#322C27] text-[#FAF8F5] rounded-xl transition-all shadow-xs group"
              >
                <Apple className="w-5 h-5 text-white shrink-0" />
                <div className="text-left">
                  <span className="block text-[9px] uppercase tracking-wider text-[#A8A29E] leading-none">
                    Download on the
                  </span>
                  <span className="text-xs font-semibold leading-tight">
                    Apple App Store
                  </span>
                </div>
              </a>

              {/* Google Play */}
              <a
                href="#google-play-placeholder"
                onClick={(e) => {
                  e.preventDefault();
                  alert("StyleSync Mobile for Android (Flutter App) APK ready for Google Play distribution.");
                }}
                className="flex items-center gap-3 px-4 py-2.5 bg-[#FFFFFF] hover:bg-[#F4F0E8] text-[#1C1917] border border-[#E7E1D7] rounded-xl transition-all shadow-xs group"
              >
                <Play className="w-4 h-4 text-[#C48A36] fill-[#C48A36] shrink-0" />
                <div className="text-left">
                  <span className="block text-[9px] uppercase tracking-wider text-[#78716C] leading-none">
                    Get it on
                  </span>
                  <span className="text-xs font-semibold leading-tight">
                    Google Play
                  </span>
                </div>
              </a>
            </div>
          </div>

          {/* SMS Send Option */}
          <div className="space-y-2">
            <label className="block text-xs font-medium text-[#44403C]">
              Or send an install link directly to your phone:
            </label>
            <form onSubmit={handleSendSms} className="flex gap-2">
              <input
                type="tel"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                placeholder="+1 (555) 000-0000"
                className="flex-1 px-4 py-2 text-xs bg-[#FFFFFF] border border-[#E7E1D7] rounded-xl focus:outline-hidden focus:border-[#1C1917] text-[#1C1917]"
              />
              <button
                type="submit"
                className="px-4 py-2 text-xs font-semibold bg-[#1C1917] text-[#FAF8F5] rounded-xl hover:bg-[#322C27] transition-colors"
              >
                Send Link
              </button>
            </form>
            {smsSent && (
              <p className="text-[11px] text-emerald-700 flex items-center gap-1">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Link sent! Check your text messages to install StyleSync Mobile.</span>
              </p>
            )}
          </div>

          {/* Role Demarcation Clarification */}
          <div className="p-3 bg-[#FAF3E8] border border-[#EADBCA] rounded-xl text-[11px] text-[#925C18] flex items-start gap-2">
            <div className="w-4 h-4 rounded-full bg-[#EADBCA] text-[#925C18] flex items-center justify-center shrink-0 mt-0.5 text-[10px] font-bold">
              i
            </div>
            <span>
              <strong>Note:</strong> Designers, Project Coordinators, and Admins operate on the web desktop suite. The mobile app is reserved for client room submissions and milestone approvals.
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
