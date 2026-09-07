/* Shared helpers for the Collinalitics demo platforms.
   No build step, no framework — Chart.js from CDN is the only dependency.
   Colours are read from styles.css so --brand controls the charts too. */

const _css = getComputedStyle(document.documentElement);
const _v = n => _css.getPropertyValue(n).trim();

const C = {
  blue:   _v('--brand'),
  teal:   _v('--teal'),
  orange: _v('--orange'),
  red:    _v('--red'),
  green:  _v('--green'),
  amber:  _v('--amber'),
  ink:    _v('--ink'),
  ink2:   _v('--ink-2'),
  ink3:   _v('--ink-3'),
  line:   _v('--line'),
  grid:   _v('--line')
};

function fmt(n, dp) {
  if (n === null || n === undefined) return '—';
  return Number(n).toLocaleString('en-GB', {
    minimumFractionDigits: dp || 0,
    maximumFractionDigits: dp || 0
  });
}

function kpiStrip(elId, items) {
  const el = document.getElementById(elId);
  el.innerHTML = items.map(k =>
    '<div class="kpi">' +
      '<div class="lab">' + k.lab + '</div>' +
      '<div class="val">' + k.val + '</div>' +
      (k.foot ? '<div class="foot ' + (k.cls || '') + '">' + k.foot + '</div>' : '') +
    '</div>'
  ).join('');
}

if (window.Chart) {
  Chart.defaults.font.family =
    'ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
  Chart.defaults.font.size = 13;
  Chart.defaults.color = C.ink2;
  Chart.defaults.plugins.tooltip.backgroundColor = C.ink;
  Chart.defaults.plugins.tooltip.padding = 12;
  Chart.defaults.plugins.tooltip.cornerRadius = 8;
  Chart.defaults.plugins.tooltip.displayColors = false;
}

/* Horizontal bar when `horizontal` is true; legend only when `legend` is true. */
function barOpts(axisTitle, horizontal, legend) {
  const valueAxis = {
    beginAtZero: true,
    title: { display: !!axisTitle, text: axisTitle, color: C.ink3 },
    grid: { color: C.grid, drawBorder: false },
    ticks: { color: C.ink2 }
  };
  const catAxis = { grid: { display: false }, ticks: { color: C.ink2 } };

  return {
    indexAxis: horizontal ? 'y' : 'x',
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: !!legend, position: 'top', align: 'end',
                labels: { boxWidth: 10, boxHeight: 10, usePointStyle: true, pointStyle: 'rectRounded' } }
    },
    scales: horizontal ? { x: valueAxis, y: catAxis } : { x: catAxis, y: valueAxis }
  };
}

function lineOpts(yTitle, yMin, yMax) {
  return {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: { legend: { display: false } },
    scales: {
      x: { grid: { display: false }, ticks: { color: C.ink2, maxRotation: 0, autoSkipPadding: 16 } },
      y: {
        min: yMin, max: yMax,
        title: { display: !!yTitle, text: yTitle, color: C.ink3 },
        grid: { color: C.grid, drawBorder: false },
        ticks: { color: C.ink2 }
      }
    }
  };
}

/* Click-to-sort on any table with sortable headers.
   Numeric columns sort numerically; everything else alphabetically. */
function makeSortable(tableId, rows, render) {
  const table = document.getElementById(tableId);
  const ths = table.querySelectorAll('th');
  let current = null, asc = false;

  ths.forEach(th => {
    const key = th.dataset.key;
    if (!key) return;
    th.addEventListener('click', () => {
      asc = current === key ? !asc : false;
      current = key;
      rows.sort((a, b) => {
        const x = a[key], y = b[key];
        const cmp = (typeof x === 'number' && typeof y === 'number')
          ? x - y
          : String(x).localeCompare(String(y));
        return asc ? cmp : -cmp;
      });
      ths.forEach(t => t.textContent = t.textContent.replace(/ [↑↓]$/, ''));
      th.textContent += asc ? ' ↑' : ' ↓';
      render();
    });
  });
}