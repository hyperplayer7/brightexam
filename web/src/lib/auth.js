import { me } from "./api";

export async function getCurrentUser() {
  const response = await me();
  return response?.data || null;
}
