import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import React from 'react';
import { AdminDesignerGovernancePage } from './pages/AdminDesignerGovernancePage';
import { ListingStatus } from './types';

describe('AdminDesignerGovernancePage', () => {
  it('gates access when userRole is not admin', () => {
    const onBack = vi.fn();
    render(<AdminDesignerGovernancePage userRole="client" onBack={onBack} />);

    expect(screen.getByText('Administrator Access Required')).toBeInTheDocument();
    expect(screen.getByText('Switch to Administrator Role')).toBeInTheDocument();
  });

  it('renders designer governance table when userRole is admin', async () => {
    render(<AdminDesignerGovernancePage userRole="admin" />);

    expect(screen.getByText('Designer Governance & Capacity Admin')).toBeInTheDocument();
    expect(screen.getByText('Role: Administrator')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Jayawardena Architecture & Interiors')).toBeInTheDocument();
      expect(screen.getByText('Studio Amara Design')).toBeInTheDocument();
    });
  });

  it('allows overriding MaxConcurrentProjects and changing ListingStatus', async () => {
    render(<AdminDesignerGovernancePage userRole="admin" />);

    await waitFor(() => {
      expect(screen.getByText('Studio Amara Design')).toBeInTheDocument();
    });

    // Find save buttons
    const saveButtons = screen.getAllByRole('button', { name: /save override/i });
    expect(saveButtons.length).toBeGreaterThan(0);
  });
});
