import { apiClient } from '../../shared/api/client';
import { Milestone, Task, Material, TaskDependency, ProgressPhoto, TimelineEvent, ProjectAnalytics } from './types';

// Milestones
export const getMilestones = async (projectId: string) => {
  const res = await apiClient.get<Milestone[]>(`/milestones?projectId=${projectId}`);
  return res.data;
};
export const getMilestone = async (id: string) => {
  const res = await apiClient.get<Milestone>(`/milestones/${id}`);
  return res.data;
};
export const createMilestone = async (data: Partial<Milestone>) => {
  const res = await apiClient.post<Milestone>('/milestones', data);
  return res.data;
};
export const updateMilestone = async (id: string, data: Partial<Milestone>) => {
  const res = await apiClient.put<Milestone>(`/milestones/${id}`, data);
  return res.data;
};
export const deleteMilestone = async (id: string) => {
  const res = await apiClient.delete(`/milestones/${id}`);
  return res.data;
};

// Tasks
export const getTasks = async (milestoneId?: string) => {
  const query = milestoneId ? `?milestoneId=${milestoneId}` : '';
  const res = await apiClient.get<Task[]>(`/tasks${query}`);
  return res.data;
};
export const createTask = async (data: Partial<Task>) => {
  const res = await apiClient.post<Task>('/tasks', data);
  return res.data;
};
export const updateTaskStatus = async (id: string, status: string) => {
  const res = await apiClient.patch<Task>(`/tasks/${id}/status`, { status });
  return res.data;
};

// Dependencies
export const getTaskDependencies = async (taskId: string) => {
  const res = await apiClient.get<TaskDependency[]>(`/tasks/${taskId}/dependencies`);
  return res.data;
};
export const addTaskDependency = async (data: { taskId: string; prerequisiteTaskId: string }) => {
  const res = await apiClient.post<TaskDependency>('/tasks/dependencies', data);
  return res.data;
};

// Materials
export const getMaterials = async (projectId: string) => {
  const res = await apiClient.get<Material[]>(`/materials?projectId=${projectId}`);
  return res.data;
};
export const createMaterial = async (data: Partial<Material>) => {
  const res = await apiClient.post<Material>('/materials', data);
  return res.data;
};
export const updateMaterialStatus = async (id: string, status: string) => {
  const res = await apiClient.patch<Material>(`/materials/${id}/status`, JSON.stringify(status), {
    headers: { 'Content-Type': 'application/json' }
  });
  return res.data;
};

// Photos
export const getProgressPhotos = async (projectId: string) => {
  const res = await apiClient.get<ProgressPhoto[]>(`/progress-photos?projectId=${projectId}`);
  return res.data;
};
export const uploadProgressPhoto = async (data: FormData) => {
  const res = await apiClient.post<ProgressPhoto>('/progress-photos', data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
  return res.data;
};

// Timeline
export const getProjectTimeline = async (projectId: string) => {
  const res = await apiClient.get<TimelineEvent[]>(`/projects/${projectId}/timeline`);
  return res.data;
};

// Analytics
export const getProjectAnalytics = async (projectId: string) => {
  const res = await apiClient.get<ProjectAnalytics>(`/projects/${projectId}/analytics`);
  return res.data;
};
