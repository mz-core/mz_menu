const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'mz_menu';

const app = document.getElementById('app');
const contextPanel = document.getElementById('contextPanel');
const menuTitle = document.getElementById('menuTitle');
const brandEl = document.getElementById('brand');
const menuSubtitle = document.getElementById('menuSubtitle');
const subtitleSeparator = document.getElementById('subtitleSeparator');
const headerIcon = document.getElementById('headerIcon');
const menuBadge = document.getElementById('menuBadge');
const optionsEl = document.getElementById('options');
const closeBtn = document.getElementById('closeBtn');
const backBtn = document.getElementById('backBtn');
const dialogOverlay = document.getElementById('dialogOverlay');
const dialogEl = document.getElementById('dialog');
const toastsEl = document.getElementById('toasts');
const focusToggleBtn = document.getElementById('focusToggleBtn');
const focusToggleKeyEl = document.getElementById('focusToggleKey');
const focusToggleLabel = document.getElementById('focusToggleLabel');
const dashboardMeta = document.getElementById('dashboardMeta');
const userCard = document.getElementById('userCard');
const statsGrid = document.getElementById('statsGrid');
const searchWrap = document.getElementById('searchWrap');
const menuSearch = document.getElementById('menuSearch');
const searchHint = document.getElementById('searchHint');
const selectorFilters = document.getElementById('selectorFilters');
const selectorSummary = document.getElementById('selectorSummary');

let currentMenu = null;
let currentBrand = 'MZ Menu';
let focusedIndex = 0;
let dialogRequestId = null;
let dialogType = null;
let movementEnabled = false;
let movementToggleKey = 'F6';
let movementToggleEnabled = true;
let playerSelector = null;
let selectorSearchTimer = null;

const icons = {
  home: '<path d="m3 10.5 9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/>',
  house: '<path d="m3 10.5 9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/>',
  plus: '<path d="M12 5v14"/><path d="M5 12h14"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  settings: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.09a2 2 0 0 1-1-1.74v-.51a2 2 0 0 1 1-1.72l.15-.1a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2Z"/><circle cx="12" cy="12" r="3"/>',
  garage: '<path d="M3 21V9l9-5 9 5v12"/><path d="M7 21v-8h10v8"/><path d="M9 17h6"/>',
  car: '<path d="M7 17h10"/><path d="M5 17l1.5-6h11L19 17"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/>',
  key: '<circle cx="7.5" cy="14.5" r="3.5"/><path d="M10 12 21 1"/><path d="m16 6 2 2"/><path d="m18 4 2 2"/>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  check: '<path d="m20 6-11 11-5-5"/>',
  'circle-check': '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-5"/>',
  warning: '<path d="m12 3 10 18H2L12 3Z"/><path d="M12 9v5"/><path d="M12 17h.01"/>',
  archive: '<path d="M21 8v13H3V8"/><path d="M1 3h22v5H1z"/><path d="M10 12h4"/>',
  refresh: '<path d="M21 12a9 9 0 0 1-15.5 6.3L3 16"/><path d="M3 21v-5h5"/><path d="M3 12a9 9 0 0 1 15.5-6.3L21 8"/><path d="M21 3v5h-5"/>',
  box: '<path d="m21 8-9-5-9 5 9 5 9-5Z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/>',
  shirt: '<path d="M20.4 7.2 16 4H8L3.6 7.2 6 11l2-1v10h8V10l2 1 2.4-3.8Z"/>',
  door: '<path d="M4 21h16"/><path d="M6 21V4h10v17"/><path d="M13 12h.01"/>',
  building: '<path d="M3 21h18"/><path d="M5 21V7l8-4v18"/><path d="M19 21V11l-6-4"/><path d="M9 9h.01"/><path d="M9 13h.01"/><path d="M9 17h.01"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  power: '<path d="M12 2v10"/><path d="M18.4 6.6a9 9 0 1 1-12.77.04"/>',
  lock: '<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  unlock: '<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/>',
  'map-pin': '<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  server: '<rect x="3" y="4" width="18" height="8" rx="2"/><rect x="3" y="12" width="18" height="8" rx="2"/><path d="M7 8h.01"/><path d="M7 16h.01"/>',
  bell: '<path d="M18 8a6 6 0 1 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/>',
  keyboard: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 9h.01M11 9h.01M15 9h.01M19 9h.01M7 13h.01M11 13h.01M15 13h.01M19 13h.01M8 17h8"/>',
  layers: '<path d="m12 2 10 6-10 6L2 8l10-6Z"/><path d="m2 12 10 6 10-6"/><path d="m2 16 10 6 10-6"/>',
  'arrow-left': '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
  'arrow-right': '<path d="m12 5 7 7-7 7"/><path d="M5 12h14"/>',
  'arrow-up': '<path d="m18 15-6-6-6 6"/>',
  'arrow-down': '<path d="m6 9 6 6 6-6"/>',
  wallet: '<path d="M20 7V5a2 2 0 0 0-2-2H5a3 3 0 0 0 0 6h16v10a2 2 0 0 1-2 2H5a3 3 0 0 1-3-3V6"/><path d="M16 13h2"/>',
  target: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
  'user-search': '<circle cx="10" cy="8" r="4"/><path d="M3 21v-2a6 6 0 0 1 6-6h2"/><circle cx="17" cy="17" r="3"/><path d="m19.5 19.5 2 2"/>',
  history: '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>',
  chevron: '<path d="m9 18 6-6-6-6"/>',
  menu: '<path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/>'
};

