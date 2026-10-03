import type { Quote, PagedResult, Contract, AgentBudgetScopeResponse } from "../types";
import type { QuoteFormPayload } from "../components/QuoteFormModal";
import type { AiDraftPayload } from "../components/AiDraftModal";
import { addMockContract } from "./contractsApi";

const RAW_API_BASE = import.meta.env?.VITE_API_BASE_URL ?? "http://localhost:5000";
const API_BASE = RAW_API_BASE.replace(/\/api\/?$/, "");

// Fallback in-memory quote store
const STORAGE_KEY = "stylesync_quotes_store";

function getLocalQuotes(): Quote[] {
  const data = localStorage.getItem(STORAGE_KEY);
  if (data) {
    try { return JSON.parse(data); } catch { /* ignore */ }
  }
  const defaults: Quote[] = [
    {
      id: "q-101",
      projectRequestId: "req-001",
      designerId: "des-001",
      scopeSummary: "Modern Minimalist Living Room Makeover & Custom Furniture",
      isAiGenerated: true,
      status: "ClientReview",
      totalCost: 450000.00,
      items: [
        { id: "item-1", description: "Custom Oak Coffee Table & TV Unit", category: "Furniture", quantity: 1, unitCost: 220000, totalCost: 220000 },
        { id: "item-2", description: "Ambient Recessed Lighting Installation", category: "Electrical", quantity: 4, unitCost: 35000, totalCost: 140000 },
        { id: "item-3", description: "Premium Linen Curtains & Hardware", category: "Textiles", quantity: 2, unitCost: 45000, totalCost: 90000 }
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: "q-102",
      projectRequestId: "req-002",
      designerId: "des-002",
      scopeSummary: "Scandinavian Bedroom Refresh & Built-in Wardrobes",
      isAiGenerated: false,
      status: "Draft",
      totalCost: 280000.00,
      items: [
        { id: "item-4", description: "Built-in Wardrobe Sliding Panels", category: "Carpentry", quantity: 1, unitCost: 200000, totalCost: 200000 },
        { id: "item-5", description: "Matte Wall Paint & Prep Work", category: "Painting", quantity: 1, unitCost: 80000, totalCost: 80000 }
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
  ];
  localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
  return defaults;
}

function saveLocalQuotes(quotes: Quote[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(quotes));
}

async function handle<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    let msg = body.message || body.title;
    if (body.errors && typeof body.errors === "object") {
      const errorList = Object.values(body.errors).flat().join(" ");
      if (errorList) {
        msg = msg ? `${msg}: ${errorList}` : errorList;
      }
    }
    throw new Error(msg || `Request failed with status ${res.status}`);
  }
  return res.status === 204 ? (null as T) : res.json();
}

interface ListQuotesParams {
  status?: string;
  designerId?: string;
  projectRequestId?: string;
  search?: string;
  page?: number;
  pageSize?: number;
  sort?: string;
}

export async function listQuotes({
  status,
  search,
  page = 1,
  pageSize = 20,
}: ListQuotesParams = {}): Promise<PagedResult<Quote>> {
  try {
    const params = new URLSearchParams();
    if (status) params.set("status", status);
    if (search) params.set("search", search);
    params.set("page", String(page));
    params.set("pageSize", String(pageSize));

    const res = await fetch(`${API_BASE}/api/quotes?${params.toString()}`);
    return await handle<PagedResult<Quote>>(res);
  } catch (err) {
    // Fallback to local store if backend API is not yet running
    let quotes = getLocalQuotes();
    if (status) {
      quotes = quotes.filter((q) => {
        const s = typeof q.status === "string" ? q.status : (q.status as any)?.value ?? (q.status as any)?.name ?? "";
        return s.toLowerCase() === status.toLowerCase();
      });
    }
    if (search) {
      quotes = quotes.filter((q) => q.scopeSummary.toLowerCase().includes(search.toLowerCase()));
    }

    const start = (page - 1) * pageSize;
    const paginated = quotes.slice(start, start + pageSize);

    return {
      items: paginated,
      totalCount: quotes.length,
      page,
      pageSize,
    };
  }
}

export async function getQuote(id: string): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}`);
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const q = quotes.find((x) => x.id === id);
    if (!q) throw new Error("Quote not found");
    return q;
  }
}

export async function createQuote(payload: QuoteFormPayload): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const totalCost = payload.items.reduce((sum, item) => sum + item.quantity * item.unitCost, 0);
    const newQuote: Quote = {
      id: `q-${Date.now().toString().slice(-4)}`,
      projectRequestId: payload.projectRequestId ?? crypto.randomUUID(),
      designerId: payload.designerId ?? crypto.randomUUID(),
      scopeSummary: payload.scopeSummary,
      isAiGenerated: false,
      status: "Draft",
      totalCost,
      items: payload.items.map((it, idx) => ({ ...it, id: `item-${idx}-${Date.now()}`, totalCost: it.quantity * it.unitCost })),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    quotes.unshift(newQuote);
    saveLocalQuotes(quotes);
    return newQuote;
  }
}

export async function updateQuote(id: string, payload: QuoteFormPayload): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) throw new Error("Quote not found");

    const totalCost = payload.items.reduce((sum, item) => sum + item.quantity * item.unitCost, 0);
    const updated: Quote = {
      ...quotes[index],
      scopeSummary: payload.scopeSummary,
      totalCost,
      items: payload.items.map((it, idx) => ({ ...it, id: it.id || `item-${idx}`, totalCost: it.quantity * it.unitCost })),
      updatedAt: new Date().toISOString(),
    };
    quotes[index] = updated;
    saveLocalQuotes(quotes);
    return updated;
  }
}

export async function updateQuoteStatus(id: string, status: string): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    });
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) throw new Error("Quote not found");

    const updated = { ...quotes[index], status, updatedAt: new Date().toISOString() };
    quotes[index] = updated;
    saveLocalQuotes(quotes);
    return updated;
  }
}

export async function acceptQuote(id: string, clientId?: string): Promise<any> {
  try {
    const url = clientId 
      ? `${API_BASE}/api/quotes/${id}/accept?clientId=${encodeURIComponent(clientId)}`
      : `${API_BASE}/api/quotes/${id}/accept`;
    const res = await fetch(url, {
      method: "POST",
    });
    return await handle<any>(res);
  } catch (err: any) {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) {
      throw err instanceof Error ? err : new Error("Failed to accept quote.");
    }

    const updated = { ...quotes[index], status: "Accepted", updatedAt: new Date().toISOString() };
    quotes[index] = updated;
    saveLocalQuotes(quotes);

    // Auto-create contract on quote acceptance
    addMockContract({
      id: `cnt-${Date.now().toString().slice(-4)}`,
      quoteId: updated.id,
      projectRequestId: updated.projectRequestId,
      designerId: updated.designerId,
      clientId: clientId || "client-default",
      status: "Draft",
      totalAmount: updated.totalCost,
      terms: `Official Contract for ${updated.scopeSummary}. 50% upfront, 50% upon final signoff.`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    return updated;
  }
}

export async function deleteQuote(id: string): Promise<null> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}`, { method: "DELETE" });
    return await handle<null>(res);
  } catch {
    let quotes = getLocalQuotes();
    quotes = quotes.filter((q) => q.id !== id);
    saveLocalQuotes(quotes);
    return null;
  }
}

