import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdminRequestDetail } from './AdminRequestDetail';
import { requestApi, ApiError } from '../../features/requests/api';
import { ThemeProvider } from '../../context/ThemeContext';
import { RequestDetail, PalettePreset } from '../../features/requests/types';

vi.mock('../../features/requests/api', () => ({
  requestApi: {
    getRequest: vi.fn(),
    listPalettePresets: vi.fn(),
    flagRequest: vi.fn(),
    cancelRequest: vi.fn(),
  },
  ApiError: class ApiError extends Error {
    problem: import('../../features/requests/types').ApiProblem;
    constructor(p: import('../../features/requests/types').ApiProblem) { super(); this.problem = p; }
  }
}));

const mockPresets: PalettePreset[] = [
  { id: 'preset-1', name: 'Ocean Breeze', colours: ['#000000', '#111111'] }
];

const defaultMockRequest: RequestDetail = {
  id: 'r1',
  referenceCode: 'REQ-123',
  clientId: 'client-1',
  roomType: 'LivingRoom',
  roomSizeSqFt: 500,
  budget: 500000,
  description: 'Nice room',
  status: 'Draft',
  isFlagged: false,
  createdAt: '2026-10-04T00:00:00Z',
  updatedAt: '2026-10-04T00:00:00Z',
  palette: [],
  moodboards: [
    { id: 'm1', url: 'https://example.com/1.jpg', sortOrder: 0 },
    { id: 'm2', url: 'https://example.com/2.jpg', sortOrder: 1 },
  ],
  statusHistory: [],
};

const renderComponent = (id: string = 'r1') => {
  return render(
    <ThemeProvider>
      <MemoryRouter initialEntries={[`/admin/requests/${id}`]}>
        <Routes>
          <Route path="/admin/requests/:id" element={<AdminRequestDetail />} />
        </Routes>
      </MemoryRouter>
    </ThemeProvider>
  );
};

describe('AdminRequestDetail', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    (requestApi.listPalettePresets as import('vitest').Mock).mockResolvedValue(mockPresets);
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });
  });

  describe('Palette rendering', () => {
    it('renders empty palette', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue(defaultMockRequest);
      renderComponent();
      expect(await screen.findByText('No colours chosen')).toBeInTheDocument();
    });

    it('renders Generated palette and shows base hex', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue({
        ...defaultMockRequest,
        paletteMode: 'Generated',
        paletteBaseHex: '#FF0000',
        palette: [{ hex: '#FF0000', position: 0 }]
      });
      renderComponent();
      expect(await screen.findByText('Generated from #FF0000')).toBeInTheDocument();
    });

    it('renders Preset palette with known name', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue({
        ...defaultMockRequest,
        paletteMode: 'Preset',
        palettePresetId: 'preset-1',
        palette: [{ hex: '#000000', position: 0 }]
      });
      renderComponent();
      expect(await screen.findByText('Preset: Ocean Breeze')).toBeInTheDocument();
    });

    it('renders Preset palette with unknown id', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue({
        ...defaultMockRequest,
        paletteMode: 'Preset',
        palettePresetId: 'unknown-id',
        palette: [{ hex: '#000000', position: 0 }]
      });
      renderComponent();
      expect(await screen.findByText('Preset: unknown-id')).toBeInTheDocument();
    });
  });

  describe('Clipboard Copy', () => {
    it('copies hex to clipboard', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue({
        ...defaultMockRequest,
        palette: [{ hex: '#ABCDEF', position: 0 }]
      });
      renderComponent();
      
      const copyBtn = await screen.findByText('#ABCDEF');
      // Click the parent button since the span text is inside it
      fireEvent.click(copyBtn.closest('button')!);
      
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('#ABCDEF');
    });
  });

  describe('Lightbox & Images', () => {
    it('opens lightbox, renders alt text, navigates via keyboard, and closes on Escape', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue(defaultMockRequest);
      renderComponent();
      
      // All images have alt text
      const img1 = await screen.findByAltText('Moodboard 1');
      const img2 = await screen.findByAltText('Moodboard 2');
      expect(img1).toBeInTheDocument();
      expect(img2).toBeInTheDocument();

      // Click to open lightbox
      fireEvent.click(img1.closest('button')!);
      
      // Lightbox opened
      const lightbox = screen.getByRole('dialog', { name: 'Image lightbox' });
      expect(lightbox).toBeInTheDocument();
      
      // Arrow navigation
      fireEvent.keyDown(window, { key: 'ArrowRight' });
      // Should show img 2 (the lightbox renders one image at a time, check its alt)
      const activeImage = screen.getAllByAltText('Moodboard 2');
      // One is thumbnail, one is lightbox. Let's find the one in dialog
      expect(activeImage.length).toBe(2); 

      // Escape closes
      fireEvent.keyDown(window, { key: 'Escape' });
      expect(screen.queryByRole('dialog', { name: 'Image lightbox' })).not.toBeInTheDocument();
    });
  });

  describe('Actions (Cancel / Flag)', () => {
    it('blocks short reasons and displays API errors in modal', async () => {
      (requestApi.getRequest as import('vitest').Mock).mockResolvedValue(defaultMockRequest);
      renderComponent();

      // Open menu and click flag
      fireEvent.click(await screen.findByTestId('actions-menu-btn'));
      fireEvent.click(screen.getByText('Flag as invalid'));

      const reasonInput = screen.getByPlaceholderText('Explain the reason...');
      const confirmBtn = screen.getByText('Confirm');

      // Invalid length (< 5)
      fireEvent.change(reasonInput, { target: { value: 'Bad' } });
      expect(confirmBtn).toBeDisabled();

      // Valid length but API returns error
      fireEvent.change(reasonInput, { target: { value: 'Valid reason' } });
      expect(confirmBtn).not.toBeDisabled();

      const apiError = new ApiError({ title: 'Server rejected', status: 409, detail: 'Conflict happened' } as import('../../features/requests/types').ApiProblem);
      (requestApi.flagRequest as import('vitest').Mock).mockRejectedValueOnce(apiError);

      fireEvent.click(confirmBtn);

      expect(await screen.findByText('Conflict happened')).toBeInTheDocument();
      // Keep what admin typed
      expect(reasonInput).toHaveValue('Valid reason');
    });

    it('successfully cancels, refetches and updates timeline', async () => {
      (requestApi.getRequest as import('vitest').Mock)
        .mockResolvedValueOnce(defaultMockRequest)
        .mockResolvedValueOnce({
          ...defaultMockRequest,
          status: 'Cancelled',
          cancelReason: 'Client called to cancel',
          statusHistory: [
            { toStatus: 'Cancelled', changedAt: '2026-10-04T12:00:00Z', note: 'Client called to cancel' }
          ]
        });

      (requestApi.cancelRequest as import('vitest').Mock).mockResolvedValueOnce(undefined);

      renderComponent();

      fireEvent.click(await screen.findByTestId('actions-menu-btn'));
      fireEvent.click(screen.getByText('Cancel request'));

      fireEvent.change(screen.getByPlaceholderText('Explain the reason...'), { target: { value: 'Client called to cancel' } });
      fireEvent.click(screen.getByText('Confirm'));

      // Wait for refetch to display the new reason in the UI
      expect(await screen.findByText('Request cancelled successfully')).toBeInTheDocument();
      
      // Should show in the Stored Reasons area
      expect(screen.getAllByText('Client called to cancel')[0]).toBeInTheDocument();
      
      // The timeline will now show Cancelled
      // Because we mocked the second getRequest to return Cancelled
      expect(requestApi.getRequest).toHaveBeenCalledTimes(2);
    });
  });
});