Object.assign(icons, {
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>',
  skull: '<circle cx="12" cy="10" r="7"/><path d="M8 16v4h8v-4"/><path d="M9 10h.01M15 10h.01"/><path d="m10 14 2-1 2 1"/>',
  briefcase: '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 12h18"/><path d="M10 12v2h4v-2"/>',
  landmark: '<path d="m3 10 9-6 9 6"/><path d="M5 10h14"/><path d="M7 10v8M12 10v8M17 10v8"/><path d="M4 18h16M2 22h20"/>',
  crown: '<path d="m3 7 4 5 5-8 5 8 4-5-2 12H5L3 7Z"/><path d="M5 19h14"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18"/>'
});

Object.assign(icons, {
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  trash: '<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="m19 6-1 15H6L5 6"/><path d="M10 11v6M14 11v6"/>',
  list: '<path d="M8 6h13M8 12h13M8 18h13"/><path d="M3 6h.01M3 12h.01M3 18h.01"/>',
  clipboard: '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2"/><path d="M9 10h6M9 14h6"/>',
  chart: '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  bolt: '<path d="M13 2 3 14h7l-1 8 10-12h-7l1-8Z"/>',
  ban: '<circle cx="12" cy="12" r="10"/><path d="m5 5 14 14"/>'
});

const iconAliases = {
  'binoculars': 'eye', 'box-open': 'box', 'building-shield': 'building', 'car-side': 'car',
  'chart-column': 'chart', 'circle-info': 'info', 'clipboard-list': 'clipboard', 'clock': 'history',
  'clock-rotate-left': 'history', 'copy': 'layers', 'couch': 'house', 'crosshairs': 'target',
  'cube': 'box', 'cubes': 'layers', 'database': 'server', 'door-closed': 'door', 'door-open': 'door',
  'earth-americas': 'globe', 'eye-slash': 'eye', 'filter': 'search', 'filter-circle-xmark': 'search',
  'fingerprint': 'target', 'floppy-disk': 'archive', 'heart-pulse': 'circle-check', 'id-card': 'user',
  'inbox': 'archive', 'kit-medical': 'plus', 'layer-group': 'layers', 'link': 'key', 'link-slash': 'key',
  'list-check': 'circle-check', 'location-dot': 'map-pin', 'magnifying-glass': 'search', 'map-location-dot': 'map-pin',
  'message': 'bell', 'money-bill': 'wallet', 'money-check-dollar': 'wallet', 'note-sticky': 'edit',
  'pen': 'edit', 'pen-ruler': 'edit', 'pen-to-square': 'edit', 'people-arrows-left-right': 'users',
  'person-flying': 'target', 'person-walking-arrow-right': 'arrow-right', 'power-off': 'power',
  'ranking-star': 'crown', 'rotate': 'refresh', 'rotate-left': 'refresh', 'route': 'map-pin',
  'ruler-combined': 'edit', 'screwdriver-wrench': 'settings', 'shield-circle-check': 'shield',
  'shield-halved': 'shield', 'shield-virus': 'shield', 'sliders': 'settings', 'square-parking': 'garage',
  'timeline': 'history', 'triangle-exclamation': 'warning', 'unlock': 'unlock', 'user-check': 'circle-check',
  'user-lock': 'lock', 'user-magnifying-glass': 'user-search', 'user-plus': 'plus', 'user-shield': 'shield',
  'user-xmark': 'x', 'users-gear': 'users', 'users-slash': 'users', 'warehouse': 'garage', 'xmark': 'x'
};

function post(name, data = {}) {
  return fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).catch(() => null);
}

