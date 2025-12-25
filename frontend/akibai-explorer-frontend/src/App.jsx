
import { useEffect, useState } from 'react';
import './App.css';

const themes = {
  green: {
    '--color-primary': '#34A853',
    '--color-play-green': '#34A853',
    '--color-play-blue': '#4285F4',
    '--color-play-yellow': '#FBBC04',
    '--color-play-red': '#EA4335',
    '--color-bg': '#FFFFFF',
  },
  blue: {
    '--color-primary': '#4285F4',
    '--color-play-green': '#34A853',
    '--color-play-blue': '#4285F4',
    '--color-play-yellow': '#FBBC04',
    '--color-play-red': '#EA4335',
    '--color-bg': '#F8FAFF',
  },
  yellow: {
    '--color-primary': '#FBBC04',
    '--color-play-green': '#34A853',
    '--color-play-blue': '#4285F4',
    '--color-play-yellow': '#FBBC04',
    '--color-play-red': '#EA4335',
    '--color-bg': '#FFFBEA',
  },
  gray: {
    '--color-primary': '#5F6368',
    '--color-play-green': '#5F6368',
    '--color-play-blue': '#B0BEC5',
    '--color-play-yellow': '#CFD8DC',
    '--color-play-red': '#B0BEC5',
    '--color-bg': '#F5F5F5',
  },
};

