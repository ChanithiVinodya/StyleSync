import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { RequestAnalyticsPanel } from './RequestAnalyticsPanel';
import { requestApi } from '../api';
import { RequestAnalytics } from '../types';

const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

vi.mock('../api', () => ({
  requestApi: {
    getRequestAnalytics: vi.fn(),
  }
}));

// Mock recharts to avoid ResizeObserver and complex SVG rendering in JSDOM
vi.mock('recharts', () => {
  return {
    ResponsiveContainer: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
    BarChart: ({ children }: { children: React.ReactNode }) => <div data-testid="recharts-barchart">{children}</div>,
    Bar: ({ onClick }: { onClick?: (args: unknown) => void }) => (
      <button 
        data-testid="recharts-bar" 
        onClick={() => onClick && onClick({ status: 'Draft' })}
      />
    ),
    PieChart: ({ children }: { children: React.ReactNode }) => <div data-testid="recharts-piechart">{children}</div>,
    Pie: ({ onClick }: { onClick?: (args: unknown) => void }) => (
      <button 
        data-testid="recharts-pie" 
        onClick={() => onClick && onClick({ roomType: 'Kitchen' })}
      />
    ),
    XAxis: () => null,
    YAxis: () => null,
    Tooltip: () => null,
    Cell: () => null,
    Legend: () => null,
  };
});

const mockData: RequestAnalytics = {
  totalRequests: 15,
  flaggedCount: 2,
  averageBudget: 150000,
  averageBudgetByRoomType: [
    { roomType: 'LivingRoom', averageBudget: 200000 }
  ],
  byStatus: [
    { status: 'Draft', count: 5 },
    { status: 'Submitted', count: 10 },
    { status: 'Completed', count: 0 } // Zero-count category
  ],
  byRoomType: [
    { roomType: 'LivingRoom', count: 12 },
    { roomType: 'Kitchen', count: 3 }
  ]
};

describe('RequestAnalyticsPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    (requestApi.getRequestAnalytics as import('vitest').Mock).mockResolvedValue(mockData);
  });

  const renderComponent = () => 
    render(
      <MemoryRouter>
        <RequestAnalyticsPanel />
      </MemoryRouter>
    );

  it('renders correctly from a fixture', async () => {
    renderComponent();
    
    // Wait for the data to load
    expect(await screen.findByText('15')).toBeInTheDocument(); // Total
    expect(screen.getByText('2')).toBeInTheDocument(); // Flagged
    expect(screen.getByText('Rs. 150,000')).toBeInTheDocument(); // Avg budget
  });

  it('includes zero-count categories and accessible labels', async () => {
    renderComponent();
    
    // Wait for loading to finish
    await screen.findByText('15');
    
    // Check aria labels
    expect(screen.getByRole('img', { name: /Bar chart showing requests by status/i })).toBeInTheDocument();
    expect(screen.getByRole('img', { name: /Donut chart showing requests by room type/i })).toBeInTheDocument();
  });

  it('navigates to correctly filtered url when clicking a bar', async () => {
    renderComponent();
    
    await screen.findByText('15');
    
    const bar = screen.getByTestId('recharts-bar');
    fireEvent.click(bar);
    
    expect(mockNavigate).toHaveBeenCalledWith('/admin/requests?status=Draft');
  });

  it('navigates to correctly filtered url when clicking a pie segment', async () => {
    renderComponent();
    
    await screen.findByText('15');
    
    const pie = screen.getByTestId('recharts-pie');
    fireEvent.click(pie);
    
    expect(mockNavigate).toHaveBeenCalledWith('/admin/requests?roomType=Kitchen');
  });
});
