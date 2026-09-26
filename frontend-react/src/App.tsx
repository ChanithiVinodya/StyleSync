import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { AuthProvider } from './auth/AuthContext';
import { ProtectedRoute } from './auth/ProtectedRoute';

import LandingPage from './pages/LandingPage';
import { Login } from './pages/Login';
import { Register } from './pages/Register';
import { AdminLogin } from './pages/AdminLogin';
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AdminUsers } from './pages/admin/AdminUsers';
import { DesignerDashboard } from './pages/designer/DesignerDashboard';
import { ClientDashboard } from './pages/client/ClientDashboard';
import { Unauthorized } from './pages/Unauthorized';

import DesignersPage from './modules/designers/DesignersPage';
import ProjectRequestsPage from './modules/project-requests/ProjectRequestsPage';
import QuotesContractsPage from './modules/quotes-contracts/QuotesContractsPage';
import ProjectExecutionLayout from './modules/project-execution/pages/ProjectExecutionLayout';
import ProjectExecutionDashboard from './modules/project-execution/pages/ProjectExecutionDashboard';
import MilestoneList from './modules/project-execution/pages/MilestoneList';
import TaskList from './modules/project-execution/pages/TaskList';
import MaterialList from './modules/project-execution/pages/MaterialList';
import ProjectTimeline from './modules/project-execution/pages/ProjectTimeline';
import ProgressPhotos from './modules/project-execution/pages/ProgressPhotos';
import AnalyticsDashboard from './modules/project-execution/pages/AnalyticsDashboard';

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public Routes */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/admin" element={<AdminLogin />} />
            <Route path="/unauthorized" element={<Unauthorized />} />

            {/* Admin-only Routes */}
            <Route
              path="/admin/dashboard"
              element={
                <ProtectedRoute allowedRoles={['Admin']}>
                  <AdminDashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/users"
              element={
                <ProtectedRoute allowedRoles={['Admin']}>
                  <AdminUsers />
                </ProtectedRoute>
              }
            />

            {/* Designer-only Routes */}
            <Route
              path="/designer"
              element={
                <ProtectedRoute allowedRoles={['Designer']}>
                  <DesignerDashboard />
                </ProtectedRoute>
              }
            />

            {/* Client-only Routes */}
            <Route
              path="/client"
              element={
                <ProtectedRoute allowedRoles={['Client']}>
                  <ClientDashboard />
                </ProtectedRoute>
              }
            />

            {/* Feature Modules */}
            <Route path="/designers" element={<DesignersPage />} />
            <Route path="/project-requests" element={<ProjectRequestsPage />} />
            <Route path="/quotes-contracts" element={<QuotesContractsPage />} />
            
            {/* Project Execution Routing */}
            <Route path="/project-execution" element={<Navigate to="/projects/123e4567-e89b-12d3-a456-426614174000/execution" replace />} />
            <Route path="/projects/:projectId/execution" element={<ProjectExecutionLayout />}>
              <Route index element={<ProjectExecutionDashboard />} />
              <Route path="milestones" element={<MilestoneList />} />
              <Route path="tasks" element={<TaskList />} />
              <Route path="materials" element={<MaterialList />} />
              <Route path="timeline" element={<ProjectTimeline />} />
              <Route path="photos" element={<ProgressPhotos />} />
              <Route path="analytics" element={<AnalyticsDashboard />} />
            </Route>

            {/* Fallback */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}
