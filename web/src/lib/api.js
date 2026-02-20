const API_BASE_URL = "http://localhost:3000";

async function request(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  const hasBody = options.body !== undefined && options.body !== null;

  if (hasBody && !headers["Content-Type"]) {
    headers["Content-Type"] = "application/json";
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    credentials: "include",
    headers
  });

  if (!response.ok) {
    const bodyText = await response.text();
    const message = `API request failed (${response.status}): ${bodyText || response.statusText}`;
    const error = new Error(message);
    error.status = response.status;
    error.body = bodyText;
    throw error;
  }

  if (response.status === 204) {
    return null;
  }

  const contentType = response.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return response.json();
  }

  return response.text();
}

export function login(email, password) {
  return request("/api/login", {
    method: "POST",
    body: JSON.stringify({ email, password })
  });
}

export function logout() {
  return request("/api/logout", {
    method: "POST"
  });
}

export function me() {
  return request("/api/me");
}

export function listExpenses(params = {}) {
  const query = new URLSearchParams();

  if (params.page !== undefined && params.page !== null && params.page !== "") {
    query.set("page", String(params.page));
  }

  if (params.status !== undefined && params.status !== null && params.status !== "" && params.status !== "all") {
    query.set("status", String(params.status));
  }

  const suffix = query.toString() ? `?${query.toString()}` : "";
  return request(`/api/expenses${suffix}`);
}

export function getExpense(id) {
  return request(`/api/expenses/${id}`);
}

export function createExpense(payload) {
  return request("/api/expenses", {
    method: "POST",
    body: JSON.stringify({ expense: payload })
  });
}

export function updateExpense(id, payload) {
  return request(`/api/expenses/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ expense: payload })
  });
}

export function deleteExpense(id) {
  return request(`/api/expenses/${id}`, {
    method: "DELETE"
  });
}

export function submitExpense(id) {
  return request(`/api/expenses/${id}/submit`, {
    method: "POST"
  });
}

export function approveExpense(id) {
  return request(`/api/expenses/${id}/approve`, {
    method: "POST"
  });
}

export function rejectExpense(id, rejection_reason) {
  return request(`/api/expenses/${id}/reject`, {
    method: "POST",
    body: JSON.stringify({ rejection_reason })
  });
}
