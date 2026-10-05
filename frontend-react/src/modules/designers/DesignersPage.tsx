import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Logo } from '../../components/Logo';
import { GlassThemeToggle } from '../../components/GlassThemeToggle';
import { getDesigners, createDesigner, updateDesigner, deleteDesigner, DesignerProfile, CreateDesignerProfile } from './api';

export default function DesignersPage() {
  const [designers, setDesigners] = useState<DesignerProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Form State
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState<CreateDesignerProfile>({
    userId: '',
    name: '',
    specialty: '',
    location: '',
    about: '',
    avatarUrl: '',
    coverUrl: '',
  });

  const fetchDesigners = async () => {
    try {
      setLoading(true);
      const res = await getDesigners();
      setDesigners(res.data);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to fetch designers.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDesigners();
  }, []);

  const handleOpenCreate = () => {
    setEditingId(null);
    setFormData({
      userId: '',
      name: '',
      specialty: '',
      location: '',
      about: '',
      avatarUrl: '',
      coverUrl: '',
    });
    setIsFormOpen(true);
  };

  const handleOpenEdit = (designer: DesignerProfile) => {
    setEditingId(designer.id);
    setFormData({
      userId: designer.userId,
      name: designer.name,
      specialty: designer.specialty,
      location: designer.location,
      about: designer.about,
      avatarUrl: designer.avatarUrl,
      coverUrl: designer.coverUrl,
    });
    setIsFormOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this designer?')) return;
    try {
      await deleteDesigner(id);
      fetchDesigners();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete designer.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        await updateDesigner(editingId, formData);
      } else {
        await createDesigner(formData);
      }
      setIsFormOpen(false);
      fetchDesigners();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to save designer.');
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] p-6 sm:p-10">
      <div className="max-w-6xl mx-auto space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <Logo variant="auto" size="md" />
            <div>
              <h1 className="font-serif text-2xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">Designers Management</h1>
              <p className="text-xs text-[#57534E] dark:text-[#A8A29E] mt-0.5">Manage designer profiles and portfolios</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GlassThemeToggle />
            <Link to="/admin/dashboard" className="px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition">
              Back to Dashboard
            </Link>
            <button onClick={handleOpenCreate} className="px-4 py-2 text-xs font-semibold text-white bg-[#8C4A3E] rounded-xl hover:bg-[#7A3E33] transition shadow-sm">
              + New Designer
            </button>
          </div>
        </div>

        {error && (
          <div className="p-3 text-xs text-rose-700 dark:text-rose-300 bg-rose-50 dark:bg-rose-950/50 border border-rose-200 dark:border-rose-900 rounded-xl">
            {error}
          </div>
        )}

        {isFormOpen && (
          <div className="bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs p-6">
            <h2 className="text-lg font-bold font-serif mb-4">{editingId ? 'Edit Designer' : 'Add New Designer'}</h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {!editingId && (
                  <div>
                    <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">User ID (Guid)</label>
                    <input required type="text" value={formData.userId} onChange={e => setFormData({...formData, userId: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                  </div>
                )}
                <div>
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">Name</label>
                  <input required type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">Specialty</label>
                  <input required type="text" value={formData.specialty} onChange={e => setFormData({...formData, specialty: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">Location</label>
                  <input required type="text" value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">Avatar URL</label>
                  <input required type="text" value={formData.avatarUrl} onChange={e => setFormData({...formData, avatarUrl: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">Cover URL</label>
                  <input required type="text" value={formData.coverUrl} onChange={e => setFormData({...formData, coverUrl: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]" />
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-xs font-semibold mb-1 text-[#57534E] dark:text-[#A8A29E]">About</label>
                  <textarea required rows={3} value={formData.about} onChange={e => setFormData({...formData, about: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-[#8C4A3E]"></textarea>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setIsFormOpen(false)} className="px-4 py-2 text-xs font-semibold text-[#1C1917] dark:text-[#FAF8F5] border border-[#E7E1D7] dark:border-[#2E2824] rounded-xl hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] transition">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 text-xs font-semibold text-white bg-[#8C4A3E] rounded-xl hover:bg-[#7A3E33] transition shadow-sm">
                  {editingId ? 'Update Designer' : 'Create Designer'}
                </button>
              </div>
            </form>
          </div>
        )}

        {!isFormOpen && (
          loading ? (
            <div className="text-center py-12 text-xs text-[#78716C]">Loading designers...</div>
          ) : designers.length === 0 ? (
            <div className="text-center py-12 text-xs text-[#78716C] bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl">No designers found. Create one to get started.</div>
          ) : (
            <div className="overflow-x-auto bg-white dark:bg-[#1A1715] border border-[#E7E1D7] dark:border-[#2E2824] rounded-3xl shadow-xs">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-[#E7E1D7] dark:border-[#2E2824] text-[11px] font-bold uppercase tracking-wider text-[#78716C] bg-[#FAF8F5] dark:bg-[#141210]">
                    <th className="py-4 px-6">Avatar</th>
                    <th className="py-4 px-6">Name</th>
                    <th className="py-4 px-6">Specialty</th>
                    <th className="py-4 px-6">Location</th>
                    <th className="py-4 px-6">Stats</th>
                    <th className="py-4 px-6">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E7E1D7] dark:divide-[#2E2824] text-xs text-[#44403C] dark:text-[#D6D3D1]">
                  {designers.map((d) => (
                    <tr key={d.id} className="hover:bg-[#FAF8F5]/60 dark:hover:bg-[#201C19]/60">
                      <td className="py-4 px-6">
                        <img src={d.avatarUrl} alt={d.name} className="w-10 h-10 rounded-full object-cover border border-[#E7E1D7] dark:border-[#2E2824]" />
                      </td>
                      <td className="py-4 px-6 font-semibold text-[#1C1917] dark:text-[#FAF8F5]">{d.name}</td>
                      <td className="py-4 px-6">{d.specialty}</td>
                      <td className="py-4 px-6">{d.location}</td>
                      <td className="py-4 px-6 text-[11px]">
                        <div className="text-[#8C4A3E] font-bold">{d.rating} ★ ({d.reviews})</div>
                        <div className="text-[#78716C]">{d.matchRate}% Match</div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <button onClick={() => handleOpenEdit(d)} className="px-3 py-1.5 rounded-xl text-xs font-semibold text-blue-700 bg-blue-50 border border-blue-200 hover:bg-blue-100 dark:bg-blue-900/30 dark:text-blue-300 dark:border-blue-800 transition">
                            Edit
                          </button>
                          <button onClick={() => handleDelete(d.id)} className="px-3 py-1.5 rounded-xl text-xs font-semibold text-rose-700 bg-rose-50 border border-rose-200 hover:bg-rose-100 dark:bg-rose-900/30 dark:text-rose-300 dark:border-rose-800 transition">
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        )}
      </div>
    </div>
  );
}
