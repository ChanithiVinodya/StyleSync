import React, { useEffect, useState, useRef } from 'react';
import { useOutletContext } from 'react-router-dom';
import { getProgressPhotos, uploadProgressPhoto, getMilestones, getTasks } from '../api';
import { ProgressPhoto, Milestone, Task } from '../types';
import { Upload, Camera, Image as ImageIcon, X } from 'lucide-react';

export default function ProgressPhotos() {
  const { projectId, userRole } = useOutletContext<{ projectId: string; userRole?: string }>();
  const [photos, setPhotos] = useState<ProgressPhoto[]>([]);
  const [milestones, setMilestones] = useState<Milestone[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ milestoneId: '', taskId: '', description: '' });
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const isClient = userRole === 'Client';

  useEffect(() => {
    loadData();
  }, [projectId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [photoData, milData, taskData] = await Promise.all([
        getProgressPhotos(projectId),
        getMilestones(projectId),
        getTasks()
      ]);
      setPhotos(photoData);
      setMilestones(milData);
      setTasks(taskData);
      if (milData.length > 0) {
        setFormData(prev => ({ ...prev, milestoneId: milData[0].milestoneId }));
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load photos.');
    } finally {
      setLoading(false);
    }
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isClient) return;
    const file = fileInputRef.current?.files?.[0];
    if (!file) {
      alert("Please select a file to upload.");
      return;
    }
    
    setUploading(true);
    try {
      const data = new FormData();
      data.append('ProjectId', projectId);
      data.append('Caption', formData.description);
      data.append('File', file);
      if (formData.milestoneId) data.append('MilestoneId', formData.milestoneId);
      if (formData.taskId) data.append('TaskId', formData.taskId);

      const newPhoto = await uploadProgressPhoto(data);
      setPhotos([newPhoto, ...photos]);
      setShowForm(false);
      setFormData(prev => ({ ...prev, description: '' }));
      if (fileInputRef.current) fileInputRef.current.value = '';
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to upload photo.');
    } finally {
      setUploading(false);
    }
  };

  if (loading) return <div className="p-12 text-center text-[#57534E] dark:text-[#A8A29E] font-serif">Loading progress photos...</div>;
  if (error) return <div className="p-12 text-center text-rose-500 font-serif">{error}</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center mb-8">
        <h2 className="text-3xl font-serif text-[#1C1917] dark:text-[#FAF8F5]">Visual Progress</h2>
        {!isClient && (
          <button 
            onClick={() => setShowForm(!showForm)}
            className="bg-[#C48A36] text-white px-5 py-2.5 rounded-xl hover:bg-[#A8742A] flex items-center shadow-sm text-sm font-semibold transition-colors"
          >
            {showForm ? <><X className="w-4 h-4 mr-2" /> Cancel</> : <><Upload className="w-4 h-4 mr-2" /> Upload Photo</>}
          </button>
        )}
      </div>

      {showForm && !isClient && (
        <div className="bg-white dark:bg-[#1A1715] p-6 rounded-3xl shadow-sm border border-[#C48A36] mb-6 transition-all">
          <h3 className="text-lg font-serif text-[#1C1917] dark:text-[#FAF8F5] mb-4">Upload Progress Photo</h3>
          <form onSubmit={handleUpload} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Milestone (Optional)</label>
                <select value={formData.milestoneId} onChange={e => setFormData({...formData, milestoneId: e.target.value, taskId: ''})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] appearance-none cursor-pointer">
                  <option value="">-- None --</option>
                  {milestones.map(m => <option key={m.milestoneId} value={m.milestoneId}>{m.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Task (Optional)</label>
                <select value={formData.taskId} onChange={e => setFormData({...formData, taskId: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36] appearance-none cursor-pointer">
                  <option value="">-- None --</option>
                  {tasks.filter(t => !formData.milestoneId || t.milestoneId === formData.milestoneId).map(t => (
                    <option key={t.taskId} value={t.taskId}>{t.name}</option>
                  ))}
                </select>
              </div>
              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Description</label>
                <input required type="text" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 focus:outline-hidden focus:border-[#C48A36]" />
              </div>
              <div className="md:col-span-2">
                <label className="block text-xs font-bold text-[#78716C] dark:text-[#A8A29E] uppercase tracking-wider mb-1">Select Image</label>
                <input required type="file" accept="image/*" ref={fileInputRef} className="w-full bg-[#FAF8F5] dark:bg-[#12100E] border border-[#E7E1D7] dark:border-[#2E2824] text-[#1C1917] dark:text-[#FAF8F5] rounded-xl px-4 py-2 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-[#FAF3E8] file:text-[#925C18] hover:file:bg-[#E8DEC8]" />
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <button type="submit" disabled={uploading} className="bg-[#C48A36] text-white px-6 py-2 rounded-xl hover:bg-[#A8742A] text-sm font-semibold transition-colors disabled:opacity-50">
                {uploading ? 'Uploading...' : 'Complete Upload'}
              </button>
            </div>
          </form>
        </div>
      )}

      {photos.length === 0 ? (
        <div className="bg-white dark:bg-[#1A1715] p-16 text-center rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] text-[#57534E] dark:text-[#A8A29E]">
          <ImageIcon className="w-12 h-12 mx-auto text-[#E7E1D7] dark:text-[#2E2824] mb-4" />
          <p className="font-serif text-lg">No progress photos have been uploaded yet.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {photos.map((photo) => (
            <div key={photo.photoId} className="bg-white dark:bg-[#1A1715] rounded-3xl shadow-sm border border-[#E7E1D7] dark:border-[#2E2824] overflow-hidden group hover:border-[#C48A36]/50 transition-colors">
              <div className="aspect-[4/3] bg-[#FAF8F5] dark:bg-[#12100E] relative overflow-hidden">
                <img 
                  src={photo.fileUrl.startsWith('http') ? photo.fileUrl : `http://localhost:5000${photo.fileUrl}`} 
                  alt={photo.caption || 'Progress Photo'} 
                  className="object-cover w-full h-full transform group-hover:scale-105 transition-transform duration-500"
                  onError={(e) => { (e.target as HTMLImageElement).src = 'https://via.placeholder.com/400x300?text=Image+Not+Found' }}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
              </div>
              <div className="p-5">
                <p className="text-sm text-[#1C1917] dark:text-[#FAF8F5] mb-2 line-clamp-2" title={photo.caption}>
                  {photo.caption || 'No description provided.'}
                </p>
                <div className="text-[10px] uppercase font-bold tracking-wider text-[#78716C] dark:text-[#A8A29E] flex items-center">
                  <Camera className="w-3 h-3 mr-1" />
                  {new Date(photo.uploadedAt).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
