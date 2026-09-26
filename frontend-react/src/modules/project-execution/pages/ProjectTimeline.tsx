import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getProjectTimeline } from '../api';
import { TimelineEvent } from '../types';
import { CheckCircle, Package, Camera, PlayCircle, PlusCircle, Activity, Flag, ListTodo, PackagePlus, Truck, PackageCheck } from 'lucide-react';

export default function ProjectTimeline() {
  const { projectId } = useOutletContext<{ projectId: string }>();
  const [events, setEvents] = useState<TimelineEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadTimeline();
  }, [projectId]);

  const loadTimeline = async () => {
    try {
      setLoading(true);
      const data = await getProjectTimeline(projectId);
      setEvents(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load timeline.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading execution timeline...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;

  const getEventIcon = (type: string) => {
    switch (type) {
      case 'MilestoneCreated':
        return <Flag className="w-5 h-5 text-blue-600 dark:text-blue-400" />;
      case 'TaskCreated':
        return <ListTodo className="w-5 h-5 text-purple-600 dark:text-purple-400" />;
      case 'MaterialRequested':
        return <PackagePlus className="w-5 h-5 text-amber-600 dark:text-amber-400" />;
      case 'MaterialOrdered':
        return <Truck className="w-5 h-5 text-orange-500 dark:text-orange-400" />;
      case 'MaterialDelivered':
        return <PackageCheck className="w-5 h-5 text-[#C48A36] dark:text-[#E8A849]" />;
      case 'MilestoneCompleted':
      case 'TaskCompleted':
        return <CheckCircle className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />;
      case 'ProgressPhotoUploaded':
        return <Camera className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />;
      case 'TaskStarted':
        return <PlayCircle className="w-5 h-5 text-teal-600 dark:text-teal-400" />;
      default:
        return <PlusCircle className="w-5 h-5 text-[#78716C] dark:text-[#A8A29E]" />;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Execution Timeline</h2>
      </div>

      {events.length === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] p-16 text-center rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] text-[#57534E] dark:text-[#A8A29E]">
          <Activity className="w-12 h-12 mx-auto text-[#E7E1D7] dark:text-[#2E2824] mb-4" />
          <p className="font-serif text-lg">No execution events recorded yet.</p>
        </div>
      ) : (
        <div className="bg-white dark:bg-[#1A1715] p-8 rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824]">
          <div className="relative border-l border-[#E7E1D7] dark:border-[#2E2824] ml-4 space-y-10">
            {[...events].sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()).map((event, index) => (
              <div key={event.eventId || index} className="relative ml-8">
                <span className="absolute flex items-center justify-center w-10 h-10 bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-full -left-13 ring-4 ring-white dark:ring-[#1A1715]">
                  {getEventIcon(event.eventType)}
                </span>
                <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-1">
                  <h3 className="font-serif text-lg font-bold text-[#1C1917] dark:text-[#FAF8F5]">{event.title || event.eventType.replace(/([A-Z])/g, ' $1').trim()}</h3>
                  <time className="block text-xs uppercase tracking-widest font-semibold text-[#78716C] dark:text-[#A8A29E]">
                    {new Date(event.timestamp).toLocaleString(undefined, {
                      year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit'
                    })}
                  </time>
                </div>
                {event.description && <p className="text-[#57534E] dark:text-[#A8A29E] mt-1">{event.description}</p>}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
