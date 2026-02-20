'use client';

import { useState, useEffect } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || '';

type Tenant = { id: string; namespace: string; created_at: string };

export default function Dashboard() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [newId, setNewId] = useState('');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadTenants() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_URL}/api/tenants`);
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg = data?.error?.message ?? data?.error ?? (typeof data === 'string' ? data : res.statusText);
        throw new Error(msg);
      }
      setTenants(data.tenants || []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load tenants');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadTenants();
  }, []);

  async function createTenant(e: React.FormEvent) {
    e.preventDefault();
    if (!newId.trim()) return;
    setCreating(true);
    setError(null);
    try {
      const res = await fetch(`${API_URL}/api/tenant`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: newId.trim() }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg = data?.error?.message ?? data?.error ?? res.statusText;
        throw new Error(msg);
      }
      setNewId('');
      await loadTenants();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Create failed');
    } finally {
      setCreating(false);
    }
  }

  return (
    <div style={{ maxWidth: 720, margin: '0 auto', padding: 32 }}>
      <h1 style={{ fontSize: '1.5rem', fontWeight: 600, marginBottom: 8 }}>
        SaaS Core Panel
      </h1>
      <p style={{ color: 'var(--muted)', marginBottom: 24 }}>
        Phase 1 — Tenant provisioning
      </p>

      <form
        onSubmit={createTenant}
        style={{
          display: 'flex',
          gap: 12,
          marginBottom: 24,
          flexWrap: 'wrap',
        }}
      >
        <input
          type="text"
          value={newId}
          onChange={(e) => setNewId(e.target.value)}
          placeholder="Tenant ID (e.g. acme)"
          style={{
            padding: '10px 14px',
            borderRadius: 8,
            border: '1px solid var(--border)',
            background: 'var(--surface)',
            color: 'var(--text)',
            minWidth: 200,
          }}
        />
        <button
          type="submit"
          disabled={creating || !newId.trim()}
          style={{
            padding: '10px 20px',
            borderRadius: 8,
            border: 'none',
            background: 'var(--accent)',
            color: 'white',
            fontWeight: 500,
            cursor: creating ? 'not-allowed' : 'pointer',
          }}
        >
          {creating ? 'Creating…' : 'Create tenant'}
        </button>
      </form>

      {error && (
        <div
          style={{
            padding: 12,
            marginBottom: 24,
            borderRadius: 8,
            background: 'rgba(239, 68, 68, 0.15)',
            color: '#fca5a5',
          }}
        >
          {error}
        </div>
      )}

      <section>
        <h2 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: 12 }}>
          Tenants
        </h2>
        {loading ? (
          <p style={{ color: 'var(--muted)' }}>Loading…</p>
        ) : tenants.length === 0 ? (
          <p style={{ color: 'var(--muted)' }}>No tenants yet. Create one above.</p>
        ) : (
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {tenants.map((t) => (
              <li
                key={t.id}
                style={{
                  padding: '14px 16px',
                  marginBottom: 8,
                  borderRadius: 8,
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: 8,
                }}
              >
                <span style={{ fontWeight: 500 }}>{t.id}</span>
                <span style={{ color: 'var(--muted)', fontSize: '0.875rem' }}>
                  {t.namespace}
                </span>
                <a
                  href={`http://${t.id}.example.local`}
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{ fontSize: '0.875rem' }}
                >
                  {t.id}.example.local →
                </a>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
