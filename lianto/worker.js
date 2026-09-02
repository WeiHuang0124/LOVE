/* 戀途 — Cloudflare Worker
   靜態檔案（public/）預設優先，比對不到才會進到這裡。
   所以 /api/ig 會落到這支，其餘一律由 ASSETS 提供。 */

const CORS = {
  'access-control-allow-origin': '*',
  'cache-control': 'public, max-age=86400',
  'content-type': 'application/json; charset=utf-8'
};

/* 代抓 IG 貼文資訊。
   Meta 2026/6/15 起 oEmbed 免 token，但瀏覽器直接打會被 CORS 擋，所以繞這一手。 */
async function ig(request) {
  const url = new URL(request.url).searchParams.get('url');
  if (!url || !/instagram\.com\/(p|reel|reels|tv)\//.test(url)) {
    return new Response(JSON.stringify({ error: 'bad url' }), { status: 400, headers: CORS });
  }
  const api = 'https://graph.facebook.com/v23.0/instagram_oembed'
            + '?url=' + encodeURIComponent(url)
            + '&omitscript=true&fields=author_name,title,thumbnail_url';
  try {
    const r = await fetch(api, { cf: { cacheTtl: 86400, cacheEverything: true } });
    const j = await r.json();
    return new Response(JSON.stringify({
      author:  j.author_name   || '',
      caption: j.title         || '',
      thumb:   j.thumbnail_url || ''
    }), { headers: CORS });
  } catch (e) {
    return new Response(JSON.stringify({ author: '', caption: '', thumb: '' }), { headers: CORS });
  }
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/api/ig') return ig(request);
    return env.ASSETS.fetch(request);
  }
};
