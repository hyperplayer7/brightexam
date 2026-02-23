import { me } from "./api";

export async function getCurrentUser() {
  const response = await me();
  return response?.data || null;
}

export async function requireCurrentUser() {
  return getCurrentUser();
}

export function isUnauthorizedError(error) {
  return error?.status === 401;
}

export function isForbiddenError(error) {
  return error?.status === 403;
}
