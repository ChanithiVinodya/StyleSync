import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import DesignersPage from './modules/designers/DesignersPage'
import ProjectRequestsPage from './modules/project-requests/ProjectRequestsPage'
import QuotesContractsPage from './modules/quotes-contracts/QuotesContractsPage'
import ProjectExecutionPage from './modules/project-execution/ProjectExecutionPage'

export default function App() {
  return (
    <BrowserRouter>
      <nav style={{ display: 'flex', gap: '1rem', padding: '1rem', borderBottom: '1px solid #ddd' }}>
        <Link to="/designers">Designers</Link>
        <Link to="/project-requests">Project Requests</Link>
        <Link to="/quotes-contracts">Quotes & Contracts</Link>
        <Link to="/project-execution">Project Execution</Link>
      </nav>

      <main style={{ padding: '1.5rem' }}>
        <Routes>
          <Route path="/" element={<h1>StyleSync</h1>} />
          {/* Student 1 owns this route */}
          <Route path="/designers" element={<DesignersPage />} />
          {/* Student 2 owns this route */}
          <Route path="/project-requests" element={<ProjectRequestsPage />} />
          {/* Student 3 owns this route */}
          <Route path="/quotes-contracts" element={<QuotesContractsPage />} />
          {/* Student 4 owns this route */}
          <Route path="/project-execution" element={<ProjectExecutionPage />} />
        </Routes>
      </main>
    </BrowserRouter>
  )
}
