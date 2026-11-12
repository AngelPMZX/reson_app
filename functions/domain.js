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

module.exports = {
  fields,
  safeUrl,
  snapshot,
  connectionId,
  escapeHtml,
  vcard,
  requestOutcome,
  respondOutcome,
};
