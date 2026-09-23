import React from 'react';
import { ShieldAlert, ShieldCheck, CheckCircle2, Clock, Layers } from 'lucide-react';
import { DesignerProfile, ListingStatus } from '../types';

interface CapacityStatusCardProps {
  profile: DesignerProfile;
}

export const CapacityStatusCard: React.FC<CapacityStatusCardProps> = ({ profile }) => {
  // Sourced directly from backend DTO — do not recompute locally
  const { 
    activeProjectCount, 
    maxConcurrentProjects, 
    remainingCapacity, 
    isAtCapacity, 
    isAvailable, 
    listingStatus 
  } = profile;

  const capacityPercentage = Math.min(100, Math.round((activeProjectCount / Math.max(1, maxConcurrentProjects)) * 100));

  return (
    <div className="rounded-2xl bg-[#F8F5F0] dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2C2723] p-5 sm:p-6 shadow-xs transition-colors duration-300">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#E7E1D7] dark:border-[#2C2723]">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#EFEAE1] dark:bg-[#26211C] flex items-center justify-center text-[#925C18] dark:text-[#E8A849] border border-[#E2D8C9] dark:border-[#382F26]">
            <Layers className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-serif text-lg font-medium text-[#1C1917] dark:text-[#FAF8F5]">
              Project Capacity & Availability
            </h3>
            <p className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              Guarded by contract limits from active project executions
            </p>
          </div>
        </div>

        {/* Status Badges */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Read-only "At Capacity" badge sourced strictly from DTO */}
          {isAtCapacity ? (
            <span 
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#FEE2E2] dark:bg-[#451A1A] text-[#991B1B] dark:text-[#FCA5A5] border border-[#FECACA] dark:border-[#7F1D1D]"
              title="Designer has reached maximum concurrent active contracts."
            >
              <ShieldAlert className="w-3.5 h-3.5 shrink-0" />
              At Capacity
            </span>
          ) : (
            <span 
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-[#DCFCE7] dark:bg-[#143823] text-[#166534] dark:text-[#86EFAC] border border-[#BBF7D0] dark:border-[#1E5638]"
              title="Designer has open slots to accept new client requests."
            >
              <ShieldCheck className="w-3.5 h-3.5 shrink-0" />
              Slots Open ({remainingCapacity} remaining)
            </span>
          )}

          {/* Availability Toggle State */}
          <span 
            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${
              isAvailable 
                ? 'bg-[#FAF3E8] dark:bg-[#2A231C] text-[#925C18] dark:text-[#E8A849] border-[#EADBCA] dark:border-[#3D3328]' 
                : 'bg-[#F5F5F4] dark:bg-[#262626] text-[#78716C] dark:text-[#A8A29E] border-[#E7E5E4] dark:border-[#404040]'
            }`}
          >
            <span className={`w-2 h-2 rounded-full ${isAvailable ? 'bg-[#16A34A]' : 'bg-[#78716C]'}`} />
            {isAvailable ? 'Accepting Projects' : 'Paused by Designer'}
          </span>

          {/* Listing Status Badge */}
          <span 
            className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${
              listingStatus === ListingStatus.Published 
                ? 'bg-[#F0FDF4] dark:bg-[#142C1D] text-[#15803D] dark:text-[#4ADE80] border-[#DCFCE7] dark:border-[#1E4E30]'
                : listingStatus === ListingStatus.Draft
                ? 'bg-[#FEFCE8] dark:bg-[#342F15] text-[#A16207] dark:text-[#FDE047] border-[#FEF08A] dark:border-[#4D451E]'
                : 'bg-[#F5F5F4] dark:bg-[#2A2A2A] text-[#737373] dark:text-[#A3A3A3] border-[#E5E5E5] dark:border-[#404040]'
            }`}
          >
            {ListingStatus[listingStatus]}
          </span>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-4">
        <div className="p-3.5 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
          <span className="text-xs font-medium text-[#78716C] dark:text-[#A8A29E] block">
            Active Contracts
          </span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              {activeProjectCount}
            </span>
            <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              of {maxConcurrentProjects} max
            </span>
          </div>
        </div>

        <div className="p-3.5 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
          <span className="text-xs font-medium text-[#78716C] dark:text-[#A8A29E] block">
            Remaining Project Slots
          </span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="font-serif text-2xl font-bold text-[#925C18] dark:text-[#E8A849]">
              {remainingCapacity}
            </span>
            <span className="text-xs text-[#78716C] dark:text-[#A8A29E]">
              available slots
            </span>
          </div>
        </div>

        <div className="p-3.5 rounded-xl bg-[#FAF8F5] dark:bg-[#201D1A] border border-[#E7E1D7] dark:border-[#2C2723]">
          <span className="text-xs font-medium text-[#78716C] dark:text-[#A8A29E] block">
            Capacity Load
          </span>
          <div className="flex items-center gap-2 mt-2">
            <div className="flex-1 h-2.5 rounded-full bg-[#E7E1D7] dark:bg-[#2C2723] overflow-hidden">
              <div 
                className={`h-full rounded-full transition-all duration-500 ${
                  isAtCapacity 
                    ? 'bg-[#DC2626]' 
                    : capacityPercentage > 60 
                    ? 'bg-[#F59E0B]' 
                    : 'bg-[#16A34A]'
                }`}
                style={{ width: `${capacityPercentage}%` }}
              />
            </div>
            <span className="text-xs font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              {capacityPercentage}%
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
