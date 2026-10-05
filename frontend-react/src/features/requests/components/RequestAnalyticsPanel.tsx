import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useRequestAnalytics } from '../hooks';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, PieChart, Pie, Legend } from 'recharts';
import { AlertTriangle, FileText, IndianRupee } from 'lucide-react';
import { AnalyticsQuery, RequestStatus, RoomType } from '../types';

// Utility colors matching brand roughly
const STATUS_COLORS: Record<RequestStatus, string> = {
  Draft: '#D9D2C7',
  Submitted: '#60A5FA',
  AIAnalysis: '#A78BFA',
  ProposalReady: '#FBBF24',
  AwaitingApproval: '#F472B6',
  Approved: '#10B981',
  DesignerAssigned: '#3B82F6',
  InProgress: '#6366F1',
  Completed: '#34D399',
  Rejected: '#F87171',
  Cancelled: '#9CA3AF'
};

const ROOM_COLORS: Record<RoomType, string> = {
  LivingRoom: '#E8A849',
  Bedroom: '#3B82F6',
  Kitchen: '#EF4444',
  Bathroom: '#10B981',
  DiningRoom: '#8B5CF6'
};

export const RequestAnalyticsPanel: React.FC = () => {
  const [query, setQuery] = useState<AnalyticsQuery>({});
  const { data, loading, error, refetch } = useRequestAnalytics(query);
  const navigate = useNavigate();

  const handleDateChange = (field: 'createdFrom' | 'createdTo', value: string) => {
    setQuery(prev => ({
      ...prev,
      [field]: value || undefined
    }));
  };

  const handleStatusClick = (status: string) => {
    navigate(`/admin/requests?status=${status}`);
  };

  const handleRoomTypeClick = (roomType: string) => {
    navigate(`/admin/requests?roomType=${roomType}`);
  };

  if (loading && !data) {
    return (
      <div className="animate-pulse space-y-6">
        <div className="h-24 bg-white dark:bg-[#1A1715] rounded-3xl" />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="h-64 bg-white dark:bg-[#1A1715] rounded-3xl" />
          <div className="h-64 bg-white dark:bg-[#1A1715] rounded-3xl" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 text-red-600 p-6 rounded-3xl flex flex-col items-center justify-center">
        <AlertTriangle className="mb-2" />
        <p className="font-semibold">{error.title || 'Failed to load analytics'}</p>
        <button 
          onClick={refetch}
          className="mt-4 px-4 py-2 bg-white dark:bg-black rounded-xl text-sm font-semibold hover:bg-gray-50 dark:hover:bg-gray-800 transition"
        >
          Try again
        </button>
      </div>
    );
  }

  if (!data) return null;

  const formattedBudget = data.averageBudget !== null 
    ? new Intl.NumberFormat('en-LK').format(data.averageBudget) 
    : '-';

  return (
    <div className="space-y-6">
      {/* Filters & Stats */}
      <div className="bg-white dark:bg-[#1A1715] rounded-3xl p-6 border border-[#E7E1D7] dark:border-[#2E2824] shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-[#78716C] uppercase tracking-wider">From Date</label>
            <input 
              type="date" 
              value={query.createdFrom || ''}
              onChange={e => handleDateChange('createdFrom', e.target.value)}
              className="px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#D9D2C7] dark:border-[#3E3834] rounded-xl text-sm focus:outline-none focus:border-amber-500"
            />
          </div>
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-[#78716C] uppercase tracking-wider">To Date</label>
            <input 
              type="date" 
              value={query.createdTo || ''}
              onChange={e => handleDateChange('createdTo', e.target.value)}
              className="px-3 py-2 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#D9D2C7] dark:border-[#3E3834] rounded-xl text-sm focus:outline-none focus:border-amber-500"
            />
          </div>
        </div>

        <div className="flex gap-4 md:gap-8">
          <div className="flex flex-col">
            <span className="text-[11px] font-bold text-[#78716C] uppercase tracking-wider flex items-center gap-1"><FileText size={12}/> Total</span>
            <span className="text-3xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">{data.totalRequests}</span>
          </div>
          <div className="flex flex-col">
            <span className="text-[11px] font-bold text-rose-600 uppercase tracking-wider flex items-center gap-1"><AlertTriangle size={12}/> Flagged</span>
            <span className="text-3xl font-serif font-bold text-rose-600">{data.flaggedCount}</span>
          </div>
          <div className="flex flex-col">
            <span className="text-[11px] font-bold text-[#78716C] uppercase tracking-wider flex items-center gap-1"><IndianRupee size={12}/> Avg Budget</span>
            <span className="text-3xl font-serif font-bold text-[#1C1917] dark:text-[#FAF8F5]">
              {data.averageBudget !== null ? `Rs. ${formattedBudget}` : '-'}
            </span>
          </div>
        </div>
      </div>

      {/* Charts */}
      {data.totalRequests === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] rounded-3xl p-10 text-center border border-[#E7E1D7] dark:border-[#2E2824] shadow-sm text-[#78716C]">
          No requests found for the selected period.
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          
          {/* Status Chart */}
          <div className="bg-white dark:bg-[#1A1715] rounded-3xl p-6 border border-[#E7E1D7] dark:border-[#2E2824] shadow-sm">
            <h3 className="text-sm font-bold text-[#1C1917] dark:text-[#FAF8F5] mb-6">Requests by Status</h3>
            <div className="h-[250px] w-full" role="img" aria-label="Bar chart showing requests by status">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data.byStatus} margin={{ top: 10, right: 10, left: -20, bottom: 20 }}>
                  <XAxis 
                    dataKey="status" 
                    tick={{ fontSize: 11, fill: '#78716C' }} 
                    angle={-45} 
                    textAnchor="end" 
                    interval={0} 
                    axisLine={false} 
                    tickLine={false} 
                  />
                  <YAxis 
                    allowDecimals={false} 
                    tick={{ fontSize: 11, fill: '#78716C' }} 
                    axisLine={false} 
                    tickLine={false} 
                  />
                  <Tooltip 
                    cursor={{ fill: 'rgba(0,0,0,0.05)' }} 
                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  />
                  <Bar 
                    dataKey="count" 
                    radius={[4, 4, 0, 0]} 
                    onClick={(entry) => handleStatusClick((entry as unknown as { status: RequestStatus }).status)}
                    className="cursor-pointer hover:opacity-80 transition-opacity"
                  >
                    {data.byStatus.map((entry) => (
                      <Cell key={entry.status} fill={STATUS_COLORS[entry.status] || '#CBD5E1'} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Room Type Chart */}
          <div className="bg-white dark:bg-[#1A1715] rounded-3xl p-6 border border-[#E7E1D7] dark:border-[#2E2824] shadow-sm flex flex-col">
            <h3 className="text-sm font-bold text-[#1C1917] dark:text-[#FAF8F5] mb-2">Requests by Room Type</h3>
            <div className="h-[250px] w-full flex-grow" role="img" aria-label="Donut chart showing requests by room type">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={data.byRoomType.filter(x => x.count > 0)}
                    dataKey="count"
                    nameKey="roomType"
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={2}
                    onClick={(entry) => handleRoomTypeClick((entry as unknown as { roomType: RoomType }).roomType)}
                    className="cursor-pointer hover:opacity-80 transition-opacity outline-none"
                  >
                    {data.byRoomType.filter(x => x.count > 0).map((entry) => (
                      <Cell key={entry.roomType} fill={ROOM_COLORS[entry.roomType] || '#CBD5E1'} className="outline-none" />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  />
                  <Legend 
                    wrapperStyle={{ fontSize: '11px' }} 
                    iconType="circle" 
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

        </div>
      )}
    </div>
  );
};
