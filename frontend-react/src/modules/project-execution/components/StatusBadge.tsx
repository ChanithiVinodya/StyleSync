import React from 'react';

type Status = 'NotStarted' | 'InProgress' | 'Delayed' | 'Completed' | 'Required' | 'Ordered' | 'Delivered' | 'Blocked';

export const StatusBadge: React.FC<{ status: Status | string }> = ({ status }) => {
  let colorClass = 'bg-gray-100 text-gray-800'; // Default Neutral
  let label = status;

  switch (status) {
    case 'Completed':
    case 'Delivered':
      colorClass = 'bg-green-100 text-green-800';
      break;
    case 'InProgress':
    case 'Ordered':
      colorClass = 'bg-blue-100 text-blue-800';
      label = status === 'InProgress' ? 'In Progress' : 'Ordered';
      break;
    case 'Delayed':
    case 'Blocked':
      colorClass = 'bg-red-100 text-red-800';
      break;
    case 'NotStarted':
    case 'Required':
      colorClass = 'bg-gray-100 text-gray-800';
      label = status === 'NotStarted' ? 'Not Started' : 'Required';
      break;
  }

  return (
    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colorClass}`}>
      {label}
    </span>
  );
};
