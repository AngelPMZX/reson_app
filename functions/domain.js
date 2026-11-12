'use strict';
const { createHash } = require('node:crypto');
const fields = [
  'photo',
  'role',
  'company',
  'email',
  'phone',
  'website',
  'bio',
  'location',
  'linkedin',
  'skills',
  'experience',
  'education',
  'sector',
  'specialty',
  'workMode',
  'projects',
  'certifications',
];
function safeUrl(value) {
  try {
    const u = new URL(value);
    return ['http:', 'https:'].includes(u.protocol) && !u.username && !u.password ? u.href : '';
  } catch {
    return '';
  }
}
function snapshot(card, selected) {
  const visible = new Set(
    selected.filter(f => fields.includes(f) && (card.visibleFields ?? fields).includes(f)),
  );
  const pick = (key, value) => (visible.has(key) ? (value ?? '') : '');
  const professional = {};
  for (const key of [
    'location',
    'linkedin',
    'skills',
    'sector',
    'specialty',
    'workMode',
    'experience',
    'education',
    'projects',
    'certifications',
  ])
    professional[key] = visible.has(key)
      ? (card.professional?.[key] ??
        (['experience', 'education', 'projects', 'certifications'].includes(key) ? [] : ''))
      : ['experience', 'education', 'projects', 'certifications'].includes(key)
        ? []
        : '';
  professional.linkedin = safeUrl(professional.linkedin);
  return {
    label: card.label,
    name: card.identity.displayName,
    role: pick('role', card.identity.jobTitle),
    company: pick('company', card.identity.company),
    email: pick('email', card.contact.email),
    phone: pick('phone', card.contact.phone),
    website: safeUrl(pick('website', card.contact.website)),
    bio: pick('bio', card.bio),
    color: card.theme.primaryHex,
    kind: card.kind ?? 'work',
    layout: card.layout ?? 'signature',
    professional,
    visibleFields: [...visible],
  };
}
function connectionId(a, b) {
  return createHash('sha256')
    .update(JSON.stringify([a, b].sort()))
    .digest('hex');
}
function escapeHtml(s) {
  return String(s ?? '').replace(
    /[&<>"']/g,
    c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c],
  );
}
function vcard(p, url) {
  const esc = s =>
    String(s ?? '')
      .replace(/\\/g, '\\\\')
      .replace(/\r\n|\r|\n/g, '\\n')
      .replace(/;/g, '\\;')
      .replace(/,/g, '\\,');
  const lines = ['BEGIN:VCARD', 'VERSION:3.0', 'FN:' + esc(p.name)];
  for (const [k, v] of [
    ['ORG', p.company],
    ['TITLE', p.role],
    ['EMAIL', p.email],
    ['TEL', p.phone],
    ['URL', p.website || url],
    ['NOTE', p.bio],
  ])
    if (v) lines.push(k + ':' + esc(v));
  lines.push('END:VCARD');
  return (
    lines
      .map(line => {
        let chunks = [],
          part = '',
          size = 0;
        for (const char of line) {
          const n = Buffer.byteLength(char);
          if (size + n > 73) {
            chunks.push(part);
            part = ' ';
            size = 1;
          }
          part += char;
          size += n;
        }
        chunks.push(part);
        return chunks.join('\r\n');
      })
      .join('\r\n') + '\r\n'
  );
}
// The connection state machine lives here as pure policy, so every branch is
// testable without a backend. index.js owns the reads, writes and timestamps.

/// What a connection request should do about an already existing connection.
/// `existing` is the stored connection or null; `respondedAt` is in millis.
function requestOutcome(existing, nowMs, cooldownMs) {
  if (!existing) return 'create';
  if (existing.status === 'blocked') return 'blocked';
  if (existing.status !== 'declined') return 'keep';
  return nowMs - (existing.respondedAt ?? 0) < cooldownMs ? 'wait' : 'revive';
}

/// What answering a request should do. Only the recipient may answer, and they
/// may still accept a request they had declined, which undoes a mistaken tap.
function respondOutcome(existing, uid, decision) {
  if (!existing || existing.recipient !== uid) return 'forbidden';
  if (decision !== 'accept' && decision !== 'decline') return 'invalid';
  const accept = decision === 'accept';
  if (existing.status === 'pending') return accept ? 'accept' : 'decline';
  if (!accept) return 'answered';
  if (existing.status === 'accepted') return 'noop';
  return existing.status === 'declined' ? 'accept' : 'answered';
}

/// A one-line trace of a message, for the network list.
///
/// Newlines are collapsed so a multi-line message cannot stretch a row, and
/// the text is cut well short of the 2000 a message may carry: the list needs
/// enough to recognise the thread, not to read it.
function preview(text, max = 120) {
  const line = String(text ?? '')
    .replace(/\s+/g, ' ')
    .trim();
  return line.length <= max ? line : line.slice(0, max - 1).trimEnd() + '…';
}

/// Mixes a `#RRGGBB` colour towards black (negative) or white (positive).
///
/// The public page needs a darker and a lighter relative of whatever colour
/// the owner chose, so the page can be theirs rather than generically carmine.
function shade(hex, amount) {
  const match = /^#?([0-9a-fA-F]{6})$/.exec(String(hex ?? ''));
  const value = match ? match[1] : 'C8102E';
  const mix = c =>
    Math.round(amount < 0 ? c * (1 + amount) : c + (255 - c) * amount)
      .toString(16)
      .padStart(2, '0');
  return '#' + [0, 2, 4].map(i => mix(parseInt(value.slice(i, i + 2), 16))).join('');
}

/// Lowercase, accent-free prefixes for everything a person can be found by.
///
/// Firestore has no text search, so each word is expanded into its prefixes
/// and matched with a single `array-contains`. Words shorter than two letters
/// are dropped and the list is capped, because an array is also an index.
function searchTerms(profile, max = 120) {
  const source = [profile.name, profile.role, profile.company, profile.sector, profile.location]
    .filter(v => typeof v === 'string')
    .join(' ');
  const plain = source.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  const terms = new Set();
  for (const word of plain.split(/[^a-z0-9]+/)) {
    if (word.length < 2) continue;
    for (let i = 2; i <= Math.min(word.length, 14); i++) terms.add(word.slice(0, i));
    if (terms.size > max) break;
  }
  return [...terms].slice(0, max);
}

/// Normalises what somebody typed into the single term worth querying.
///
/// Only one `array-contains` is allowed per query, so the longest word goes to
/// the server and the rest narrow the result on the device.
function searchQuery(text) {
  const words = String(text ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(w => w.length >= 2);
  if (!words.length) return { term: '', rest: [] };
  const longest = words.reduce((a, b) => (b.length > a.length ? b : a));
  return {
    term: longest.slice(0, 14),
    rest: words.filter(w => w !== longest),
  };
}

module.exports = {
  fields,
  shade,
  searchTerms,
  searchQuery,
  safeUrl,
  snapshot,
  connectionId,
  escapeHtml,
  vcard,
  requestOutcome,
  respondOutcome,
  preview,
};
