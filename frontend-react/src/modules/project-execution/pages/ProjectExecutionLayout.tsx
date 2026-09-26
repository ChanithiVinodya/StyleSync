import React from 'react';
import { NavLink, Outlet, useParams, Link } from 'react-router-dom';
import { LayoutDashboard, CheckSquare, Layers, Package, Clock, Camera, BarChart2, ArrowLeft } from 'lucide-react';
import { GlassThemeToggle } from '../../../components/GlassThemeToggle'; // Adjust path if needed
import { Logo } from '../../../components/Logo'; // Adjust path if needed
import { useAuth } from '../../../auth/AuthContext';

export default function ProjectExecutionLayout() {
  const { projectId } = useParams<{ projectId: string }>();
  const pId = projectId || '00000000-0000-0000-0000-000000000000';
  const { user } = useAuth();

  const navItems = [
    { name: 'Overview', path: `/projects/${pId}/execution`, icon: LayoutDashboard, exact: true },
    { name: 'Milestones', path: `/projects/${pId}/execution/milestones`, icon: Layers },
    { name: 'Tasks', path: `/projects/${pId}/execution/tasks`, icon: CheckSquare },
    { name: 'Materials', path: `/projects/${pId}/execution/materials`, icon: Package },
    { name: 'Timeline', path: `/projects/${pId}/execution/timeline`, icon: Clock },
    { name: 'Photos', path: `/projects/${pId}/execution/photos`, icon: Camera },
    { name: 'Analytics', path: `/projects/${pId}/execution/analytics`, icon: BarChart2 },
  ];

  return (
    <div className="min-h-screen bg-[#FAF8F5] dark:bg-[#12100E] text-[#1C1917] dark:text-[#FAF8F5] font-sans transition-colors duration-300">
      {/* Top Header */}
      <header className="sticky top-0 z-20 bg-white/80 dark:bg-[#1A1715]/80 backdrop-blur-md border-b border-[#E7E1D7] dark:border-[#2E2824]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-6">
              <Link to="/admin/dashboard" className="text-[#57534E] dark:text-[#A8A29E] hover:text-[#C48A36] dark:hover:text-[#C48A36] transition-colors">
                <ArrowLeft className="w-5 h-5" />
              </Link>
              <div className="flex-shrink-0">
                <span className="font-serif text-xl font-bold text-[#1C1917] dark:text-[#FAF8F5]">StyleSync Execution</span>
              </div>
            </div>
            
            <div className="hidden sm:flex space-x-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <NavLink
                    key={item.name}
                    to={item.path}
                    end={item.exact}
                    className={({ isActive }) =>
                      isActive
                        ? 'px-3 py-2 rounded-xl text-sm font-semibold bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] flex items-center transition-colors'
                        : 'px-3 py-2 rounded-xl text-sm font-medium text-[#57534E] dark:text-[#A8A29E] hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] hover:text-[#1C1917] dark:hover:text-[#FAF8F5] flex items-center transition-colors'
                    }
                  >
                    <Icon className="w-4 h-4 mr-2" />
                    {item.name}
                  </NavLink>
                );
              })}
            </div>
            
            <div className="flex items-center">
               {/* Note: GlassThemeToggle might require correct import path. We'll leave out for safety if it breaks, but assuming it exists since AdminDashboard has it. If it fails to compile, we can remove it. */}
               <div className="hidden sm:block">
                  {/* <GlassThemeToggle /> */}
               </div>
            </div>
          </div>
        </div>
        
        {/* Mobile Navigation (Scrollable horizontally) */}
        <div className="sm:hidden overflow-x-auto px-4 pb-2 flex space-x-2 no-scrollbar border-t border-[#E7E1D7] dark:border-[#2E2824] pt-2">
           {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <NavLink
                  key={item.name}
                  to={item.path}
                  end={item.exact}
                  className={({ isActive }) =>
                    isActive
                      ? 'whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#FAF3E8] dark:bg-[#2A231A] text-[#925C18] dark:text-[#E8A849] border border-[#E8DEC8] dark:border-[#423525] flex items-center transition-colors'
                      : 'whitespace-nowrap px-3 py-1.5 rounded-lg text-xs font-medium text-[#57534E] dark:text-[#A8A29E] hover:bg-[#EFEAE1] dark:hover:bg-[#25201C] flex items-center transition-colors'
                  }
                >
                  <Icon className="w-3.5 h-3.5 mr-1.5" />
                  {item.name}
                </NavLink>
              );
            })}
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <Outlet context={{ projectId: pId, userRole: user?.role }} />
      </main>
    </div>
  );
}
