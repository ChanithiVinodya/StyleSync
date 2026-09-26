import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getTasks, updateTaskStatus, createTask, getMilestones } from '../api';
import { Task, Milestone } from '../types';
import { StatusBadge } from '../components/StatusBadge';
import { Plus, Settings2, Link, CheckSquare, X } from 'lucide-react';

export default function TaskList() {
  const { projectId, userRole } = useOutletContext<{ projectId: string; userRole?: string }>();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [milestones, setMilestones] = useState<Milestone[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ milestoneId: '', name: '', description: '', startDate: '', dueDate: '' });
  const isClient = userRole === 'Client';

  useEffect(() => {
    loadData();
  }, [projectId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [tasksData, milestonesData] = await Promise.all([
        getTasks(),
        getMilestones(projectId)
      ]);
      setTasks(tasksData);
      setMilestones(milestonesData);
      if (milestonesData.length > 0) {
        setFormData(prev => ({ ...prev, milestoneId: milestonesData[0].milestoneId }));
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load tasks and milestones.');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (taskId: string, newStatus: string) => {
    if (isClient) return;
    try {
      await updateTaskStatus(taskId, newStatus);
      setTasks(tasks.map(t => t.taskId === taskId ? { ...t, status: newStatus as any } : t));
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update status. Dependency or material restrictions may apply.');
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isClient) return;
    if (!formData.milestoneId) {
      alert("Please select a milestone first.");
      return;
    }
    try {
      const newTask = await createTask({
        milestoneId: formData.milestoneId,
        name: formData.name,
        description: formData.description,
        startDate: new Date(formData.startDate).toISOString(),
        dueDate: new Date(formData.dueDate).toISOString()
      });
      setTasks([...tasks, newTask]);
      setShowForm(false);
      setFormData(prev => ({ ...prev, name: '', description: '', startDate: '', dueDate: '' }));
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to create task.');
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading tasks...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Project Tasks</h2>
        <div className="flex space-x-3">
          <button className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] px-4 py-2.5 rounded-xl hover:bg-[#FAF8F5] dark:hover:bg-[#12100E] flex items-center shadow-sm text-sm font-semibold transition-colors">
            <Settings2 className="w-4 h-4 mr-2 text-[#C48A36]" /> Filter
          </button>
          {!isClient && (
            <button 
              onClick={() => setShowForm(!showForm)}
              className="bg-[#C48A36] text-white px-5 py-2.5 rounded-xl hover:bg-[#A8742A] flex items-center shadow-sm text-sm font-semibold transition-colors"
            >
              {showForm ? <><X className="w-4 h-4 mr-2" /> Cancel</> : <><Plus className="w-4 h-4 mr-2" /> Create Task</>}
            </button>
          )}
        </div>
      </div>

      {showForm && !isClient && (
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#C48A36] mb-6 transition-all">
          <h3 className="text-lg font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-4">Create New Task</h3>
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div className="lg:col-span-3">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Milestone</label>
                <select 
                  required
                  value={formData.milestoneId} 
                  onChange={e => setFormData({...formData, milestoneId: e.target.value})} 
                  className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] appearance-none cursor-pointer"
                >
                  {milestones.length === 0 && <option value="">No milestones available</option>}
                  {milestones.map(m => (
                    <option key={m.milestoneId} value={m.milestoneId}>{m.name}</option>
                  ))}
                </select>
              </div>
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Task Name</label>
                <input required type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div className="lg:col-span-3">
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
              <button type="submit" disabled={!formData.milestoneId} className="bg-[#C48A36] text-white px-6 py-2 rounded-xl hover:bg-[#A8742A] text-sm font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                Save Task
              </button>
            </div>
          </form>
        </div>
      )}

      {tasks.length === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] p-16 text-center rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] text-[#57534E] dark:text-[#A8A29E]">
          <CheckSquare className="w-12 h-12 mx-auto text-[#E7E1D7] dark:text-[#2E2824] mb-4" />
          <p className="font-serif text-lg">No tasks found for this project.</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {tasks.map((task) => (
            <div key={task.taskId} className="bg-white dark:bg-[#1A1715] p-6 rounded-2xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] flex flex-col sm:flex-row sm:items-center justify-between hover:border-[#C48A36]/50 transition-colors group">
              <div className="flex-1">
                <div className="flex items-center space-x-3 mb-2">
                  <h3 className="font-serif text-xl text-[#1C1917] dark:text-[#FAF8F5]">{task.name}</h3>
                  <StatusBadge status={task.status} />
                  {task.cascadedDelay > 0 && (
                    <span className="text-[10px] uppercase font-bold text-rose-600 bg-rose-50 border border-rose-200 px-2 py-0.5 rounded-full dark:bg-rose-950/30 dark:border-rose-900/50 dark:text-rose-400">
                      Delayed ({task.cascadedDelay} days)
                    </span>
                  )}
                </div>
                <p className="text-sm text-[#57534E] dark:text-[#A8A29E] mb-3">{task.description}</p>
                <div className="text-xs text-[#78716C] dark:text-[#78716C] flex flex-wrap items-center gap-4">
                  <span className="bg-[#FAF8F5] dark:bg-[#12100E] px-2 py-1 rounded-md border border-[#E7E1D7] dark:border-[#2E2824]">Start: {new Date(task.startDate).toLocaleDateString()}</span>
                  <span className="bg-[#FAF8F5] dark:bg-[#12100E] px-2 py-1 rounded-md border border-[#E7E1D7] dark:border-[#2E2824]">Due: {new Date(task.dueDate).toLocaleDateString()}</span>
                  <button className="text-[#C48A36] hover:text-[#A8742A] flex items-center transition-colors">
                    <Link className="w-3.5 h-3.5 mr-1" /> Dependencies
                  </button>
                </div>
              </div>

              {!isClient && (
                <div className="mt-5 sm:mt-0 sm:ml-6 flex items-center space-x-2">
                  <select 
                    className="text-sm bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] transition-colors appearance-none cursor-pointer"
                    value={task.status}
                    onChange={(e) => handleStatusChange(task.taskId, e.target.value)}
                  >
                    <option value="NotStarted">Not Started</option>
                    <option value="InProgress">In Progress</option>
                    <option value="Completed">Completed</option>
                  </select>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
