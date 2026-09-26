export type MilestoneStatus = 'NotStarted' | 'InProgress' | 'Delayed' | 'Completed';
export type TaskStatus = 'NotStarted' | 'InProgress' | 'Delayed' | 'Completed';
export type MaterialStatus = 'Required' | 'Ordered' | 'Delivered';

export interface Milestone {
  milestoneId: string;
  projectId: string;
  name: string;
  description: string;
  startDate: string;
  dueDate: string;
  status: MilestoneStatus;
  createdAt: string;
  updatedAt: string;
}

export interface Task {
  taskId: string;
  milestoneId: string;
  name: string;
  description: string;
  startDate: string;
  dueDate: string;
  status: TaskStatus;
  cascadedDelay: number;
}

export interface Material {
  materialId: string;
  projectId: string;
  milestoneId?: string;
  taskId?: string;
  name: string;
  description: string;
  quantity: number;
  unit: string;
  requiredDate?: string;
  orderedDate?: string;
  deliveredDate?: string;
  status: MaterialStatus;
}

export interface TaskDependency {
  dependencyId: string;
  taskId: string;
  prerequisiteTaskId: string;
}

export interface ProgressPhoto {
  photoId: string;
  projectId: string;
  milestoneId?: string;
  taskId?: string;
  fileName: string;
  fileUrl: string;
  contentType: string;
  fileSize: number;
  caption?: string;
  uploadedBy: string;
  uploadedAt: string;
}

export interface TimelineEvent {
  eventId: string;
  projectId: string;
  eventType: string;
  title: string;
  description?: string;
  entityType: string;
  entityId: string;
  timestamp: string;
  createdBy?: string;
}

export interface ProjectAnalytics {
  projectId: string;
  projectName: string;
  overallProgress: number;
  tasks: {
    total: number;
    completed: number;
    inProgress: number;
    notStarted: number;
    delayed: number;
    completionPercentage: number;
  };
  milestones: {
    total: number;
    completed: number;
    inProgress: number;
    notStarted: number;
    delayed: number;
    completionPercentage: number;
  };
  materials: {
    total: number;
    required: number;
    ordered: number;
    delivered: number;
    completionPercentage: number;
  };
  materialGated: {
    blockedMilestones: number;
  };
  delays: {
    delayedTasks: number;
    totalDelayDays: number;
    averageDelayDays: number;
    maximumDelayDays: number;
  };
  progressPhotos: {
    total: number;
  };
  activity: {
    totalEvents: number;
    photosUploaded: number;
    materialsDelivered: number;
    tasksCompleted: number;
    milestonesCompleted: number;
  };
}
