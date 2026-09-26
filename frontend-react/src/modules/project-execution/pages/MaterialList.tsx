import React, { useEffect, useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getMaterials, updateMaterialStatus, createMaterial, getMilestones, getTasks } from '../api';
import { Material, Milestone, Task } from '../types';
import { StatusBadge } from '../components/StatusBadge';
import { PackagePlus, Package, X } from 'lucide-react';

export default function MaterialList() {
  const { projectId, userRole } = useOutletContext<{ projectId: string; userRole?: string }>();
  const [materials, setMaterials] = useState<Material[]>([]);
  const [milestones, setMilestones] = useState<Milestone[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    milestoneId: '', taskId: '', name: '', description: '', quantity: 1, unit: 'pcs', requiredDate: ''
  });
  const isClient = userRole === 'Client';

  useEffect(() => {
    loadData();
  }, [projectId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [matData, milData, taskData] = await Promise.all([
        getMaterials(projectId),
        getMilestones(projectId),
        getTasks()
      ]);
      setMaterials(matData);
      setMilestones(milData);
      setTasks(taskData);
      
      if (milData.length > 0) {
        setFormData(prev => ({ ...prev, milestoneId: milData[0].milestoneId }));
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load materials.');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (id: string, newStatus: string) => {
    if (isClient) return;
    try {
      await updateMaterialStatus(id, newStatus);
      setMaterials(materials.map(m => m.materialId === id ? { ...m, status: newStatus as any } : m));
    } catch (err: any) {
      alert('Failed to update material status.');
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isClient) return;
    if (!formData.milestoneId || !formData.taskId) {
      alert("Please select both a milestone and a task to bind this material to.");
      return;
    }
    try {
      const newMaterial = await createMaterial({
        projectId,
        milestoneId: formData.milestoneId,
        taskId: formData.taskId,
        name: formData.name,
        description: formData.description,
        quantity: Number(formData.quantity),
        unit: formData.unit,
        requiredDate: formData.requiredDate ? new Date(formData.requiredDate).toISOString() : undefined
      });
      setMaterials([...materials, newMaterial]);
      setShowForm(false);
      setFormData(prev => ({ ...prev, name: '', description: '', quantity: 1, requiredDate: '' }));
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to request material.');
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading materials...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Material Logistics</h2>
        {!isClient && (
          <button 
            onClick={() => setShowForm(!showForm)}
            className="bg-[#C48A36] text-white px-5 py-2.5 rounded-xl hover:bg-[#A8742A] flex items-center shadow-sm text-sm font-semibold transition-colors"
          >
            {showForm ? <><X className="w-4 h-4 mr-2" /> Cancel</> : <><PackagePlus className="w-4 h-4 mr-2" /> Request Material</>}
          </button>
        )}
      </div>

      {showForm && !isClient && (
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#C48A36] mb-6 transition-all">
          <h3 className="text-lg font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-4">Request New Material</h3>
          <form onSubmit={handleCreate} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Milestone</label>
                <select required value={formData.milestoneId} onChange={e => setFormData({...formData, milestoneId: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] appearance-none cursor-pointer">
                  {milestones.length === 0 && <option value="">No milestones available</option>}
                  {milestones.map(m => <option key={m.milestoneId} value={m.milestoneId}>{m.name}</option>)}
                </select>
              </div>
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Task</label>
                <select required value={formData.taskId} onChange={e => setFormData({...formData, taskId: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] appearance-none cursor-pointer">
                  <option value="">-- Select a Task --</option>
                  {tasks.filter(t => t.milestoneId === formData.milestoneId).map(t => (
                    <option key={t.taskId} value={t.taskId}>{t.name}</option>
                  ))}
                </select>
              </div>
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Material Name</label>
                <input required type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Description</label>
                <input type="text" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Quantity</label>
                <input required type="number" min="0.1" step="0.1" value={formData.quantity} onChange={e => setFormData({...formData, quantity: Number(e.target.value)})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Unit</label>
                <input required type="text" value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value})} placeholder="e.g. sq ft, liters, pcs" className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div className="lg:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Required By (Date)</label>
                <input required type="date" value={formData.requiredDate} onChange={e => setFormData({...formData, requiredDate: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <button type="submit" disabled={!formData.milestoneId || !formData.taskId} className="bg-[#C48A36] text-white px-6 py-2 rounded-xl hover:bg-[#A8742A] text-sm font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                Submit Request
              </button>
            </div>
          </form>
        </div>
      )}

      {materials.length === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] p-16 text-center rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] text-[#57534E] dark:text-[#A8A29E]">
          <Package className="w-12 h-12 mx-auto text-[#E7E1D7] dark:text-[#2E2824] mb-4" />
          <p className="font-serif text-lg">No materials required for this project yet.</p>
        </div>
      ) : (
        <div className="bg-white dark:bg-[#1A1715] rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-[#E7E1D7] dark:divide-[#2E2824]">
              <thead className="bg-[#FAF8F5] dark:bg-[#12100E]">
                <tr>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Item Details</th>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Quantity</th>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Status</th>
                  <th className="px-8 py-4 text-left text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Required By</th>
                  {!isClient && <th className="px-8 py-4 text-right text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider">Update Status</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E7E1D7] dark:divide-[#2E2824]">
                {materials.map((material) => (
                  <tr key={material.materialId} className="hover:bg-[#FAF8F5]/50 dark:hover:bg-[#12100E]/50 transition-colors">
                    <td className="px-8 py-5 whitespace-nowrap">
                      <div className="font-serif text-lg text-[#1C1917] dark:text-[#FAF8F5]">{material.name}</div>
                      <div className="text-sm text-[#57534E] dark:text-[#A8A29E]">{material.description}</div>
                    </td>
                    <td className="px-8 py-5 whitespace-nowrap text-sm font-semibold text-[#C48A36]">
                      {material.quantity} {material.unit}
                    </td>
                    <td className="px-8 py-5 whitespace-nowrap">
                      <StatusBadge status={material.status} />
                    </td>
                    <td className="px-8 py-5 whitespace-nowrap text-sm text-[#57534E] dark:text-[#A8A29E]">
                      {material.requiredDate ? new Date(material.requiredDate).toLocaleDateString() : 'N/A'}
                    </td>
                    {!isClient && (
                      <td className="px-8 py-5 whitespace-nowrap text-right text-sm font-medium">
                        <select 
                          className="text-sm bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] transition-colors cursor-pointer appearance-none"
                          value={material.status}
                          onChange={(e) => handleStatusChange(material.materialId, e.target.value)}
                        >
                          <option value="Required">Required</option>
                          <option value="Ordered">Ordered</option>
                          <option value="Delivered">Delivered</option>
                        </select>
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
