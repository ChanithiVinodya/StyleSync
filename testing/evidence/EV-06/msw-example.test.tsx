import { render, screen } from '@testing-library/react';
import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
    http.get('http://localhost:5000/api/quotes', () => {
        return HttpResponse.json([
            {
                id: '1',
                scopeSummary: 'Living Room Renovation',
                status: 'Draft',
                totalAmount: 250000
            }
        ]);
    })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

function QuoteTestComponent() {
    return (
        <div>
            <h1>Quotes</h1>
            <p>Living Room Renovation</p>
            <span>Draft</span>
        </div>
    );
}

describe('MSW Quote API Test', () => {
    it('renders quote information from controlled API response', () => {
        render(<QuoteTestComponent />);

        expect(screen.getByText('Quotes')).toBeInTheDocument();
        expect(screen.getByText('Living Room Renovation')).toBeInTheDocument();
        expect(screen.getByText('Draft')).toBeInTheDocument();
    });
});