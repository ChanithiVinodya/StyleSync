import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getMilestones, createMilestone, deleteMilestone } from '../api';
import { Milestone } from '../types';
import { StatusBadge } from '../components/StatusBadge';
import { Plus, Trash2, Edit, Layers, X } from 'lucide-react';

export default function MilestoneList() {
  const { projectId, userRole } = useOutletContext<{ projectId: string; userRole?: string }>();
  const [milestones, setMilestones] = useState<Milestone[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', description: '', startDate: '', dueDate: '' });
  const isClient = userRole === 'Client';

  useEffect(() => {
    loadMilestones();
  }, [projectId]);

  const loadMilestones = async () => {
    try {
      setLoading(true);
      const data = await getMilestones(projectId);
      setMilestones(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load milestones.');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isClient) return;
    try {
      const newMilestone = await createMilestone({
        projectId,
        name: formData.name,
        description: formData.description,
        startDate: new Date(formData.startDate).toISOString(),
        dueDate: new Date(formData.dueDate).toISOString()
      });
      setMilestones([...milestones, newMilestone]);
      setShowForm(false);
      setFormData({ name: '', description: '', startDate: '', dueDate: '' });
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to create milestone.');
    }
  };

  const handleDelete = async (id: string) => {
    if (isClient) return;
    if (!window.confirm('Are you sure you want to delete this milestone?')) return;
    try {
      await deleteMilestone(id);
      setMilestones(milestones.filter(m => m.milestoneId !== id));
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete milestone. It may have associated tasks.');
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading milestones...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Project Milestones</h2>
        {!isClient && (
          <button 
            onClick={() => setShowForm(!showForm)}
            className="bg-[#C48A36] text-white px-5 py-2.5 rounded-xl hover:bg-[#A8742A] flex items-center shadow-sm text-sm font-semibold transition-colors"
          >
            {showForm ? <><X className="w-4 h-4 mr-2" /> Cancel</> : <><Plus className="w-4 h-4 mr-2" /> Create Milestone</>}
          </button>
        )}
      </div>

      {showForm && !isClient && (
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#C48A36] mb-6 transition-all">
          <h3 className="text-lg font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-4">Create New Milestone</h3>
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Name</label>
                <input required type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Description</label>
                <input required type="text" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Start Date</label>
                <input required type="date" value={formData.startDate} onChange={e => setFormData({...formData, startDate: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Due Date</label>
                <input required type="date" value={formData.dueDate} onChange={e => setFormData({...formData, dueDate: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <button type="submit" className="bg-[#C48A36] text-white px-6 py-2 rounded-xl hover:bg-[#A8742A] text-sm font-semibold transition-colors">
                Save Milestone
              </button>
            </div>
          </form>
        </div>
      )}

      {milestones.length === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] p-16 text-center rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] text-[#57534E] dark:text-[#A8A29E]">
          <Layers className="w-12 h-12 mx-auto text-[#E7E1D7] dark:text-[#2E2824] mb-4" />
          <p className="font-serif text-lg">No milestones have been scheduled yet.</p>
        </div>
      ) : (
        <div className="bg-white dark:bg-[#1A1715] rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-[#E7E1D7] dark:divide-[#2E2824]">
              <thead className="bg-[#FAF8F5] dark:bg-[#12100E]">
                <tr>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Name</th>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Dates</th>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Status</th>
                  {!isClient && <th className="px-8 py-4 text-right text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Actions</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E7E1D7] dark:divide-[#2E2824]">
                {milestones.map((milestone) => (
                  <tr key={milestone.milestoneId} className="hover:bg-[#FAF8F5]/50 dark:hover:bg-[#12100E]/50 transition-colors">
                    <td className="px-8 py-5 whitespace-nowrap">
                      <div className="font-serif text-lg text-[#1C1917] dark:text-[#FAF8F5]">{milestone.name}</div>
                      <div className="text-sm text-[#57534E] dark:text-[#A8A29E] truncate max-w-xs">{milestone.description}</div>
                    </td>
                    <td className="px-8 py-5 whitespace-nowrap text-sm text-[#57534E] dark:text-[#A8A29E]">
                      <div className="mb-1"><span className="text-[#C48A36] font-semibold mr-2">Start</span> {new Date(milestone.startDate).toLocaleDateString()}</div>
                      <div><span className="text-[#C48A36] font-semibold mr-2">Due</span> {new Date(milestone.dueDate).toLocaleDateString()}</div>
                    </td>
                    <td className="px-8 py-5 whitespace-nowrap">
                      <StatusBadge status={milestone.status} />
                    </td>
                    {!isClient && (
                      <td className="px-8 py-5 whitespace-nowrap text-right text-sm font-medium">
                        <button className="text-[#57534E] hover:text-[#C48A36] dark:text-[#A8A29E] dark:hover:text-[#C48A36] mr-4 transition-colors" title="Edit">
                          <Edit className="w-5 h-5" />
                        </button>
                        <button 
                          className="text-rose-600/70 hover:text-rose-700 dark:hover:text-rose-400 transition-colors" 
                          onClick={() => handleDelete(milestone.milestoneId)}
                          title="Delete"
                        >
                          <Trash2 className="w-5 h-5" />
                        </button>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
