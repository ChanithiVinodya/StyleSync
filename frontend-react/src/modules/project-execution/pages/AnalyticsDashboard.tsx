import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getProjectAnalytics } from '../api';
import { ProjectAnalytics } from '../types';
import { ProgressBar } from '../components/ProgressBar';
import { BarChart2, CheckCircle, Clock, AlertTriangle, RefreshCw } from 'lucide-react';

export default function AnalyticsDashboard() {
  const { projectId } = useOutletContext<{ projectId: string }>();
  const [analytics, setAnalytics] = useState<ProjectAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadAnalytics();
  }, [projectId]);

  const loadAnalytics = async () => {
    try {
      setLoading(true);
      const data = await getProjectAnalytics(projectId);
      setAnalytics(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load analytics.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading advanced analytics...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;
  if (!analytics) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">No data available.</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Execution Analytics</h2>
        <button onClick={loadAnalytics} className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] px-4 py-2.5 rounded-xl hover:bg-[#FAF8F5] dark:hover:bg-[#12100E] flex items-center shadow-sm text-sm font-semibold transition-colors">
          <RefreshCw className="w-4 h-4 mr-2 text-[#C48A36]" /> Refresh Data
        </button>
      </div>

      {/* Progress Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <div className="flex items-center text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider mb-4">
            <BarChart2 className="w-4 h-4 mr-2 text-[#C48A36]" /> Overall Progress
          </div>
          <div className="text-4xl font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-4">{analytics.overallProgress}%</div>
          <ProgressBar percentage={analytics.overallProgress} />
        </div>
        
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <div className="flex items-center text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider mb-4">
            <CheckCircle className="w-4 h-4 mr-2 text-emerald-500" /> Tasks Completed
          </div>
          <div className="text-4xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">
            {analytics.tasks.completed} <span className="text-[#A8A29E] dark:text-[#57534E] text-2xl font-sans">/ {analytics.tasks.total}</span>
          </div>
          <div className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-3 font-medium bg-[#FAF8F5] dark:bg-[#12100E] rounded-md px-2 py-1 inline-block border border-[#E7E1D7] dark:border-[#2E2824]">
            {analytics.tasks.completionPercentage}% completed
          </div>
        </div>

        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <div className="flex items-center text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider mb-4">
            <AlertTriangle className="w-4 h-4 mr-2 text-orange-500" /> Blocked Milestones
          </div>
          <div className="text-4xl font-serif text-orange-600 dark:text-orange-400">{analytics.materialGated.blockedMilestones}</div>
          <div className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-3 font-medium bg-orange-50 dark:bg-orange-950/30 rounded-md px-2 py-1 inline-block border border-orange-200 dark:border-orange-900/50 text-orange-700 dark:text-orange-300">
            Due to missing materials
          </div>
        </div>

        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <div className="flex items-center text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider mb-4">
            <Clock className="w-4 h-4 mr-2 text-rose-500" /> Total Delay
          </div>
          <div className="text-4xl font-serif text-rose-600 dark:text-rose-400">{analytics.delays.totalDelayDays}</div>
          <div className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-3 font-medium bg-rose-50 dark:bg-rose-950/30 rounded-md px-2 py-1 inline-block border border-rose-200 dark:border-rose-900/50 text-rose-700 dark:text-rose-300">
            {analytics.delays.delayedTasks} tasks cascaded
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Milestones Analytics */}
        <div className="bg-white dark:bg-[#1A1715] p-8 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <h3 className="text-xl font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-6">Milestone Distribution</h3>
          <div className="space-y-6">
            <div>
              <div className="flex justify-between mb-2 text-sm font-semibold text-[#57534E] dark:text-[#A8A29E]">
                <span>Completed</span>
                <span>{analytics.milestones.completed}</span>
              </div>
              <ProgressBar percentage={(analytics.milestones.completed / (analytics.milestones.total || 1)) * 100} colorClass="bg-emerald-500" />
            </div>
            <div>
              <div className="flex justify-between mb-2 text-sm font-semibold text-[#57534E] dark:text-[#A8A29E]">
                <span>In Progress</span>
                <span>{analytics.milestones.inProgress}</span>
              </div>
              <ProgressBar percentage={(analytics.milestones.inProgress / (analytics.milestones.total || 1)) * 100} colorClass="bg-blue-500" />
            </div>
            <div>
              <div className="flex justify-between mb-2 text-sm font-semibold text-[#57534E] dark:text-[#A8A29E]">
                <span>Delayed</span>
                <span>{analytics.milestones.delayed}</span>
              </div>
              <ProgressBar percentage={(analytics.milestones.delayed / (analytics.milestones.total || 1)) * 100} colorClass="bg-rose-500" />
            </div>
          </div>
        </div>

        {/* Materials Analytics */}
        <div className="bg-white dark:bg-[#1A1715] p-8 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <h3 className="text-xl font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-6">Logistics Flow</h3>
          <div className="grid grid-cols-2 gap-4">
            <div className="p-6 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-2xl text-center">
              <div className="text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider">Total</div>
              <div className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5] mt-2">{analytics.materials.total}</div>
            </div>
            <div className="p-6 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-900/50 rounded-2xl text-center">
              <div className="text-emerald-700 dark:text-emerald-400 text-xs font-bold uppercase tracking-wider">Delivered</div>
              <div className="text-3xl font-serif text-emerald-600 dark:text-emerald-400 mt-2">{analytics.materials.delivered}</div>
            </div>
            <div className="p-6 bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-900/50 rounded-2xl text-center">
              <div className="text-blue-700 dark:text-blue-400 text-xs font-bold uppercase tracking-wider">Ordered</div>
              <div className="text-3xl font-serif text-blue-600 dark:text-blue-400 mt-2">{analytics.materials.ordered}</div>
            </div>
            <div className="p-6 bg-orange-50 dark:bg-orange-950/30 border border-orange-200 dark:border-orange-900/50 rounded-2xl text-center">
              <div className="text-orange-700 dark:text-orange-400 text-xs font-bold uppercase tracking-wider">Pending</div>
              <div className="text-3xl font-serif text-orange-600 dark:text-orange-400 mt-2">{analytics.materials.required}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
