import type { Quote, QuoteVersion, PagedResult, AgentBudgetScopeResponse } from "../types";
import type { QuoteFormPayload } from "../components/QuoteFormModal";
import type { AiDraftPayload } from "../components/AiDraftModal";
import { addMockContract } from "./contractsApi";

const RAW_API_BASE = import.meta.env?.VITE_API_BASE_URL ?? "http://localhost:5000";
const API_BASE = RAW_API_BASE.replace(/\/api\/?$/, "");

const STORAGE_KEY = "stylesync_quotes_store_v2";

// Quotation Engine calculations helper
export function computeQuotationBreakdown(items: { category?: string; quantity: number; unitCost: number }[]) {
  const materialsSubtotal = items
    .filter((i) => !i.category || ["materials", "furniture", "other", "carpentry", "textiles", "plumbing"].includes(i.category.toLowerCase()))
    .reduce((sum, i) => sum + (Number(i.quantity) || 0) * (Number(i.unitCost) || 0), 0);

  const laborSubtotal = items
    .filter((i) => i.category && ["labor", "painting", "electrical", "installation"].includes(i.category.toLowerCase()))
    .reduce((sum, i) => sum + (Number(i.quantity) || 0) * (Number(i.unitCost) || 0), 0);

  const directDesign = items
    .filter((i) => i.category && i.category.toLowerCase() === "design")
    .reduce((sum, i) => sum + (Number(i.quantity) || 0) * (Number(i.unitCost) || 0), 0);

  const designFee = directDesign > 0 ? directDesign : Math.round((materialsSubtotal + laborSubtotal) * 0.10 * 100) / 100;
  const subtotalBeforeContingencyAndTax = materialsSubtotal + laborSubtotal + designFee;
  const contingencyAmount = Math.round(subtotalBeforeContingencyAndTax * 0.05 * 100) / 100;
  const taxable = subtotalBeforeContingencyAndTax + contingencyAmount;
  const taxAmount = Math.round(taxable * 0.08 * 100) / 100;
  const totalCost = subtotalBeforeContingencyAndTax + contingencyAmount + taxAmount;

  return {
    materialsSubtotal,
    laborSubtotal,
    designFee,
    contingencyAmount,
    taxAmount,
    totalCost,
  };
}

