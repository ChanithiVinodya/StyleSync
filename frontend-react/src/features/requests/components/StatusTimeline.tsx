import React from 'react';
import { RequestStatus, StatusHistoryEntry } from '../types';
import { CheckCircle2, Circle, XCircle, Clock } from 'lucide-react';

const EXPECTED_STAGES: RequestStatus[] = [
  'Submitted',
  'AIAnalysis',
  'ProposalReady',
  'AwaitingApproval',
  'Approved',
  'DesignerAssigned',
  'InProgress',
  'Completed'
];

interface StatusTimelineProps {
  history: StatusHistoryEntry[];
  currentStatus: RequestStatus;
}

export const StatusTimeline: React.FC<StatusTimelineProps> = ({ history, currentStatus }) => {
  // Sort history chronologically (usually it comes sorted, but just in case)
  const sortedHistory = [...history].sort((a, b) => new Date(a.changedAt).getTime() - new Date(b.changedAt).getTime());

  // Determine terminal state
  const isCancelled = currentStatus === 'Cancelled';
  const isRejected = currentStatus === 'Rejected';
  const isTerminal = isCancelled || isRejected;

  // Find which expected stages have already been completed/reached
  const reachedStatuses = new Set(sortedHistory.map(h => h.toStatus));

  // Determine upcoming stages
  let upcomingStages: RequestStatus[] = [];
  if (isTerminal) {
    upcomingStages = [currentStatus];
  } else {
    // Upcoming are stages in EXPECTED_STAGES that are after the current index, or simply not reached
    // We'll find the index of the current status in EXPECTED_STAGES
    const currentIndex = EXPECTED_STAGES.indexOf(currentStatus);
    if (currentIndex !== -1) {
      upcomingStages = EXPECTED_STAGES.slice(currentIndex + 1);
    } else if (currentStatus === 'Draft') {
      upcomingStages = EXPECTED_STAGES;
    }
  }

  const formatDate = (val: string) => {
    return new Date(val).toLocaleString('en-US', { 
      month: 'short', day: 'numeric', year: 'numeric', 
      hour: 'numeric', minute: '2-digit', hour12: true 
    });
  };

  return (
    <div className="relative pl-6 space-y-6 before:absolute before:inset-0 before:ml-[11px] before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-[#E7E1D7] dark:before:via-[#2E2824] before:to-transparent">
      
      {/* Completed/History Stages */}
      {sortedHistory.map((entry, idx) => {
        const isCurrent = entry.toStatus === currentStatus;
        return (
          <div key={`${entry.toStatus}-${idx}`} className="relative flex items-start gap-4 group">
            <div className={`absolute -left-6 bg-white dark:bg-[#1A1715] p-1 rounded-full ${isCurrent ? 'text-amber-500' : 'text-emerald-500'}`}>
              {isCurrent ? <Clock size={20} className="animate-pulse" /> : <CheckCircle2 size={20} />}
            </div>
            <div className={`flex flex-col ${isCurrent ? 'opacity-100' : 'opacity-80'}`}>
              <h4 className={`text-sm font-bold ${isCurrent ? 'text-[#1C1917] dark:text-[#FAF8F5]' : 'text-[#57534E] dark:text-[#A8A29E]'}`}>
                {entry.toStatus}
              </h4>
              <time className="text-[11px] font-medium text-[#78716C] dark:text-[#78716C]">
                {formatDate(entry.changedAt)}
              </time>
              {entry.note && (
                <p className="mt-1 text-xs text-[#57534E] dark:text-[#A8A29E] bg-[#FAF8F5] dark:bg-[#12100E] p-2 rounded-lg border border-[#E7E1D7] dark:border-[#2E2824]">
                  {entry.note}
                </p>
              )}
            </div>
          </div>
        );
      })}

      {/* Upcoming Stages */}
      {upcomingStages.map((stage, idx) => {
        const isTerminalStage = isTerminal && stage === currentStatus;
        // If it's a terminal stage that hasn't been added to history somehow? 
        // Wait, terminal stage IS the current status, so it's in history! 
        // If it's in history, it shouldn't be in upcoming.
        // Wait, if it's rejected/cancelled, the history already contains it. So `upcomingStages` should be empty if history already contains the terminal state.
        // Let's filter out anything already in history to be safe.
        if (reachedStatuses.has(stage)) return null;

        return (
          <div key={`upcoming-${stage}-${idx}`} className="relative flex items-start gap-4 opacity-40 grayscale">
            <div className="absolute -left-6 bg-white dark:bg-[#1A1715] p-1 rounded-full text-gray-400">
              {isTerminalStage ? <XCircle size={20} /> : <Circle size={20} />}
            </div>
            <div className="flex flex-col pt-1">
              <h4 className="text-sm font-bold text-[#57534E] dark:text-[#A8A29E]">
                {stage}
              </h4>
              <span className="text-[11px] font-medium text-[#78716C]">Upcoming</span>
            </div>
          </div>
        );
      })}
    </div>
  );
};