function svg(name) {
  const requested = String(name || 'menu').toLowerCase();
  const key = iconAliases[requested] || requested;
  const body = icons[key] || icons.menu;
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${body}</svg>`;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function setTheme(theme = {}, brand = 'MZ Menu') {
  const isHex = value => /^#[0-9a-f]{6}$/i.test(String(value || ''));
  const safeAccent = isHex(theme.accent) ? theme.accent : '#009fe3';
  const safeAccent2 = isHex(theme.accent2) ? theme.accent2 : '#67c9f1';
  const requestedWidth = Number(theme.width);
  const safeWidth = Number.isFinite(requestedWidth) ? Math.min(640, Math.max(320, requestedWidth)) : 380;
  const safePosition = ['left', 'right', 'center'].includes(theme.position) ? theme.position : 'left';

  document.documentElement.style.setProperty('--mz-primary', safeAccent);
  document.documentElement.style.setProperty('--mz-primary-hover', safeAccent);
  document.documentElement.style.setProperty('--mz-accent', safeAccent2);
  document.documentElement.style.setProperty('--mz-panel-width', `${safeWidth}px`);

  currentBrand = brand || 'MZ Menu';
  brandEl.textContent = currentBrand;

  app.classList.remove('app--right', 'app--left', 'app--center');
  app.classList.add(`app--${safePosition}`);
}

function closeAll(send = true) {
  contextPanel.classList.add('hidden');
  dialogOverlay.classList.add('hidden');
  dialogEl.innerHTML = '';
  currentMenu = null;
  menuSearch.value = '';
  searchWrap.classList.add('hidden');
  dashboardMeta.classList.add('hidden');
  selectorFilters.classList.add('hidden');
  selectorSummary.classList.add('hidden');
  selectorFilters.innerHTML = '';
  selectorSummary.textContent = '';
  playerSelector = null;
  if (selectorSearchTimer) clearTimeout(selectorSearchTimer);
  selectorSearchTimer = null;
  dialogRequestId = null;
  dialogType = null;
  setMovementMode(false, movementToggleKey);
  if (send) post('close');
}

function setMovementMode(enabled, key = movementToggleKey, toggleEnabled = movementToggleEnabled) {
  movementEnabled = enabled === true;
  movementToggleEnabled = toggleEnabled !== false;
  movementToggleKey = /^F([1-9]|1[0-2])$/i.test(String(key || '')) ? String(key).toUpperCase() : 'F6';
  contextPanel.classList.toggle('is-movement', movementEnabled);
  focusToggleBtn.classList.toggle('hidden', !movementToggleEnabled);
  focusToggleKeyEl.textContent = movementToggleKey;
  focusToggleLabel.textContent = movementEnabled ? 'travar movimento' : 'liberar movimento';
  focusToggleBtn.setAttribute(
    'aria-label',
    movementEnabled ? 'Travar movimento' : 'Liberar movimento'
  );
}

function safeVariant(value, fallback = 'neutral') {
  const normalized = String(value || '').toLowerCase();
  return ['neutral', 'info', 'success', 'warning', 'danger'].includes(normalized) ? normalized : fallback;
}

function renderMetadata(metadata) {
  if (!metadata) return '';
  const values = Array.isArray(metadata)
    ? metadata.map(item => typeof item === 'object' ? `${item.label || ''}${item.value !== undefined ? `: ${item.value}` : ''}` : String(item))
    : Object.entries(metadata).map(([key, value]) => `${key}: ${value}`);

  if (!values.length) return '';
  return `<div class="option__meta">${values.slice(0, 4).map(v => `<span class="chip">${escapeHtml(v)}</span>`).join('')}</div>`;
}

function renderPill(text, variant = 'neutral', className = 'option__pill') {
  if (text === undefined || text === null || String(text).trim() === '') return '';
  return `<span class="${className} is-${safeVariant(variant)}">${escapeHtml(text)}</span>`;
}

function renderOption(option, idx) {
  if (String(option.type || '').toLowerCase() === 'section') {
    return `<div class="option-section"><span>${escapeHtml(option.label || option.title || '')}</span></div>`;
  }

  const disabled = option.disabled || option.readOnly;
  const progress = typeof option.progress === 'number'
    ? `<div class="progress" title="${Math.round(Math.max(0, Math.min(100, option.progress)))}%"><span style="width:${Math.max(0, Math.min(100, option.progress))}%"></span></div>`
    : '';
  const arrow = (option.menu || option.arrow === true) && option.arrow !== false ? svg('chevron') : '';
  const toggle = typeof option.checked === 'boolean'
    ? `<span class="option__toggle ${option.checked ? 'is-on' : ''}" aria-hidden="true"><span></span></span>`
    : '';
  const iconColor = option.iconColor ? `style="color:${escapeHtml(option.iconColor)}"` : '';
  const badge = renderPill(option.badge, option.badgeVariant || 'neutral');
  const status = renderPill(option.status, option.statusVariant || 'info', 'option__status');
  const shortcut = option.shortcut ? `<kbd class="option__shortcut">${escapeHtml(option.shortcut)}</kbd>` : '';
  const tone = option.destructive === true || String(option.tone || '').toLowerCase() === 'danger' ? ' is-danger' : '';
  const searchText = [option.title, option.description, option.badge, option.status]
    .filter(Boolean).join(' ').toLowerCase();

  return `
    <button class="option ${disabled ? 'is-disabled' : ''}${tone}" data-index="${idx}" data-search="${escapeHtml(searchText)}" type="button">
      <span class="option__icon" ${iconColor}>${svg(option.icon)}</span>
      <span class="option__body">
        <span class="option__titleRow">
          <span class="option__title">${escapeHtml(option.title || 'Opção')}</span>
          ${badge}
        </span>
        ${option.description ? `<span class="option__desc">${escapeHtml(option.description)}</span>` : ''}
        ${renderMetadata(option.metadata)}
      </span>
      <span class="option__right">${status}${shortcut}${progress}${toggle}${arrow}</span>
    </button>
  `;
}

function visibleButtons() {
  return [...optionsEl.querySelectorAll('.option:not(.is-disabled):not(.is-filtered)')];
}

function updateFocus() {
  const buttons = visibleButtons();
  optionsEl.querySelectorAll('.option').forEach(btn => btn.classList.remove('is-focused'));
  if (!buttons.length) return;
  focusedIndex = Math.max(0, Math.min(buttons.length - 1, focusedIndex));
  buttons[focusedIndex].classList.add('is-focused');
  buttons[focusedIndex].scrollIntoView({ block: 'nearest' });
}

function applySearchFilter() {
  const term = String(menuSearch.value || '').trim().toLowerCase();
  optionsEl.querySelectorAll('.option[data-search]').forEach(btn => {
    const haystack = String(btn.dataset.search || '');
    btn.classList.toggle('is-filtered', !!term && !haystack.includes(term));
  });
  focusedIndex = 0;
  updateFocus();
}

function selectorFilterLabel(filter) {
  if (filter === 'online') return 'Online';
  if (filter === 'offline') return 'Offline';
  return 'Todos';
}

function renderPlayerItem(item) {
  const online = item.online === true && Number(item.source) > 0;
  const characterName = String(item.characterName || '').trim();
  const sessionName = String(item.name || '').trim();
  const title = characterName || sessionName || 'Character sem nome';
  const details = [];
  if (sessionName && sessionName.toLowerCase() !== title.toLowerCase()) details.push(sessionName);
  details.push(online ? `Source ${Number(item.source)}` : 'Offline');
  if (item.self === true) details.push('voce');
  return `
    <button class="option player-option" data-player-key="${escapeHtml(item.key)}" type="button">
      <span class="option__icon player-option__state ${online ? 'is-online' : 'is-offline'}" aria-hidden="true"><span></span></span>
      <span class="option__body">
        <span class="option__titleRow"><span class="option__title">${escapeHtml(title)}</span></span>
        <span class="option__desc">${escapeHtml(details.join(' · '))}</span>
      </span>
      <span class="option__right">${renderPill(online ? 'Online' : 'Offline', online ? 'success' : 'neutral', 'option__status')}${svg('chevron')}</span>
    </button>
  `;
}

function bindPlayerSelectorResults() {
  optionsEl.querySelectorAll('.player-option').forEach(button => {
    button.addEventListener('click', () => {
      if (!playerSelector) return;
      post('playerSelectorSelect', {
        requestId: playerSelector.requestId,
        key: button.dataset.playerKey
      });
    });
  });
  const more = optionsEl.querySelector('.selector-more');
  if (more) more.addEventListener('click', () => requestPlayerSelectorPage(playerSelector.page + 1, true));
}

function renderPlayerSelectorResults(result = {}, append = false) {
  if (!playerSelector) return;
  const incoming = Array.isArray(result.items) ? result.items : [];
  if (!append) playerSelector.items = [];
  const known = new Set(playerSelector.items.map(item => item.key));
  incoming.forEach(item => {
    if (item && item.key && !known.has(item.key)) {
      known.add(item.key);
      playerSelector.items.push(item);
    }
  });
  playerSelector.page = Math.max(1, Number(result.page) || 1);
  playerSelector.hasMore = result.hasMore === true;
  playerSelector.total = Math.max(playerSelector.items.length, Number(result.total) || 0);

  const hint = String(result.hint || '').trim();
  selectorSummary.textContent = hint || `${playerSelector.items.length} de ${playerSelector.total} resultado(s)`;
  selectorSummary.classList.remove('hidden');
  const empty = hint || 'Nenhum jogador encontrado.';
  optionsEl.innerHTML = playerSelector.items.length
    ? playerSelector.items.map(renderPlayerItem).join('')
    : `<div class="option-empty"><span>${escapeHtml(empty)}</span><small>Tente outro nome, citizenid ou source.</small></div>`;
  if (playerSelector.hasMore) {
    optionsEl.insertAdjacentHTML('beforeend', '<button class="option selector-more" type="button"><span class="option__icon">+</span><span class="option__body"><span class="option__title">Carregar mais</span><span class="option__desc">Próxima página de Characters</span></span><span class="option__right"></span></button>');
  }
  focusedIndex = 0;
  bindPlayerSelectorResults();
  updateFocus();
}

function requestPlayerSelectorPage(page = 1, append = false) {
  if (!playerSelector) return;
  selectorSummary.textContent = 'Buscando...';
  selectorSummary.classList.remove('hidden');
  post('playerSelectorSearch', {
    requestId: playerSelector.requestId,
    query: menuSearch.value,
    filter: playerSelector.filter,
    page,
    append
  });
}

function cancelPlayerSelector(restorePrevious = true) {
  if (!playerSelector) return false;
  post('playerSelectorCancel', { requestId: playerSelector.requestId, restorePrevious });
  return true;
}

function openPlayerSelector(selector = {}) {
  playerSelector = {
    requestId: selector.requestId,
    filter: selector.defaultFilter || 'all',
    page: 1,
    total: 0,
    hasMore: false,
    items: []
  };
  currentMenu = { playerSelector: true, id: selector.requestId };
  focusedIndex = 0;
  contextPanel.classList.remove('is-dashboard');
  dashboardMeta.classList.add('hidden');
  brandEl.textContent = selector.brand || currentBrand || 'MZ Menu';
  menuTitle.textContent = selector.title || 'Selecionar jogador';
  menuSubtitle.textContent = selector.subtitle || '';
  menuSubtitle.classList.toggle('hidden', !selector.subtitle);
  subtitleSeparator.classList.add('hidden');
  headerIcon.classList.remove('hidden');
  headerIcon.innerHTML = svg('user-search');
  menuBadge.classList.add('hidden');
  backBtn.classList.remove('hidden');
  backBtn.innerHTML = svg('arrow-left');
  closeBtn.innerHTML = svg('x');

  searchWrap.classList.remove('hidden');
  menuSearch.value = '';
  menuSearch.placeholder = selector.searchPlaceholder || 'Nome, Character, citizenid ou source...';
  searchWrap.querySelector('.mz-search__icon').innerHTML = svg('search');
  searchHint.textContent = 'CTRL K';

  const filters = Array.isArray(selector.filters) ? selector.filters : ['all', 'online', 'offline'];
  selectorFilters.innerHTML = filters.map(filter => `
    <button class="mz-selectorFilter ${filter === playerSelector.filter ? 'is-active' : ''}" data-filter="${escapeHtml(filter)}" type="button">${escapeHtml(selectorFilterLabel(filter))}</button>
  `).join('');
  selectorFilters.classList.remove('hidden');
  selectorSummary.textContent = 'Buscando jogadores online...';
  selectorSummary.classList.remove('hidden');
  optionsEl.innerHTML = '<div class="option-empty"><span>Buscando...</span></div>';
  selectorFilters.querySelectorAll('[data-filter]').forEach(button => {
    button.addEventListener('click', () => {
      if (!playerSelector) return;
      playerSelector.filter = button.dataset.filter || 'all';
      selectorFilters.querySelectorAll('[data-filter]').forEach(item => item.classList.toggle('is-active', item === button));
      requestPlayerSelectorPage(1, false);
    });
  });
  contextPanel.classList.remove('hidden');
}

function renderDashboardMeta(menu) {
  const isDashboard = String(menu.layout || 'context').toLowerCase() === 'dashboard';
  const user = menu.user && typeof menu.user === 'object' ? menu.user : null;
  const stats = Array.isArray(menu.stats) ? menu.stats.slice(0, 4) : [];

  dashboardMeta.classList.toggle('hidden', !isDashboard || (!user && !stats.length));

  if (isDashboard && user) {
    const initial = String(user.name || 'S').trim().charAt(0).toUpperCase() || 'S';
    userCard.innerHTML = `
      <span class="mz-userCard__avatar">${escapeHtml(initial)}</span>
      <span class="mz-userCard__body">
        <strong>${escapeHtml(user.name || 'Staff')}</strong>
        <small>${escapeHtml(user.subtitle || 'Sessão administrativa')}</small>
      </span>
      ${renderPill(user.role || 'STAFF', user.variant || 'info', 'mz-userCard__role')}
    `;
    userCard.classList.remove('hidden');
  } else {
    userCard.classList.add('hidden');
    userCard.innerHTML = '';
  }

  if (isDashboard && stats.length) {
    statsGrid.innerHTML = stats.map(stat => `
      <div class="mz-stat is-${safeVariant(stat.variant || 'neutral')}">
        <span>${escapeHtml(stat.label || '')}</span>
        <strong>${escapeHtml(stat.value ?? '—')}</strong>
      </div>
    `).join('');
    statsGrid.classList.remove('hidden');
  } else {
    statsGrid.classList.add('hidden');
    statsGrid.innerHTML = '';
  }
}

function openContext(menu) {
  playerSelector = null;
  selectorFilters.classList.add('hidden');
  selectorSummary.classList.add('hidden');
  selectorFilters.innerHTML = '';
  selectorSummary.textContent = '';
  currentMenu = menu || { id: 'unknown', title: 'Menu', options: [] };
  focusedIndex = 0;

  const layout = String(currentMenu.layout || 'context').toLowerCase() === 'dashboard' ? 'dashboard' : 'context';
  contextPanel.classList.toggle('is-dashboard', layout === 'dashboard');

  menuTitle.textContent = currentMenu.title || 'Menu';
  brandEl.textContent = currentMenu.brand || currentBrand || 'MZ Menu';
  const subtitle = currentMenu.subtitle || currentMenu.description || '';
  menuSubtitle.textContent = subtitle;
  menuSubtitle.classList.toggle('hidden', !subtitle);
  subtitleSeparator.classList.add('hidden');
  headerIcon.classList.toggle('hidden', !currentMenu.headerIcon);
  headerIcon.innerHTML = currentMenu.headerIcon ? svg(currentMenu.headerIcon) : '';
  menuBadge.classList.toggle('hidden', !currentMenu.badge);
  menuBadge.textContent = currentMenu.badge || '';
  backBtn.classList.toggle('hidden', !currentMenu.menu);
  backBtn.innerHTML = svg('arrow-left');
  closeBtn.innerHTML = svg('x');

  renderDashboardMeta(currentMenu);

  const searchable = currentMenu.searchable === true;
  searchWrap.classList.toggle('hidden', !searchable);
  menuSearch.value = '';
  menuSearch.placeholder = currentMenu.searchPlaceholder || 'Buscar ferramenta...';
  searchWrap.querySelector('.mz-search__icon').innerHTML = svg('search');
  searchHint.textContent = 'CTRL K';

  const options = currentMenu.options || [];
  optionsEl.innerHTML = options.length
    ? options.map(renderOption).join('')
    : '<div class="option-empty"><span>Nenhuma opção disponível</span><small>As permissões podem limitar este menu.</small></div>';

  optionsEl.querySelectorAll('.option[data-index]').forEach(btn => {
    btn.addEventListener('click', () => {
      const index = Number(btn.dataset.index);
      const option = (currentMenu.options || [])[index];
      if (!option || option.disabled || option.readOnly || String(option.type || '').toLowerCase() === 'section') return;
      post('select', { id: currentMenu.id, index: option.index || index + 1 });
    });
  });

  contextPanel.classList.remove('hidden');
  updateFocus();
}

function notify(data = {}) {
  const type = data.type === 'inform' ? 'info' : (data.type || 'info');
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = `
    <div class="toast__title">${escapeHtml(data.title || 'MZ Menu')}</div>
    <div class="toast__desc">${escapeHtml(data.description || data.message || '')}</div>
  `;
  toastsEl.appendChild(el);
  const duration = Number(data.duration || 5000);
  setTimeout(() => {
    el.style.opacity = '0';
    el.style.transform = 'translateX(16px)';
    setTimeout(() => el.remove(), 180);
  }, duration);
}

function renderInputRow(row, idx) {
  const type = row.type || 'input';
  const label = row.label || row.name || `Campo ${idx + 1}`;
  const placeholder = row.placeholder || '';
  const required = row.required ? 'required' : '';
  const value = row.default ?? row.value ?? '';
  const name = `field_${idx}`;
  const description = row.description
    ? `<span class="field__description">${escapeHtml(row.description)}</span>`
    : '';

  if (type === 'checkbox') {
    const checked = row.checked === true || row.default === true ? 'checked' : '';
    return `<div class="field"><div class="field--checkbox"><input id="${name}" name="${name}" type="checkbox" ${checked}/><label for="${name}">${escapeHtml(label)}</label></div>${description}</div>`;
  }

  if (type === 'textarea') {
    return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><textarea id="${name}" name="${name}" placeholder="${escapeHtml(placeholder)}" ${required}>${escapeHtml(value)}</textarea>${description}</div>`;
  }

  if (type === 'select') {
    const opts = Array.isArray(row.options) ? row.options : [];
    return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><select id="${name}" name="${name}" ${required}>${opts.map(opt => {
      const optValue = typeof opt === 'object' ? opt.value : opt;
      const optLabel = typeof opt === 'object' ? (opt.label || opt.value) : opt;
      const selected = String(optValue) === String(value) ? 'selected' : '';
      return `<option value="${escapeHtml(optValue)}" ${selected}>${escapeHtml(optLabel)}</option>`;
    }).join('')}</select>${description}</div>`;
  }

  const htmlType = type === 'number' ? 'number' : (type === 'color' ? 'color' : (type === 'date' ? 'date' : (type === 'time' ? 'time' : 'text')));
  return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><input id="${name}" name="${name}" type="${htmlType}" value="${escapeHtml(value)}" placeholder="${escapeHtml(placeholder)}" ${required}/>${description}</div>`;
}

