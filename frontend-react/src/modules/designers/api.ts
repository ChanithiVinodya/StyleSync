import { apiClient } from '../../shared/api/client';

export interface DesignerProfile {
  id: string;
  userId: string;
  name: string;
  specialty: string;
  location: string;
  matchRate: number;
  rating: number;
  reviews: number;
  about: string;
  avatarUrl: string;
  coverUrl: string;
}

export interface CreateDesignerProfile {
  userId: string;
  name: string;
  specialty: string;
  location: string;
  about: string;
  avatarUrl: string;
  coverUrl: string;
}

export interface UpdateDesignerProfile {
  name: string;
  specialty: string;
  location: string;
  about: string;
  avatarUrl: string;
  coverUrl: string;
}

export const getDesigners = () => apiClient.get<DesignerProfile[]>('/designerprofiles');
export const getDesigner = (id: string) => apiClient.get<DesignerProfile>(`/designerprofiles/${id}`);
export const createDesigner = (data: CreateDesignerProfile) => apiClient.post<DesignerProfile>('/designerprofiles', data);
export const updateDesigner = (id: string, data: UpdateDesignerProfile) => apiClient.put<DesignerProfile>(`/designerprofiles/${id}`, data);
export const deleteDesigner = (id: string) => apiClient.delete(`/designerprofiles/${id}`);
