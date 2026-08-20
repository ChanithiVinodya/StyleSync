import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import App from './App'

describe('App', () => {
  it('renders the navigation links', () => {
    render(<App />)
    expect(screen.getByText('Designers')).toBeInTheDocument()
    expect(screen.getByText('Project Requests')).toBeInTheDocument()
    expect(screen.getByText('Quotes & Contracts')).toBeInTheDocument()
    expect(screen.getByText('Project Execution')).toBeInTheDocument()
  })
})
