
import { useEffect, useState } from 'react';

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

  useEffect(() => {
    // Apply theme CSS variables
    const root = document.documentElement;
    Object.entries(themes[theme]).forEach(([k, v]) => root.style.setProperty(k, v));
  }, [theme]);

  useEffect(() => {
    setLoading(true);
    setError(null);
    fetch(`/api/github/results?page=${page}&limit=${limit}`)
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
  }, [page, limit]);

  return (
    <div style={{ maxWidth: 1200, margin: '2rem auto', fontFamily: 'var(--font-body)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <span className="app-page-title">Akibai Explorer</span>
        <select className="theme-dropdown" value={theme} onChange={e => setTheme(e.target.value)}>
          <option value="green">Play Green (Default)</option>
          <option value="blue">Soft Blue</option>
          <option value="yellow">Soft Yellow</option>
          <option value="gray">Soft Gray</option>
        </select>
      </div>
      <div className="grid">
        {loading && <div>Loading...</div>}
        {error && <div style={{ color: 'red' }}>Error: {error}</div>}
        {!loading && !error && results.length === 0 && <div>No results found.</div>}
        {results.map((r, i) => (
          <div className="card" key={r.id || r.url}>
            <div className="card-title">Repo #{(page - 1) * limit + i + 1}</div>
            <div className="card-meta">{r.url}</div>
            <div className="card-status">Status: {r.status}</div>
            <div style={{ fontSize: '12px', color: 'var(--color-text-muted)' }}>{r.created_at ? new Date(r.created_at).toLocaleString() : ''}</div>
            <a className="card-link" href={r.url} target="_blank" rel="noopener noreferrer">Open Repository</a>
          </div>
        ))}
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
