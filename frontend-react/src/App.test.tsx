import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import App from './App'

describe('App', () => {
  it('renders the landing page headline and branding', () => {
    render(<App />)
    expect(screen.getAllByText(/StyleSync/i).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Get Started/i).length).toBeGreaterThan(0)
  })
})
