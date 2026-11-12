'use strict';
const { escapeHtml: e, shade, mix, credentialSkin } = require('./domain');

/// The flowing lines the aurora and signature credentials are painted with,
/// as inline SVG so the page stays one request and scales to any width.
function waves(accent) {
  let paths = '';
  for (let i = 0; i < 8; i++) {
    const y = 60 + i * 18;
    paths +=
      `<path d="M-40 ${y} C 230 ${-30 + i * 6}, 370 ${250 - i * 4}, 620 ${90 + i * 22}" ` +
      `stroke="${accent}" stroke-opacity="${(0.13 + i * 0.014).toFixed(3)}" ` +
      `stroke-width="${14 - i}" fill="none"/>`;
  }
  return (
    `<svg class="art" viewBox="0 0 560 320" preserveAspectRatio="none" ` +
    `aria-hidden="true" focusable="false">${paths}</svg>`
  );
}

/// The arcs the other layouts use, so a card is never drawn on a bare panel.
function arcs(accent) {
  let circles = '';
  for (let i = 0; i < 5; i++) {
    circles +=
      `<circle cx="540" cy="20" r="${45 + i * 22}" fill="none" ` +
      `stroke="${accent}" stroke-opacity="0.22" stroke-width="2"/>`;
  }
  return (
    `<svg class="art" viewBox="0 0 560 320" preserveAspectRatio="none" ` +
    `aria-hidden="true" focusable="false">${circles}</svg>`
  );
}

