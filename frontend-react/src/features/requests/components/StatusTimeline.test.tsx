import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { StatusTimeline } from './StatusTimeline';
import { StatusHistoryEntry } from '../types';

describe('StatusTimeline', () => {
  const mockHistory: StatusHistoryEntry[] = [
    { toStatus: 'Draft', changedAt: '2026-10-04T10:00:00Z', note: 'Created draft' },
    { toStatus: 'Submitted', changedAt: '2026-10-04T11:00:00Z', note: 'Submitted by client' }
  ];

  it('renders normal progress and remaining upcoming stages', () => {
    render(<StatusTimeline history={mockHistory} currentStatus="Submitted" />);
    
    // Rendered history
    expect(screen.getByText('Draft')).toBeInTheDocument();
    expect(screen.getByText('Created draft')).toBeInTheDocument();
    expect(screen.getByText('Submitted')).toBeInTheDocument();
    expect(screen.getByText('Submitted by client')).toBeInTheDocument();

    // Upcoming stages
    expect(screen.getByText('AIAnalysis')).toBeInTheDocument();
    expect(screen.getByText('Completed')).toBeInTheDocument();
  });

  it('replaces upcoming stages when Cancelled mid-flow', () => {
    const cancelledHistory: StatusHistoryEntry[] = [
      ...mockHistory,
      { toStatus: 'Cancelled', changedAt: '2026-10-04T12:00:00Z', note: 'Client request' }
    ];

    render(<StatusTimeline history={cancelledHistory} currentStatus="Cancelled" />);
    
    expect(screen.getByText('Cancelled')).toBeInTheDocument();
    expect(screen.queryByText('AIAnalysis')).not.toBeInTheDocument();
  });

  it('replaces upcoming stages when Rejected', () => {
    const rejectedHistory: StatusHistoryEntry[] = [
      ...mockHistory,
      { toStatus: 'Rejected', changedAt: '2026-10-04T12:00:00Z', note: 'Invalid' }
    ];

    render(<StatusTimeline history={rejectedHistory} currentStatus="Rejected" />);
    
    expect(screen.getByText('Rejected')).toBeInTheDocument();
    expect(screen.queryByText('AIAnalysis')).not.toBeInTheDocument();
  });

  it('renders correctly with empty history', () => {
    render(<StatusTimeline history={[]} currentStatus="Draft" />);
    
    // Shouldn't crash, upcoming stages should render
    expect(screen.getByText('Submitted')).toBeInTheDocument();
  });
});
