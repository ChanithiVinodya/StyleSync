import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getProjectAnalytics } from '../api';
import { ProjectAnalytics } from '../types';
import { ProgressBar } from '../components/ProgressBar';
import { AlertCircle, FileText, CheckCircle2 } from 'lucide-react';

export default function ProjectExecutionDashboard() {
  const { projectId } = useOutletContext<{ projectId: string }>();
  const [analytics, setAnalytics] = useState<ProjectAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadDashboard = async () => {
      try {
        const data = await getProjectAnalytics(projectId);
        setAnalytics(data);
      } catch (err) {
        console.error('Failed to load dashboard', err);
      } finally {
        setLoading(false);
      }
    };
    loadDashboard();
  }, [projectId]);

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading execution dashboard...</div>;
  if (!analytics) return <div className="p-12 text-center text-rose-500 font-serif">Failed to load project data.</div>;

  return (
    <div className="space-y-6">
      {/* Project Header */}
      <div className="bg-white dark:bg-[#1A1715] p-8 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] flex flex-col md:flex-row justify-between items-start md:items-center relative overflow-hidden">
        {/* Subtle decorative accent */}
        <div className="absolute top-0 left-0 w-1 h-full bg-[#C48A36]"></div>
        
        <div className="pl-4">
          <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">{analytics.projectName || 'Project Details'}</h2>
          <p className="text-[#57534E] dark:text-[#A8A29E] text-xs mt-2 uppercase tracking-widest font-semibold">ID: {projectId}</p>
        </div>
        <div className="mt-6 md:mt-0 md:text-right w-full md:w-auto">
          <div className="text-xs uppercase tracking-wider font-semibold text-[#78716C] dark:text-[#A8A29E] mb-2">Overall Progress</div>
          <div className="flex items-center space-x-4">
            <div className="w-full md:w-64">
              <ProgressBar percentage={analytics.overallProgress} />
            </div>
            <span className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">{analytics.overallProgress}%</span>
          </div>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] relative overflow-hidden group hover:border-[#C48A36] transition-colors">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <FileText className="w-16 h-16 text-[#C48A36]" />
          </div>
          <div className="text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider flex items-center mb-4">
             Milestones
          </div>
          <div className="text-4xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">
            {analytics.milestones.completed} <span className="text-[#A8A29E] dark:text-[#57534E] text-2xl font-sans">/ {analytics.milestones.total}</span>
          </div>
        </div>
        
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] relative overflow-hidden group hover:border-emerald-500 transition-colors">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <CheckCircle2 className="w-16 h-16 text-emerald-500" />
          </div>
          <div className="text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider flex items-center mb-4">
             Tasks
          </div>
          <div className="text-4xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">
            {analytics.tasks.completed} <span className="text-[#A8A29E] dark:text-[#57534E] text-2xl font-sans">/ {analytics.tasks.total}</span>
          </div>
        </div>

        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] relative overflow-hidden group hover:border-rose-500 transition-colors">
           <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <AlertCircle className="w-16 h-16 text-rose-500" />
          </div>
          <div className="text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider flex items-center mb-4">
             Delayed Tasks
          </div>
          <div className="text-4xl font-serif text-rose-600 dark:text-rose-400">{analytics.tasks.delayed}</div>
        </div>

        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] relative overflow-hidden group hover:border-orange-500 transition-colors">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <AlertCircle className="w-16 h-16 text-orange-500" />
          </div>
          <div className="text-[#78716C] dark:text-[#A8A29E] text-xs font-bold uppercase tracking-wider flex items-center mb-4">
             Blocked Milestones
          </div>
          <div className="text-4xl font-serif text-orange-600 dark:text-orange-400">{analytics.materialGated.blockedMilestones}</div>
        </div>
      </div>

      <div className="bg-white dark:bg-[#1A1715] p-8 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
        <h3 className="text-xl font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-6">Execution Health Assessment</h3>
        {analytics.tasks.delayed > 0 ? (
          <div className="p-6 bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-900/50 rounded-2xl flex items-start">
            <div className="p-3 bg-white dark:bg-[#1A1715] rounded-full shadow-sm mr-4 shrink-0">
               <AlertCircle className="w-6 h-6 text-rose-600 dark:text-rose-400" />
            </div>
            <div>
              <h4 className="font-serif text-lg text-rose-900 dark:text-rose-300">Project is experiencing delays</h4>
              <p className="text-sm text-rose-700 dark:text-rose-400/80 mt-2 leading-relaxed">
                Critical path affected. There are <strong className="font-bold">{analytics.tasks.delayed}</strong> delayed tasks resulting in an aggregated <strong className="font-bold">{analytics.delays.totalDelayDays}</strong> total days of delay cascade.
              </p>
            </div>
          </div>
        ) : (
          <div className="p-6 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-900/50 rounded-2xl flex items-start">
            <div className="p-3 bg-white dark:bg-[#1A1715] rounded-full shadow-sm mr-4 shrink-0">
               <CheckCircle2 className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
            </div>
            <div>
              <h4 className="font-serif text-lg text-emerald-900 dark:text-emerald-300">Project execution is optimal</h4>
              <p className="text-sm text-emerald-700 dark:text-emerald-400/80 mt-2 leading-relaxed">
                All workflows are operating within their scheduled timeframes. No active delays detected in current task dependency chains.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