export function getLocalQuotes(): Quote[] {
  const data = localStorage.getItem(STORAGE_KEY);
  if (data) {
    try { return JSON.parse(data); } catch { /* ignore */ }
  }

  const q100Items = [
    { id: "item-10", description: "Custom Walnut Executive Desk & Matching Credenza", category: "Furniture", quantity: 1, unitCost: 260000, lineTotal: 260000 },
    { id: "item-11", description: "Acoustic Slat Wood Wall Paneling & Insulation", category: "Materials", quantity: 1, unitCost: 140000, lineTotal: 140000 },
    { id: "item-12", description: "Architectural LED Linear Track Lighting System", category: "Labor", quantity: 4, unitCost: 30000, lineTotal: 120000 }
  ];
  const q100Calc = computeQuotationBreakdown(q100Items);

  const defaults: Quote[] = [
    {
      id: "q-100",
      projectRequestId: "00000000-0000-0000-0000-000000000001",
      designerId: "22222222-2222-2222-2222-222222222222",
      scopeSummary: "Executive Penthouse Interior Fitout & Custom Joinery",
      isAiGenerated: false,
      status: "Stage2Approved",
      totalCost: q100Calc.totalCost,
      notes: "Seismic-rated structural mounting. Includes 3-year commercial workmanship warranty.",
      items: q100Items,
      currentVersion: {
        id: "v-100-1",
        versionNumber: 1,
        authorId: "22222222-2222-2222-2222-222222222222",
        authorRole: "Designer",
        materialsSubtotal: q100Calc.materialsSubtotal,
        laborSubtotal: q100Calc.laborSubtotal,
        designFee: q100Calc.designFee,
        contingencyAmount: q100Calc.contingencyAmount,
        taxAmount: q100Calc.taxAmount,
        totalCost: q100Calc.totalCost,
        createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
        items: q100Items as any,
      },
      versions: [],
      createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
      updatedAt: new Date(Date.now() - 86400000).toISOString()
    },
    {
      id: "q-101",
      projectRequestId: "00000000-0000-0000-0000-000000000002",
      designerId: "44444444-4444-4444-4444-444444444444",
      scopeSummary: "Modern Minimalist Living Room Makeover & Custom Furniture",
      isAiGenerated: true,
      status: "Stage1Pending",
      totalCost: 450000.00,
      notes: "Paused AI proposal awaiting Stage 1 Admin governance.",
      items: [
        { id: "item-1", description: "Custom Oak Coffee Table & TV Unit", category: "Furniture", quantity: 1, unitCost: 220000, lineTotal: 220000 },
        { id: "item-2", description: "Ambient Recessed Lighting Installation", category: "Labor", quantity: 4, unitCost: 35000, lineTotal: 140000 },
        { id: "item-3", description: "Premium Linen Curtains & Hardware", category: "Materials", quantity: 2, unitCost: 45000, lineTotal: 90000 }
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
    if (body.errors && Array.isArray(body.errors)) {
      msg = `${msg}: ${body.errors.join(", ")}`;
    } else if (body.errors && typeof body.errors === "object") {
      const errorList = Object.values(body.errors).flat().join(" ");
      if (errorList) msg = msg ? `${msg}: ${errorList}` : errorList;
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

export async function getQuoteVersions(id: string): Promise<QuoteVersion[]> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}/versions`);
    return await handle<QuoteVersion[]>(res);
  } catch {
    const quote = await getQuote(id);
    return quote.versions || [];
  }
}

export async function createQuote(payload: QuoteFormPayload): Promise<Quote> {
  try {
    const requestId = payload.projectRequestId ?? crypto.randomUUID();
    const res = await fetch(`${API_BASE}/api/quotes/${requestId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<Quote>(res);
  } catch (err) {
    try {
      const res = await fetch(`${API_BASE}/api/quotes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      return await handle<Quote>(res);
    } catch {
      const quotes = getLocalQuotes();
      const calc = computeQuotationBreakdown(payload.items);
      const newQuote: Quote = {
        id: `q-${Date.now().toString().slice(-4)}`,
        projectRequestId: payload.projectRequestId ?? crypto.randomUUID(),
        designerId: payload.designerId ?? crypto.randomUUID(),
        scopeSummary: payload.scopeSummary,
        isAiGenerated: Boolean(payload.isAiGenerated),
        status: payload.isAiGenerated ? "Stage1Pending" : "Draft",
        totalCost: calc.totalCost,
        items: payload.items.map((it, idx) => ({ ...it, id: `item-${idx}-${Date.now()}`, lineTotal: it.quantity * it.unitCost })),
        currentVersion: {
          id: `v-1-${Date.now()}`,
          versionNumber: 1,
          authorId: payload.designerId ?? "des-1",
          authorRole: "Designer",
          materialsSubtotal: calc.materialsSubtotal,
          laborSubtotal: calc.laborSubtotal,
          designFee: calc.designFee,
          contingencyAmount: calc.contingencyAmount,
          taxAmount: calc.taxAmount,
          totalCost: calc.totalCost,
          notes: payload.notes,
          createdAt: new Date().toISOString(),
          items: payload.items.map((it, idx) => ({ ...it, id: `vitem-${idx}`, lineTotal: it.quantity * it.unitCost })),
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      quotes.unshift(newQuote);
      saveLocalQuotes(quotes);
      return newQuote;
    }
  }
}

export async function updateQuote(id: string, payload: QuoteFormPayload): Promise<Quote> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}/revise`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await handle<Quote>(res);
  } catch (err: any) {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) throw err;

    const calc = computeQuotationBreakdown(payload.items);
    const existing = quotes[index];
    const newVersionNumber = (existing.versions?.length ?? 1) + 1;

    const newVersion: QuoteVersion = {
      id: `v-${newVersionNumber}-${Date.now()}`,
      versionNumber: newVersionNumber,
      authorId: existing.designerId,
      authorRole: "Designer",
      materialsSubtotal: calc.materialsSubtotal,
      laborSubtotal: calc.laborSubtotal,
      designFee: calc.designFee,
      contingencyAmount: calc.contingencyAmount,
      taxAmount: calc.taxAmount,
      totalCost: calc.totalCost,
      notes: payload.notes,
      createdAt: new Date().toISOString(),
      items: payload.items.map((it, idx) => ({ ...it, id: `vitem-${idx}`, lineTotal: it.quantity * it.unitCost })),
    };

    const updated: Quote = {
      ...existing,
      scopeSummary: payload.scopeSummary,
      totalCost: calc.totalCost,
      items: payload.items.map((it, idx) => ({ ...it, id: it.id || `item-${idx}`, lineTotal: it.quantity * it.unitCost })),
      currentVersion: newVersion,
      versions: [newVersion, ...(existing.versions || [])],
      isAiGenerated: false,
      updatedAt: new Date().toISOString(),
    };
    quotes[index] = updated;
    saveLocalQuotes(quotes);
    return updated;
  }
}

export async function stage1Decision(id: string, action: "Release" | "SendForRevision" | "Reject", notes?: string): Promise<Quote> {
  try {
    const statusMap = {
      Release: "Stage1Released",
      SendForRevision: "Stage1RevisionRequested",
      Reject: "Stage1Rejected",
    };
    
    const res = await fetch(`${API_BASE}/api/quotes/${id}/status`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: statusMap[action], notes }),
    });
    return await handle<Quote>(res);
  } catch {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) throw new Error("Quote not found");

    const statusMap = {
      Release: "Stage1Released",
      SendForRevision: "Stage1RevisionRequested",
      Reject: "Stage1Rejected",
    };
    const updated = { ...quotes[index], status: statusMap[action], updatedAt: new Date().toISOString() };
    quotes[index] = updated;
    saveLocalQuotes(quotes);
    return updated;
  }
}

