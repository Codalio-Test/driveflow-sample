// DriveFlow data helpers.
//
// The approved prototype ships literal fixtures and fake handlers. These are
// the small utilities the wiring needs in their place: the organization-scoped
// path builder for the custom (non-CRUD) endpoints, blob downloads for the
// PDF/CSV services, offline draft caching and error text extraction.
import { api, useOrganization } from '@rhino-dev/rhino-react';

/** `/${org}/path` — custom endpoints are tenant-scoped but not model hooks. */
export const apiPath = (slug: string | null | undefined, path: string) => `/${slug}${path}`;

/** The current organization slug, reactive to login/logout. */
export const useOrgSlug = () => useOrganization();

export const money = (value: unknown) => `$${(Number(value ?? 0) || 0).toFixed(2)}`;

export const errorText = (err: any, fallback = 'Something went wrong') => {
  const data = err?.response?.data;
  if (typeof data?.message === 'string' && data.message) return data.message;
  const fieldErrors = data?.errors;
  if (fieldErrors && typeof fieldErrors === 'object') {
    const first = Object.values(fieldErrors).flat() as unknown[];
    if (first.length > 0) return String(first[0]);
  }
  return err?.message || fallback;
};

/** Downloads a backend-rendered PDF/CSV through the authenticated API client. */
export const downloadFile = async (path: string, filename: string) => {
  const response = await api.get(path, { responseType: 'blob' });
  const url = URL.createObjectURL(response.data as Blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
};

/** Offline-resilient draft cache for the tablet inspection screens. */
export const saveDraft = (key: string, value: unknown) => {
  try {
    localStorage.setItem(`driveflow-draft-${key}`, JSON.stringify(value));
  } catch {
    /* private mode — drafts are best effort */
  }
};
