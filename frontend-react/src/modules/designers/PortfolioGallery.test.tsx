import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import React from 'react';
import { PortfolioProjectCard } from './components/PortfolioProjectCard';
import { PortfolioProjectModal } from './components/PortfolioProjectModal';
import { DesignerPortfolioGalleryPage } from './pages/DesignerPortfolioGalleryPage';
import { PortfolioItem, ListingStatus } from './types';

const mockPortfolioItem: PortfolioItem = {
  id: 10,
  designerProfileId: 1,
  title: 'Bawa-Inspired Courtyard Residence',
  description: 'A 3,200 sq.ft villa in Pelawatte with exposed brick and natural timber columns.',
  imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
  budgetRangeLabel: 'LKR 450k-550k',
  clientInitials: 'K.M.',
  completionStatusBadge: ListingStatus.Published,
  createdAtUtc: '2026-08-16T12:00:00Z'
};

const mockDraftItem: PortfolioItem = {
  ...mockPortfolioItem,
  id: 11,
  title: 'Modern Minimalist Kitchen',
  clientInitials: 'S.D.',
  completionStatusBadge: ListingStatus.Draft
};

describe('PortfolioProjectCard', () => {
  it('renders image, budget range label, client initials only (never full name), and completion status badge', () => {
    const onClick = vi.fn();
    render(<PortfolioProjectCard item={mockPortfolioItem} onClick={onClick} />);

    expect(screen.getByText('Bawa-Inspired Courtyard Residence')).toBeInTheDocument();
    expect(screen.getByText('LKR 450k-550k')).toBeInTheDocument();
    expect(screen.getByText('Client: K.M.')).toBeInTheDocument();
    expect(screen.getByText('Published Project')).toBeInTheDocument();

    fireEvent.click(screen.getByText('Bawa-Inspired Courtyard Residence'));
    expect(onClick).toHaveBeenCalledWith(mockPortfolioItem);
  });

  it('renders in-progress / draft completion badge appropriately', () => {
    const onClick = vi.fn();
    render(<PortfolioProjectCard item={mockDraftItem} onClick={onClick} />);

    expect(screen.getByText('In Progress / Draft')).toBeInTheDocument();
    expect(screen.getByText('Client: S.D.')).toBeInTheDocument();
  });
});

describe('PortfolioProjectModal', () => {
  it('displays full project details, description, image, and status on click', () => {
    const onClose = vi.fn();
    render(
      <PortfolioProjectModal
        item={mockPortfolioItem}
        designerDisplayName="Jayawardena Architecture"
        onClose={onClose}
      />
    );

    expect(screen.getByText('Bawa-Inspired Courtyard Residence')).toBeInTheDocument();
    expect(screen.getByText(/A 3,200 sq.ft villa in Pelawatte/i)).toBeInTheDocument();
    expect(screen.getByText('Budget Tier: LKR 450k-550k')).toBeInTheDocument();
    expect(screen.getByText('Client: K.M.')).toBeInTheDocument();

    fireEvent.click(screen.getByText('Close Project'));
    expect(onClose).toHaveBeenCalled();
  });
});

describe('DesignerPortfolioGalleryPage', () => {
  it('loads and renders the dedicated proof of work gallery for a designer', async () => {
    const onBack = vi.fn();
    render(<DesignerPortfolioGalleryPage designerId={1} onBack={onBack} />);

    await waitFor(() => {
      expect(screen.getByText(/Dedicated Proof of Work Gallery/i)).toBeInTheDocument();
      expect(screen.getByText(/Jayawardena Architecture & Interiors — Portfolio Gallery/i)).toBeInTheDocument();
      expect(screen.getByText('Bawa-Inspired Courtyard Residence')).toBeInTheDocument();
    });
  });
});
