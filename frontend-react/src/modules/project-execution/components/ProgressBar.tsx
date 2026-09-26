import React from 'react';

export const ProgressBar: React.FC<{ percentage: number; colorClass?: string }> = ({ percentage, colorClass = 'bg-blue-600' }) => {
  const safePercentage = Math.min(Math.max(percentage, 0), 100);
  
  return (
    <div className="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
      <div className={`${colorClass} h-2.5 rounded-full`} style={{ width: `${safePercentage}%` }}></div>
    </div>
  );
};