export async function stage2Decision(id: string, action: "Approve" | "RequestChanges" | "Reject", feedback?: string, clientId?: string): Promise<any> {
  try {
    if (action === "Approve") {
      const url = clientId ? `${API_BASE}/api/quotes/${id}/accept?clientId=${clientId}` : `${API_BASE}/api/quotes/${id}/accept`;
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
      });
      return await handle<any>(res);
    } else {
      const status = action === "RequestChanges" ? "Stage2ChangesRequested" : "Stage2Rejected";
      const res = await fetch(`${API_BASE}/api/quotes/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, notes: feedback }),
      });
      return await handle<Quote>(res);
    }
  } catch (err: any) {
    const quotes = getLocalQuotes();
    const index = quotes.findIndex((q) => q.id === id);
    if (index === -1) throw err;

    if (action === "Approve") {
      const updated = { ...quotes[index], status: "Stage2Approved", updatedAt: new Date().toISOString() };
      quotes[index] = updated;
      saveLocalQuotes(quotes);

      addMockContract({
        id: `cnt-${Date.now().toString().slice(-4)}`,
        quoteId: updated.id,
        projectRequestId: updated.projectRequestId,
        designerId: updated.designerId,
        clientId: clientId || "client-1",
        status: "PendingSignature",
        totalAmount: updated.totalCost,
        terms: `Official Contract for ${updated.scopeSummary}.`,
        termsSummary: updated.scopeSummary,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        quote: updated,
      });

      return updated;
    } else if (action === "RequestChanges") {
      const updated = { ...quotes[index], status: "Stage2ChangesRequested", updatedAt: new Date().toISOString() };
      quotes[index] = updated;
      saveLocalQuotes(quotes);
      return updated;
    } else {
      const updated = { ...quotes[index], status: "Stage2Rejected", updatedAt: new Date().toISOString() };
      quotes[index] = updated;
      saveLocalQuotes(quotes);
      return updated;
    }
  }
}

export async function acceptQuote(id: string, clientId?: string): Promise<any> {
  return stage2Decision(id, "Approve", undefined, clientId);
}

export async function exportQuote(id: string, format: "pdf" | "csv" = "pdf"): Promise<void> {
  try {
    const res = await fetch(`${API_BASE}/api/quotes/${id}/export?format=${format}`);
    if (!res.ok) throw new Error("Failed to download export file.");
    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Quote_${id.slice(0, 8)}.${format === "csv" ? "csv" : "html"}`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  } catch (err) {
    const quote = await getQuote(id);
    const content = `StyleSync Quotation Export\nQuote ID: ${quote.id}\nScope: ${quote.scopeSummary}\nTotal: LKR ${quote.totalCost.toLocaleString()}`;
    const blob = new Blob([content], { type: format === "csv" ? "text/csv" : "text/plain" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Quote_${id.slice(0, 8)}.${format}`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
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
      notes: "Fallback estimate — generated using deterministic category ratios.",
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
    const preview = await previewQuoteFromAgent(payload);
    return await createQuote({
      projectRequestId: payload.projectRequestId || crypto.randomUUID(),
      designerId: payload.designerId || crypto.randomUUID(),
      scopeSummary: preview.scopeSummary || `${payload.styleProfile} Scope`,
      notes: preview.notes || "",
      isAiGenerated: true,
      items: preview.items,
    });
  }
}