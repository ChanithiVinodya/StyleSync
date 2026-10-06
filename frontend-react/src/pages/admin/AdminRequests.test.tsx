import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdminRequests } from './AdminRequests';
import { requestApi, ApiError } from '../../features/requests/api';
import { ThemeProvider } from '../../context/ThemeContext';

vi.mock('../../auth/AuthContext', () => ({
  useAuth: () => ({
    user: { id: 'admin-1', role: 'Admin', name: 'Admin', email: 'admin@stylesync.com' },
    token: 'mock-token',
    login: vi.fn(),
    logout: vi.fn(),
    isLoading: false,
  }),
}));

vi.mock('../../features/requests/api', () => {
  return {
    requestApi: {
      listRequests: vi.fn(),
    },
    ApiError: class ApiError extends Error {
      problem: import('../../features/requests/types').ApiProblem;
      constructor(p: import('../../features/requests/types').ApiProblem) { super(); this.problem = p; }
    }
  };
});

// Avoid date parsing discrepancies in tests
const mockResult = {
  items: [
    {
      id: 'r1',
      referenceCode: 'REQ-123',
      roomType: 'LivingRoom',
      budget: 500000,
      status: 'Draft',
      isFlagged: false,
      createdAt: '2026-10-04T00:00:00Z',
      updatedAt: '2026-10-04T00:00:00Z',
      clientDisplayName: 'John Doe',
    }
  ],
  totalCount: 1,
  page: 1,
  pageSize: 10,
  totalPages: 1
};

const LocationDisplay = () => {
  const location = useLocation();
  return <div data-testid="location-display">{location.search}</div>;
};

const renderComponent = (initialUrl: string = '/admin/requests') => {
  return render(
    <ThemeProvider>
      <MemoryRouter initialEntries={[initialUrl]}>
        <AdminRequests />
        <LocationDisplay />
      </MemoryRouter>
    </ThemeProvider>
  );
};

describe('AdminRequests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('hydrates controls from URL parameters and fetches data', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue(mockResult);

    renderComponent('/admin/requests?search=luxury&minBudget=10000&isFlagged=true');

    // Check if input is hydrated
    const searchInput = screen.getByPlaceholderText('Search reference or description...') as HTMLInputElement;
    expect(searchInput.value).toBe('luxury');

    const minBudget = screen.getByPlaceholderText('Min Budget') as HTMLInputElement;
    expect(minBudget.value).toBe('10000');

    const flaggedToggle = screen.getByLabelText('Flagged Only') as HTMLInputElement;
    expect(flaggedToggle.checked).toBe(true);

    await waitFor(() => {
      expect(requestApi.listRequests).toHaveBeenCalledWith(
        expect.objectContaining({
          search: 'luxury',
          minBudget: 10000,
          isFlagged: true
        })
      );
    });

    // Check if table renders
    expect(await screen.findByText('REQ-123')).toBeInTheDocument();
  });

  it('debounces search input and resets page', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue(mockResult);
    
    // Start at page 2
    renderComponent('/admin/requests?page=2');
    
    // Initial fetch should be called
    await waitFor(() => expect(requestApi.listRequests).toHaveBeenCalledTimes(1));

    const searchInput = screen.getByPlaceholderText('Search reference or description...');
    
    fireEvent.change(searchInput, { target: { value: 'modern' } });
    
    // Shouldn't be called immediately
    expect(requestApi.listRequests).toHaveBeenCalledTimes(1);

    // After debounce
    await waitFor(() => {
      expect(requestApi.listRequests).toHaveBeenCalledTimes(2);
    }, { timeout: 600 });

    const callArgs = (requestApi.listRequests as import('vitest').Mock).mock.calls[1][0];
    expect(callArgs.search).toBe('modern');
    expect(callArgs.page).toBe(1); // Page reset
  });

  it('handles client-side budget validation', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue(mockResult);

    renderComponent('/admin/requests?minBudget=50000&maxBudget=10000');
    
    expect(await screen.findByText(/Min budget cannot exceed max budget/i)).toBeInTheDocument();
    
    // It should omit budget parameters from the actual API call
    await waitFor(() => {
      const callArgs = (requestApi.listRequests as import('vitest').Mock).mock.calls[0][0];
      expect(callArgs.minBudget).toBeUndefined();
      expect(callArgs.maxBudget).toBeUndefined();
    });
  });

  it('renders empty state', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue({ items: [], totalCount: 0, page: 1, pageSize: 10, totalPages: 0 });
    renderComponent();
    expect(await screen.findByText('No requests match your filters.')).toBeInTheDocument();
  });

  it('renders error state and retry button', async () => {
    const error = new ApiError({ title: 'Server Failed', status: 500, detail: 'Timeout' } as import('../../features/requests/types').ApiProblem);
    (requestApi.listRequests as import('vitest').Mock).mockRejectedValueOnce(error).mockResolvedValueOnce(mockResult);
    
    renderComponent();
    expect(await screen.findByText('Server Failed')).toBeInTheDocument();
    
    // Find retry button
    const retryButton = screen.getByTestId('retry-btn');
    fireEvent.click(retryButton);
    
    await waitFor(() => {
      expect(requestApi.listRequests).toHaveBeenCalledTimes(2);
    });
  });
  
  it('handles table sorting', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue(mockResult);
    renderComponent();
    
    const budgetHeader = await screen.findByText(/Budget/i);
    fireEvent.click(budgetHeader);
    
    await waitFor(() => {
      const callArgs = (requestApi.listRequests as import('vitest').Mock).mock.calls.slice(-1)[0][0];
      expect(callArgs.sortBy).toBe('budget');
      expect(callArgs.sortDir).toBe('asc');
    });
    
    // Click again to toggle
    fireEvent.click(budgetHeader);
    
    await waitFor(() => {
      const callArgs = (requestApi.listRequests as import('vitest').Mock).mock.calls.slice(-1)[0][0];
      expect(callArgs.sortBy).toBe('budget');
      expect(callArgs.sortDir).toBe('desc');
    });
  });

  it('serializes query params to URL when controls change', async () => {
    (requestApi.listRequests as import('vitest').Mock).mockResolvedValue(mockResult);
    renderComponent('/admin/requests');
    
    // Set a control
    const minBudget = await screen.findByPlaceholderText('Min Budget');
    fireEvent.change(minBudget, { target: { value: '25000' } });
    
    // Wait for the URL to update
    const locationDisplay = await screen.findByTestId('location-display');
    await waitFor(() => {
      expect(locationDisplay.textContent).toContain('minBudget=25000');
    });
  });
});