function App() {
  const [results, setResults] = useState([]);
  const [page, setPage] = useState(1);
  const [limit] = useState(20);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [theme, setTheme] = useState('green');
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');

  useEffect(() => {
    // Apply theme CSS variables
    const root = document.documentElement;
    Object.entries(themes[theme]).forEach(([k, v]) => root.style.setProperty(k, v));
  }, [theme]);

  useEffect(() => {
    setLoading(true);
    setError(null);
    let url = `/api/github/results?page=${page}&limit=${limit}`;
    fetch(url)
      .then(async (res) => {
        if (!res.ok) {
          const text = await res.text();
          throw new Error(`Error ${res.status}: ${text}`);
        }
        return res.json();
      })
      .then(data => {
        setResults(data.results || []);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, [page, limit, search]);

  return (
    <div style={{ maxWidth: 1200, margin: '2rem auto', fontFamily: 'var(--font-body)', background: 'var(--color-bg)', borderRadius: 24, boxShadow: '0 4px 32px 0 rgba(60,64,67,0.08)', padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <span className="app-page-title" style={{ fontSize: 32, fontWeight: 700, color: 'var(--color-play-green)', letterSpacing: 1 }}>Akibai Explorer</span>
        <select className="theme-dropdown" value={theme} onChange={e => setTheme(e.target.value)} style={{ borderRadius: 8, padding: '0.5rem 1rem', border: '1px solid var(--color-border-subtle)', background: 'var(--color-bg-alt)', color: 'var(--color-text-primary)', fontWeight: 500 }}>
          <option value="green">Play Green (Default)</option>
          <option value="blue">Soft Blue</option>
          <option value="yellow">Soft Yellow</option>
          <option value="gray">Soft Gray</option>
        </select>
      </div>
      <form
        onSubmit={async e => {
          e.preventDefault();
          if (!searchInput.trim()) return;
          setLoading(true);
          setError(null);
          try {
            // POST search to backend, save/seed repo, get result
            const res = await fetch('/api/github/search', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ queries: [searchInput.trim()] })
            });
            if (!res.ok) {
              const text = await res.text();
              throw new Error(`Error ${res.status}: ${text}`);
            }
            const data = await res.json();
            // Insert searched repo at top, then reload paginated results
            setResults(r => [data.results[0], ...r]);
            setSearch(searchInput.trim());
            setPage(1);
          } catch (err) {
            setError(err.message);
          } finally {
            setLoading(false);
          }
        }}
        style={{ display: 'flex', gap: 12, marginBottom: 32, alignItems: 'center', background: 'var(--color-bg-alt)', borderRadius: 12, padding: '1rem 1.5rem', boxShadow: '0 2px 8px 0 rgba(60,64,67,0.04)' }}>
        <input
          type="text"
          value={searchInput}
          onChange={e => setSearchInput(e.target.value)}
          placeholder="Search GitHub repositories..."
          style={{ flex: 1, fontSize: 18, border: 'none', outline: 'none', background: 'transparent', color: 'var(--color-text-primary)' }}
        />
        <button type="submit" style={{ background: 'var(--color-primary)', color: 'var(--color-text-on-primary)', border: 'none', borderRadius: 24, fontWeight: 600, fontSize: 18, padding: '0.75rem 2.5rem', boxShadow: '0 2px 8px 0 rgba(52,168,83,0.12)', cursor: 'pointer', transition: 'box-shadow 0.2s', position: 'relative', overflow: 'hidden' }}>
          <span style={{ position: 'relative', zIndex: 2 }}>Search</span>
        </button>
      </form>
      <div style={{ overflowX: 'auto', background: 'var(--color-surface)', borderRadius: 16, boxShadow: '0 2px 12px 0 rgba(60,64,67,0.06)' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 17 }}>
          <thead>
            <tr style={{ background: 'var(--color-bg-alt)' }}>
              <th style={{ padding: '1rem', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600, borderBottom: '2px solid var(--color-divider)' }}>#</th>
              <th style={{ padding: '1rem', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600, borderBottom: '2px solid var(--color-divider)' }}>Repo Number</th>
              <th style={{ padding: '1rem', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600, borderBottom: '2px solid var(--color-divider)' }}>URL</th>
              <th style={{ padding: '1rem', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600, borderBottom: '2px solid var(--color-divider)' }}>Name</th>
              <th style={{ padding: '1rem', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600, borderBottom: '2px solid var(--color-divider)' }}>Description</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>Loading...</td></tr>
            )}
            {error && (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '2rem', color: 'red' }}>Error: {error}</td></tr>
            )}
            {!loading && !error && results.length === 0 && (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>No results found.</td></tr>
            )}
            {results.map((r, i) => (
              <tr key={r.id || r.url} style={{ background: i % 2 === 0 ? 'var(--color-bg)' : 'var(--color-bg-alt)', transition: 'background 0.2s' }}>
                <td style={{ padding: '1rem', fontWeight: 500, color: 'var(--color-play-green)' }}>{(page - 1) * limit + i + 1}</td>
                <td style={{ padding: '1rem', color: 'var(--color-text-primary)' }}>{r.id || ''}</td>
                <td style={{ padding: '1rem' }}>
                  <a href={r.url} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--color-play-blue)', textDecoration: 'underline', fontWeight: 500 }}>{r.url}</a>
                </td>
                <td style={{ padding: '1rem', color: 'var(--color-text-primary)', fontWeight: 500 }}>{r.name || ''}</td>
                <td style={{ padding: '1rem', color: 'var(--color-text-secondary)' }}>{r.description || ''}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div style={{ marginTop: 32, display: 'flex', justifyContent: 'center', gap: 16 }}>
        <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} style={{ padding: '0.5rem 1.5rem', borderRadius: 8, border: 'none', background: 'var(--color-primary)', color: 'var(--color-text-on-primary)', fontWeight: 500, fontSize: 16, cursor: 'pointer', opacity: page === 1 ? 0.5 : 1 }}>Previous</button>
        <span style={{ fontSize: 18, fontWeight: 500, color: 'var(--color-text-primary)' }}>Page {page}</span>
        <button onClick={() => setPage(p => p + 1)} disabled={results.length < limit} style={{ padding: '0.5rem 1.5rem', borderRadius: 8, border: 'none', background: 'var(--color-primary)', color: 'var(--color-text-on-primary)', fontWeight: 500, fontSize: 16, cursor: 'pointer', opacity: results.length < limit ? 0.5 : 1 }}>Next</button>
      </div>
    </div>
  );
}

export default App;
