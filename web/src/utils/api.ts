export async function withLoading(setLoading, asyncFn) {
  setLoading(true);
  try {
    return await asyncFn();
  } finally {
    setLoading(false);
  }
}