module.exports = function render(p, id, origin, english = false) {
  const t = (es, en) => (english ? en : es);
  const base = origin + '/c/' + id;
  const phone = p.phone.replace(/[^+0-9]/g, '');
  // The page draws the credential its owner designed rather than a generic
  // panel in Reson's own colours, using the same skin table the app uses.
  const skin = credentialSkin(p.color, p.layout);
  const accent = shade(p.color, 0);
  const deep = shade(p.color, -0.72);
  const art = ['aurora', 'signature', 'bold', 'classic'].includes(p.layout)
    ? waves(skin.ink)
    : arcs(skin.ink);
  const line = v => (v ? `<p>${e(v)}</p>` : '');
  const kind =
    p.kind === 'freelance'
      ? t('FREELANCE', 'FREELANCE')
      : p.kind === 'personal'
        ? t('PERSONAL', 'PERSONAL')
        : t('PROFESIONAL', 'PROFESSIONAL');

  // Contact rows live on the credential, as the card shows them.
  // The card shows whatever its owner typed. A phone with no digits cannot
  // be dialled, but hiding it would show less on the web than on the card.
  const rows = [
    p.email && ['@', p.email, 'mailto:' + encodeURIComponent(p.email)],
    p.phone && ['✆', p.phone, phone ? 'tel:' + phone : ''],
    p.website && ['⊕', p.website, p.website],
  ].filter(Boolean);

  const actions = [
    [base + '/contact.vcf', t('Guardar contacto', 'Save contact')],
    p.whatsapp && phone && ['https://wa.me/' + phone.replace(/\D/g, ''), 'WhatsApp'],
    [origin + '/#/receive/' + id, t('Guardar en Reson · Conectar', 'Save in Reson · Connect')],
  ].filter(Boolean);

  const pro = p.professional;
  let extra = '';
  for (const [key, label] of [
    ['sector', t('Sector', 'Industry')],
    ['specialty', t('Especialidades', 'Specialties')],
    ['workMode', t('Modalidad', 'Work mode')],
    ['location', t('Ubicación', 'Location')],
    ['skills', t('Habilidades', 'Skills')],
  ])
    if (pro[key]) extra += `<section><h2>${label}</h2><p>${e(pro[key])}</p></section>`;
  for (const [key, label] of [
    ['experience', t('Experiencia', 'Experience')],
    ['education', t('Educación', 'Education')],
    ['projects', t('Proyectos', 'Projects')],
    ['certifications', t('Certificaciones', 'Certifications')],
  ])
    if (pro[key]?.length)
      extra += `<section><h2>${label}</h2>${pro[key]
        .map(
          v =>
            `<article><h3>${e(v.title)}</h3><p>${e(v.organization)}</p>` +
            `<small>${e(v.period)}</small>${line(v.details)}</article>`,
        )
        .join('')}</section>`;
  if (pro.linkedin)
    extra += `<a class="button secondary" href="${e(pro.linkedin)}" rel="noopener noreferrer">LinkedIn ↗</a>`;

  return `<!doctype html><html lang="${english ? 'en' : 'es'}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>${e(p.name)} · Reson</title><meta name="description" content="${e(p.role || p.label)}"><style>
 :root{color-scheme:light dark;--accent:${accent};--deep:${deep};--surface:${skin.surface};--ink:${skin.ink};--muted:${skin.muted};--veil:${mix(skin.surface, skin.ink, 0.1)}}
 *{box-sizing:border-box}body{margin:0;background:#101012;color:#faf9f7;font:16px/1.55 system-ui,sans-serif}
 main{max-width:560px;margin:auto;padding:24px 18px 60px}
 .brand{display:flex;justify-content:space-between;align-items:center;margin-bottom:20px}
 .brand strong{font-size:25px;letter-spacing:-1px}.brand a{color:#c6c1c4}
 .card{position:relative;overflow:hidden;border-radius:26px;background:var(--surface);color:var(--ink);padding:26px;min-height:330px;display:flex;flex-direction:column;animation:enter .6s ease-out;box-shadow:0 18px 40px rgba(0,0,0,.35)}
 .art{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
 .card>*{position:relative}
 .top{display:flex;justify-content:space-between;align-items:center;font-size:12px;letter-spacing:1.4px;color:var(--muted)}
 .mark{display:flex;align-items:center;gap:9px;font-weight:700}
 .bars{display:flex;align-items:flex-end;gap:2px;height:15px}
 .bars i{width:3px;background:var(--ink);border-radius:2px;opacity:.9}
 .face{width:86px;height:86px;border-radius:50%;object-fit:cover;border:3px solid var(--ink);margin:22px 0 0}
 .initial{display:grid;place-items:center;background:var(--accent);color:#fff;font-size:34px;font-weight:700}
 h1{font-size:33px;line-height:1.1;letter-spacing:-1.1px;margin:20px 0 8px;color:var(--ink)}
 .card p{margin:2px 0;color:var(--muted)}
 .rule{height:1px;background:var(--ink);opacity:.22;margin:20px 0 16px}
 .rows{display:grid;gap:9px}
 .row{display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:13px;background:var(--veil);color:var(--ink);text-decoration:none;font-size:14px;overflow-wrap:anywhere}
 .row span{opacity:.75;width:17px;text-align:center}
 .foot{margin-top:auto;padding-top:20px;font-size:11px;letter-spacing:1.6px;color:var(--muted)}
 .foot b{color:var(--accent)}
 nav{display:grid;gap:10px;margin:22px 0}
 .button{display:block;text-align:center;padding:15px 18px;border-radius:16px;color:white;background:var(--accent);text-decoration:none;font-weight:650;transition:transform .18s}
 .button:hover{transform:translateY(-2px)}.secondary{background:#29292d}
 h2{font-size:18px}h3{margin-bottom:0}
 p{white-space:pre-wrap;overflow-wrap:anywhere;margin:8px 0;color:#c6c1c4}
 section{padding:20px 0;border-bottom:1px solid #454045}
 article{border-left:2px solid var(--accent);padding-left:16px;margin:20px 0}
 small,footer{color:#c6c1c4}footer{margin-top:30px;font-size:12px;text-align:center}
 @keyframes enter{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
 @media(prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
 @media(prefers-color-scheme:light){body{background:#faf9f7;color:#101012}p,small,footer{color:#6c686b}h2{color:var(--deep)}.secondary{background:#29292d}}
 </style><main><div class="brand"><strong>reson</strong><a href="${base}?lang=${english ? 'es' : 'en'}">${english ? 'Español' : 'English'}</a></div><div class="card">${art}<div class="top"><span class="mark"><span class="bars"><i style="height:7px"></i><i style="height:13px"></i><i style="height:9px"></i><i style="height:15px"></i><i style="height:6px"></i></span>${e(p.label)}</span></div>${p.photo ? `<img class="face" src="${base}/photo" alt="${e(p.name)}">` : `<div class="face initial">${e([...p.name][0] || 'R')}</div>`}<h1>${e(p.name)}</h1>${line(p.role)}${line(p.company)}${p.bio ? `<p>${e(p.bio)}</p>` : ''}${rows.length ? `<div class="rule"></div><div class="rows">${rows.map(([icon, text, url]) => (url ? `<a class="row" href="${e(url)}" rel="noopener noreferrer"><span>${icon}</span>${e(text)}</a>` : `<div class="row"><span>${icon}</span>${e(text)}</div>`)).join('')}</div>` : ''}<div class="foot"><b>●</b> RESON / ${kind}</div></div><nav>${actions.map(([url, label], i) => `<a class="button ${i ? 'secondary' : ''}" href="${e(url)}" rel="noopener noreferrer">${label}</a>`).join('')}</nav>${extra}<footer>${t('Tarjeta compartida por su titular. Guardar no envía ningún mensaje.', 'Shared by its owner. Saving does not send a message.')}<br>RESON · THEDARKINGSTUDIOS</footer></main></html>`;
};
