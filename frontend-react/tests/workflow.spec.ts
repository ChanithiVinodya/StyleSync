import { test, expect } from '@playwright/test';

test.describe('StyleSync Testing Workflow', () => {

  // =========================================================================
  // STEP 1: Client Login (UI Test)
  // =========================================================================
  test('Step 1: Client can successfully log in to the web app', async ({ page }) => {
    // Navigate to login page
    await page.goto('http://localhost:5173/login');

    // Fill in client credentials
    await page.getByPlaceholder('you@example.com').fill('hiruc1@gmail.com');
    await page.getByPlaceholder('••••••••••••').fill('12345678');

    // Submit the form
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Verify successful login by checking the URL redirect
    await expect(page).toHaveURL(/.*client/);
  });

  // =========================================================================
  // STEP 4: AI Graph Validation (API Test)
  // =========================================================================
  test('Step 4: System triggers AI graph and validates proposal', async ({ request }) => {
    // Create a dummy payload that mimics a client's project request
    const dummyWorkflowState = {
      project_request_id: 101,
      client_id: 1,
      room_type: "Living Room",
      room_size: 200.0,
      budget_min: 500000.0,
      budget_max: 2000000.0,
      description: "I want a cozy, modern living room with warm colors.",
      plan: []
    };

    // Make a direct POST request to the Python AI service (running on port 8000)
    // NOTE: This test will take ~10-15 seconds because it calls LLMs!
    const response = await request.post('http://127.0.0.1:8000/workflow/run', {
      data: dummyWorkflowState,
    });

    // 1. Verify the API successfully processed the request (HTTP 200 OK)
    expect(response.status()).toBe(200);

    const responseBody = await response.json();

    // Log the validation errors to the console so you can see WHY it failed!
    console.log('--- AI VALIDATION RESULT ---');
    console.log('Is Valid:', responseBody.validation_result?.is_valid);
    console.log('Errors:', responseBody.validation_result?.errors);
    console.log('----------------------------');

    // 2. Verify the AI graph populated the workflow plan
    expect(responseBody.plan.length).toBeGreaterThan(0);

    // 3. Expected: Validated proposal produced (Check style, scope, and validation results)
    expect(responseBody.style_profile).toBeDefined();
    expect(responseBody.project_scope).toBeDefined();
    expect(responseBody.validation_result).toBeDefined();

    // 4. Expected: The status is updated (either AwaitingClientApproval or RevisionRequested)
    expect(['AwaitingClientApproval', 'RevisionRequested']).toContain(responseBody.approval_status);
  });

  // =========================================================================
  // STEP 5: Workflow Pauses for Approval (API Test)
  // =========================================================================
  test('Step 5: Workflow pauses and status shows awaiting approval', async ({ request }) => {
    // We send a valid request that is likely to trigger the Human-in-the-Loop pause
    const dummyWorkflowState = {
      project_request_id: 102,
      client_id: 1,
      room_type: "Bedroom",
      room_size: 150.0,
      budget_min: 100000.0,
      budget_max: 5000000.0,
      description: "A simple, clean bedroom design.",
      plan: []
    };

    const response = await request.post('http://127.0.0.1:8000/workflow/run', {
      data: dummyWorkflowState,
    });

    expect(response.status()).toBe(200);
    const responseBody = await response.json();

    // The core of Step 5: The system MUST pause execution.
    // In LangGraph, this means it returns a status of either 'AwaitingClientApproval' 
    // (if it passed) or 'RevisionRequested' (if the rules rejected it).
    // It should NOT be "Completed" or "Pending" at this stage.
    expect(['AwaitingClientApproval', 'RevisionRequested']).toContain(responseBody.approval_status);
  });

  // =========================================================================
  // STEP 6: Admin Releases Proposal (UI Test)
  // =========================================================================
  test('Step 6: Administrator releases proposal in the React dashboard', async ({ page, request }) => {
    // 0. Setup: Create a real quote in the database using the API so the UI has something to show!
    const loginResponse = await request.post('http://localhost:5000/api/auth/login', {
      data: { email: 'admin@stylesync.com', password: 'Admin@StyleSync2026!' }
    });
    const { token } = await loginResponse.json();

    await request.post('http://localhost:5000/api/quotes', {
      headers: { 'Authorization': `Bearer ${token}` },
      data: {
        scopeSummary: "UI Test Quote for Release",
        isAiGenerated: true,
        items: [{ description: "Test", category: 0, quantity: 1, unitCost: 100 }]
      }
    });

    // 1. Log in to the UI as Administrator
    await page.goto('http://localhost:5173/admin');
    await page.getByPlaceholder('admin@stylesync.com').fill('admin@stylesync.com');
    await page.getByPlaceholder('••••••••••••').fill('Admin@StyleSync2026!');
    await page.getByRole('button', { name: 'Authenticate & Access Console' }).click();

    // Wait until login completes and redirects
    await page.waitForURL('**/admin/dashboard');

    // 2. Navigate to the Quotes & Contracts page
    await page.goto('http://localhost:5173/quotes-contracts');

    // 3. Find the first proposal that is awaiting approval and click "Release"
    // (Since we just created one, it will definitely be there!)

    // --> TAKES A SCREENSHOT RIGHT BEFORE CLICKING RELEASE <--
    await page.screenshot({ path: 'admin-release-screenshot.png', fullPage: true });

    await page.getByRole('button', { name: 'Release' }).first().click();

    // 4. Expected: Proposal released to client
    // Wait a brief moment for the UI to process
    await page.waitForTimeout(1000);
  });

  // =========================================================================
  // STEP 8: System Contract Creation (API Test)
  // =========================================================================
  test('Step 8: System creates exactly one contract linked to quote when accepted', async ({ request }) => {
    // 1. Authenticate with the backend API to get a JWT token
    const loginResponse = await request.post('http://localhost:5000/api/auth/login', {
      data: {
        email: 'admin@stylesync.com',
        password: 'Admin@StyleSync2026!'
      }
    });
    expect(loginResponse.status()).toBe(200);
    const loginData = await loginResponse.json();
    const token = loginData.token;

    // 2. Create a dummy Quote directly in the database so we have something to accept
    const createQuoteResponse = await request.post('http://localhost:5000/api/quotes', {
      headers: {
        'Authorization': `Bearer ${token}`
      },
      data: {
        scopeSummary: "Dummy Quote for Contract Generation",
        isAiGenerated: false,
        items: [{
          description: "Design Consultation",
          category: 0,
          quantity: 1,
          unitCost: 15000.0
        }]
      }
    });

    // Ensure quote creation was successful
    expect(createQuoteResponse.status()).toBe(201);
    const quoteData = await createQuoteResponse.json();
    const quoteId = quoteData.id;

    // 3. Client Action: Accept the quote (This triggers the Contract creation in the .NET API)
    const acceptResponse = await request.post(`http://localhost:5000/api/quotes/${quoteId}/accept`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    // 4. Expected: Exactly one contract is created and returned
    expect(acceptResponse.status()).toBe(201); // 201 Created!
    const contractData = await acceptResponse.json();

    // Verify it is a valid contract linked to our specific quote
    expect(contractData.id).toBeDefined();
    expect(contractData.quoteId).toBe(quoteId);
    expect(contractData.status).toBe('PendingSignature'); // A newly created contract is pending signature!
  });

});