function closeDialogAsCancel() {
  if (dialogType === 'input') post('inputCancel', { requestId: dialogRequestId });
  if (dialogType === 'alert') post('alertSubmit', { requestId: dialogRequestId, result: 'cancel', cancelled: true });
  dialogOverlay.classList.add('hidden');
}

function openInputDialog(payload) {
  dialogRequestId = payload.requestId;
  dialogType = 'input';
  const rows = Array.isArray(payload.rows) ? payload.rows : [];
  const options = payload.options || {};
  const labels = options.labels || {};
  const confirmLabel = labels.confirm || options.confirmLabel || 'Confirmar';
  const cancelLabel = labels.cancel || options.cancelLabel || 'Cancelar';

  dialogEl.className = 'mz-dialog';
  dialogEl.innerHTML = `
    <div class="dialog__header">
      <h2 class="dialog__title">${escapeHtml(payload.title || 'Input')}</h2>
      <button class="mz-icon-btn" type="button" id="inputX" title="Fechar">${svg('x')}</button>
    </div>
    <form id="inputForm" class="form">
      <div class="dialog__body">
        ${rows.map(renderInputRow).join('')}
      </div>
      <div class="dialog__actions">
        <button class="btn" type="button" id="inputCancel">${escapeHtml(cancelLabel)}</button>
        <button class="btn btn--primary" type="submit">${escapeHtml(confirmLabel)}</button>
      </div>
    </form>
  `;
  dialogOverlay.classList.remove('hidden');

  document.getElementById('inputX').onclick = closeDialogAsCancel;
  document.getElementById('inputCancel').onclick = closeDialogAsCancel;
  document.getElementById('inputForm').onsubmit = (event) => {
    event.preventDefault();
    const values = rows.map((row, idx) => {
      const el = document.querySelector(`[name="field_${idx}"]`);
      if (!el) return null;
      if ((row.type || 'input') === 'checkbox') return el.checked;
      if ((row.type || 'input') === 'number') return el.value === '' ? null : Number(el.value);
      return el.value;
    });
    post('inputSubmit', { requestId: dialogRequestId, values });
    dialogOverlay.classList.add('hidden');
  };

  const first = dialogEl.querySelector('input, textarea, select');
  if (first) first.focus();
}

