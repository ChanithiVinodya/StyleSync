import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import React from 'react';
import { DesignerDirectoryPage } from './pages/DesignerDirectoryPage';
import { DesignerListingCard } from './components/DesignerListingCard';
import { DesignerListingItem, ListingStatus } from './types';

const mockDesigner: DesignerListingItem = {
  id: 1,
  displayName: "Jayawardena Architecture & Interiors",
  bio: "Award-winning interior studio specializing in tropical modernism.",
  styleTags: ["Tropical Modernism", "Minimalist"],
  serviceCategories: ["Full Home Interior"],
  priceRangeMin: 150000,
  priceRangeMax: 600000,
  ratePerSqFt: 450,
  isAvailable: true,
  maxConcurrentProjects: 3,
  activeProjectCount: 1,
  remainingCapacity: 2,
  isUnderCapacity: true,
  isAtCapacity: false,
  averageRating: 4.85,
  listingStatus: ListingStatus.Published,
  publishedPortfolioCount: 2,
  featuredImageUrl: "https://example.com/test.jpg",
  createdAtUtc: "2026-08-15T10:00:00Z"
};

const mockAtCapacityDesigner: DesignerListingItem = {
  ...mockDesigner,
  id: 2,
  displayName: "Studio Amara Design",
  activeProjectCount: 2,
  maxConcurrentProjects: 2,
  remainingCapacity: 0,
  isUnderCapacity: false,
  isAtCapacity: true
};

describe('DesignerListingCard', () => {
  it('renders designer details, rating, and accepting projects badge', () => {
    const onSelect = vi.fn();
    render(<DesignerListingCard designer={mockDesigner} onSelect={onSelect} />);

    expect(screen.getByText('Jayawardena Architecture & Interiors')).toBeInTheDocument();
    expect(screen.getByText('4.85')).toBeInTheDocument();
    expect(screen.getByText('Accepting Projects')).toBeInTheDocument();
    expect(screen.getByText('Tropical Modernism')).toBeInTheDocument();
    expect(screen.getByText('LKR 450')).toBeInTheDocument();

    fireEvent.click(screen.getByText('Jayawardena Architecture & Interiors'));
    expect(onSelect).toHaveBeenCalledWith(1);
  });

  it('renders read-only "At Capacity" badge when isAtCapacity is true', () => {
    const onSelect = vi.fn();
    render(<DesignerListingCard designer={mockAtCapacityDesigner} onSelect={onSelect} />);

    expect(screen.getByText('Studio Amara Design')).toBeInTheDocument();
    expect(screen.getByText('At Capacity')).toBeInTheDocument();
  });
});

describe('DesignerDirectoryPage', () => {
  it('renders directory with filters and loads published listings', async () => {
    const onSelectDesigner = vi.fn();
    render(<DesignerDirectoryPage onSelectDesigner={onSelectDesigner} />);

    expect(screen.getByText('Discover Certified Interior Designers')).toBeInTheDocument();
    expect(screen.getByText('Filters:')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Jayawardena Architecture & Interiors')).toBeInTheDocument();
    });
  });
});
