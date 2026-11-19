function whoAmI(request, env) {
  const auth = request.headers.get('Authorization');
  if (env.TOKEN_BLUE && auth === `Bearer ${env.TOKEN_BLUE}`) return 'blue';
  if (env.TOKEN_YELLOW && auth === `Bearer ${env.TOKEN_YELLOW}`) return 'yellow';
  return null;
}


export default {
  async fetch(request, env) {
    const me = whoAmI(request, env);
    if (!me) return new Response('Unauthorized', { status: 401 });
    const other = me === 'blue' ? 'yellow' : 'blue';
    // Every request must carry the shared token
    
    const url = new URL(request.url);
    const path = url.pathname.split('/').filter(Boolean); // e.g. ['photos', id, 'image']
        // ---------------- Letters ----------------
    if (path[0] === 'letters') {
      // GET /letters -> letters I sent or received (without the full text)
      if (request.method === 'GET' && path.length === 1) {
        const listed = await env.LETTERS.list({ limit: 1000, include: ['customMetadata'] });
        const letters = listed.objects
          .filter((o) => o.customMetadata?.from === me || o.customMetadata?.to === me)
          .map((o) => ({
            id: o.key,
            from: o.customMetadata.from,
            to: o.customMetadata.to,
            sentAt: o.customMetadata.sentAt,
            readAt: o.customMetadata.readAt || null,
            preview: o.customMetadata.preview ?? '',
          }));
        return Response.json(letters);
      }

      // POST /letters -> send a letter to the other person
      if (request.method === 'POST' && path.length === 1) {
        const body = await request.json();
        const text = typeof body.text === 'string' ? body.text.trim() : '';
        if (!text) return new Response('Empty letter', { status: 400 });

        const id = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
        const letter = {
          id,
          from: me,
          to: other,
          sentAt: new Date().toISOString(),
          text: text.slice(0, 5000),
          items: [], // stickers / drawings / photos come in phase 2
        };

        await env.LETTERS.put(id, JSON.stringify(letter), {
          httpMetadata: { contentType: 'application/json' },
          customMetadata: {
            from: me,
            to: other,
            sentAt: letter.sentAt,
            preview: text.replace(/\s+/g, ' ').slice(0, 80),
          },
        });
        return Response.json({ id }, { status: 201 });
      }

      // GET /letters/:id -> the full letter (marks it read for the recipient)
      if (request.method === 'GET' && path.length === 2) {
        const object = await env.LETTERS.get(path[1]);
        if (!object) return new Response('Not found', { status: 404 });

        const meta = { ...object.customMetadata };
        if (meta.from !== me && meta.to !== me) {
          return new Response('Not found', { status: 404 }); // not your letter
        }

        const letter = await object.json();

        if (meta.to === me && !meta.readAt) {
          meta.readAt = new Date().toISOString();
          await env.LETTERS.put(path[1], JSON.stringify(letter), {
            httpMetadata: { contentType: 'application/json' },
            customMetadata: meta,
          });
        }
        return Response.json({ ...letter, readAt: meta.readAt || null });
      }

      return new Response('Not found', { status: 404 });
    }

    if (path[0] !== 'photos') return new Response('Not found', { status: 404 });

    // GET /photos -> list of {id, description, date}
    if (request.method === 'GET' && path.length === 1) {
      const listed = await env.PHOTOS.list({ limit: 1000, include: ['customMetadata'] });
      const photos = listed.objects.map((o) => ({
        id: o.key,
        title: o.customMetadata?.title ?? '',
        description: o.customMetadata?.description ?? '',
        date: o.customMetadata?.date ?? o.uploaded.toISOString(),
      }));
      return Response.json(photos);
    }

    // POST /photos -> upload (image bytes in the body, details in headers)
    if (request.method === 'POST' && path.length === 1) {
      const id = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
      await env.PHOTOS.put(id, request.body, {
        httpMetadata: { contentType: request.headers.get('Content-Type') || 'image/jpeg' },
        customMetadata: {
            title: decodeURIComponent(request.headers.get('X-Title') || ''),
            description: decodeURIComponent(request.headers.get('X-Description') || ''),
            date: request.headers.get('X-Date') || new Date().toISOString(),
        },
      });
      return Response.json({ id }, { status: 201 });
    }

    // GET /photos/:id/image -> the image itself
    if (request.method === 'GET' && path.length === 3 && path[2] === 'image') {
      const object = await env.PHOTOS.get(path[1]);
      if (!object) return new Response('Not found', { status: 404 });
      return new Response(object.body, {
        headers: {
          'Content-Type': object.httpMetadata?.contentType ?? 'image/jpeg',
          'Cache-Control': 'private, max-age=31536000, immutable',
        },
      });
    }

    if (request.method === 'PATCH' && path.length === 2) {
      const existing = await env.PHOTOS.get(path[1]);
      if (!existing) return new Response('Not found', { status: 404 });

      const changes = await request.json();
      const meta = { ...existing.customMetadata };
      for (const field of ['title', 'description', 'date']) {
        if (typeof changes[field] === 'string') meta[field] = changes[field];
      }

      // Read the whole file first, then write it back with the new metadata
      const data = await existing.arrayBuffer();
      await env.PHOTOS.put(path[1], data, {
        httpMetadata: existing.httpMetadata,
        customMetadata: meta,
      });

      return Response.json({ id: path[1] });
    }

    // DELETE /photos/:id
    if (request.method === 'DELETE' && path.length === 2) {
      await env.PHOTOS.delete(path[1]);
      return new Response(null, { status: 204 });
    }

    return new Response('Not found', { status: 404 });

  },
};