function getAlertVariant(data) {
  const rawType = String(data.type || data.severity || '').toLowerCase();
  const rawColor = String(data.confirmColor || data.color || '').toLowerCase();
  const title = String(data.header || data.title || '').toLowerCase();
  const content = String(data.content || data.description || '').toLowerCase();
  const text = `${title} ${content}`;

  const isDanger = data.destructive === true
    || rawType === 'error'
    || rawType === 'danger'
    || rawColor === 'red'
    || rawColor === 'danger'
    || text.includes('arquivar')
    || text.includes('excluir')
    || text.includes('deletar')
    || text.includes('remover');

  if (isDanger) return 'danger';
  if (rawType === 'warning' || rawType === 'warn' || rawColor === 'yellow' || rawColor === 'orange') return 'warning';
  if (rawType === 'success' || rawColor === 'green') return 'success';
  return 'info';
}

function openAlertDialog(payload) {
  dialogRequestId = payload.requestId;
  dialogType = 'alert';
  const data = payload.data || {};
  const hasCancel = data.cancel !== false;
  const variant = getAlertVariant(data);
  const confirmClass = variant === 'danger' ? 'btn btn--danger' : 'btn btn--primary';
  const iconName = variant === 'danger' || variant === 'warning' ? 'warning' : 'info';
  const labels = data.labels || {};
  const confirmLabel = labels.confirm || data.confirmLabel || data.confirm || data.confirmText || 'Confirmar';
  const cancelLabel = labels.cancel || data.cancelLabel || data.cancelText || 'Cancelar';

  dialogEl.className = 'mz-dialog';
  dialogEl.innerHTML = `
    <div class="dialog__body dialog__confirmContent">
      <span class="dialog__warnIcon is-${variant}">${svg(iconName)}</span>
      <div>
        <h2 class="dialog__title">${escapeHtml(data.header || data.title || 'Alerta')}</h2>
        <p class="dialog__message">${escapeHtml(data.content || data.description || '')}</p>
      </div>
    </div>
    <div class="dialog__actions">
      ${hasCancel ? `<button class="btn" type="button" id="alertCancel">${escapeHtml(cancelLabel)}</button>` : ''}
      <button class="${confirmClass}" type="button" id="alertConfirm">${escapeHtml(confirmLabel)}</button>
    </div>
  `;
  dialogOverlay.classList.remove('hidden');

  const cancel = document.getElementById('alertCancel');
  if (cancel) cancel.onclick = closeDialogAsCancel;
  document.getElementById('alertConfirm').onclick = () => {
    post('alertSubmit', { requestId: dialogRequestId, result: 'confirm' });
    dialogOverlay.classList.add('hidden');
  };
}