export async function previewQuoteFromAgent(payload: AiDraftPayload): Promise<AgentBudgetScopeResponse> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/draft-preview`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<AgentBudgetScopeResponse>(res);
  } catch {
    // Deterministic fallback mirroring budget_scope_agent.py
    const targetBudget = (payload.budgetMin + payload.budgetMax) / 2 || payload.budgetMin || (payload.roomSizeSqft * 800);
    const split = [
      { category: "Design", pct: 0.10, desc: `Design — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} concept & planning` },
      { category: "Labor", pct: 0.30, desc: `Labor — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} installation & craftsmanship` },
      { category: "Materials", pct: 0.35, desc: `Materials — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} fixtures & finishes` },
      { category: "Furniture", pct: 0.25, desc: `Furniture — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} curated styling` },
    ];
    const items = split.map((s) => ({
      description: s.desc,
      category: s.category,
      quantity: 1,
      unitCost: Math.round((targetBudget * s.pct) / 100) * 100,
    }));
    const total = items.reduce((sum, it) => sum + it.unitCost * it.quantity, 0);
    return {
      scopeSummary: `${payload.styleProfile} ${payload.roomType.toLowerCase()} refresh, ${payload.roomSizeSqft.toFixed(0)} sq ft.`,
      items,
      notes: "Fallback estimate — generated using deterministic category ratios (Design 10%, Labor 30%, Materials 35%, Furniture 25%).",
      estimatedTotal: total,
      withinBudget: payload.budgetMax > 0 ? (total >= payload.budgetMin && total <= payload.budgetMax) : true,
      source: "fallback",
    };
  }
}

export async function draftQuoteFromAgent(payload: AiDraftPayload): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/draft-from-agent`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const targetBudget = (payload.budgetMin + payload.budgetMax) / 2 || payload.budgetMin || (payload.roomSizeSqft * 800);
    const split = [
      { category: "Design", pct: 0.10, desc: `Design — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} work` },
      { category: "Labor", pct: 0.30, desc: `Labor — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} work` },
      { category: "Materials", pct: 0.35, desc: `Materials — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} work` },
      { category: "Furniture", pct: 0.25, desc: `Furniture — ${payload.styleProfile.toLowerCase()} ${payload.roomType.toLowerCase()} work` },
    ];
    const items = split.map((s, idx) => {
      const unitCost = Math.round((targetBudget * s.pct) / 100) * 100;
      return {
        id: `ai-item-${idx}-${Date.now()}`,
        description: s.desc,
        category: s.category,
        quantity: 1,
        unitCost,
        totalCost: unitCost,
      };
    });
    const totalCost = items.reduce((sum, it) => sum + it.totalCost, 0);

    const newQuote: Quote = {
      id: `q-ai-${Date.now().toString().slice(-4)}`,
      projectRequestId: payload.projectRequestId || crypto.randomUUID(),
      designerId: payload.designerId || crypto.randomUUID(),
      scopeSummary: `${payload.styleProfile} ${payload.roomType.toLowerCase()} refresh, ${payload.roomSizeSqft.toFixed(0)} sq ft.`,
      notes: "Fallback estimate — generated without a live LLM call, split across standard category ratios. (agent source: fallback)",
      isAiGenerated: true,
      status: "Draft",
      totalCost,
      items,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    quotes.unshift(newQuote);
    saveLocalQuotes(quotes);
    return newQuote;
  }
}