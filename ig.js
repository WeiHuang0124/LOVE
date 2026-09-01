/* Cloudflare Pages Function：代抓 IG 貼文資訊
   Meta 2026/6/15 起 oEmbed 免 token，但瀏覽器直接打會被 CORS 擋，所以繞一手。
   路徑自動對應 /api/ig?url=<貼文網址> */
export async function onRequestGet(context) {
  const url = new URL(context.request.url).searchParams.get('url');
  const cors = {
    'access-control-allow-origin': '*',
    'cache-control': 'public, max-age=86400',
    'content-type': 'application/json; charset=utf-8'
  };
  if (!url || !/instagram\.com\/(p|reel|reels|tv)\//.test(url)) {
    return new Response(JSON.stringify({ error: 'bad url' }), { status: 400, headers: cors });
  }

  const api = 'https://graph.facebook.com/v23.0/instagram_oembed'
            + '?url=' + encodeURIComponent(url)
            + '&omitscript=true&fields=author_name,title,thumbnail_url';

  try {
    const r = await fetch(api, { cf: { cacheTtl: 86400 } });
    const j = await r.json();
    return new Response(JSON.stringify({
      author:  j.author_name  || '',
      caption: j.title        || '',
      thumb:   j.thumbnail_url || ''
    }), { headers: cors });
  } catch (e) {
    return new Response(JSON.stringify({ author: '', caption: '', thumb: '' }), { headers: cors });
  }
}