menuSearch.addEventListener('input', () => {
  if (!playerSelector) {
    applySearchFilter();
    return;
  }
  if (selectorSearchTimer) clearTimeout(selectorSearchTimer);
  selectorSearchTimer = setTimeout(() => requestPlayerSelectorPage(1, false), 250);
});
menuSearch.addEventListener('keydown', event => {
  if (event.key === 'Enter') {
    const buttons = visibleButtons();
    if (buttons.length === 1) {
      event.preventDefault();
      buttons[0].click();
    }
  }
});

closeBtn.onclick = () => {
  if (!cancelPlayerSelector(false)) closeAll(true);
};
backBtn.onclick = () => {
  if (cancelPlayerSelector()) return;
  if (currentMenu && currentMenu.menu) post('back', { id: currentMenu.id });
};
focusToggleBtn.onclick = () => {
  if (movementToggleEnabled && currentMenu && dialogOverlay.classList.contains('hidden')) post('toggleMovement');
};

document.addEventListener('keydown', event => {
  if ((event.ctrlKey || event.metaKey)
    && String(event.key || '').toLowerCase() === 'k'
    && !searchWrap.classList.contains('hidden')
    && !contextPanel.classList.contains('hidden')
    && dialogOverlay.classList.contains('hidden')) {
    event.preventDefault();
    menuSearch.focus();
    menuSearch.select();
    return;
  }

  if (movementToggleEnabled
    && !contextPanel.classList.contains('hidden')
    && dialogOverlay.classList.contains('hidden')
    && String(event.key || '').toUpperCase() === movementToggleKey) {
    event.preventDefault();
    post('toggleMovement');
    return;
  }

  if (!contextPanel.classList.contains('hidden') && dialogOverlay.classList.contains('hidden')) {
    const buttons = visibleButtons();
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      focusedIndex = buttons.length ? (focusedIndex + 1) % buttons.length : 0;
      updateFocus();
      return;
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      focusedIndex = buttons.length ? (focusedIndex - 1 + buttons.length) % buttons.length : 0;
      updateFocus();
      return;
    }
    if (event.key === 'Enter') {
      event.preventDefault();
      if (buttons[focusedIndex]) buttons[focusedIndex].click();
      return;
    }
  }

  if (event.key === 'Escape') {
    if (!dialogOverlay.classList.contains('hidden')) {
      closeDialogAsCancel();
      return;
    }
    if (cancelPlayerSelector(false)) return;
    if (!contextPanel.classList.contains('hidden')) closeAll(true);
  }

  if (event.key === 'Backspace'
    && !contextPanel.classList.contains('hidden')
    && dialogOverlay.classList.contains('hidden')
    && (document.activeElement !== menuSearch || menuSearch.value === '')) {
    event.preventDefault();
    if (cancelPlayerSelector()) return;
    if (currentMenu && currentMenu.menu) post('back', { id: currentMenu.id });
  }
});

window.addEventListener('message', event => {
  const data = event.data || {};
  if (data.action === 'theme') setTheme(data.theme, data.brand);
  if (data.action === 'openContext') openContext(data.menu);
  if (data.action === 'openPlayerSelector') openPlayerSelector(data.selector);
  if (data.action === 'playerSelectorResults'
    && playerSelector
    && data.requestId === playerSelector.requestId) renderPlayerSelectorResults(data.result, data.append === true);
  if (data.action === 'close') closeAll(false);
  if (data.action === 'notify') notify(data.data);
  if (data.action === 'inputDialog') openInputDialog(data);
  if (data.action === 'alertDialog') openAlertDialog(data);
  if (data.action === 'movementMode') {
    setMovementMode(data.movementEnabled, data.key, data.toggleEnabled);
  }
});

post('ready');
