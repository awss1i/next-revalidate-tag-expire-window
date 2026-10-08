# revalidateTag expire window repro

```bash
npm install
npm run repro
```

`repro.sh` builds the app once. For `/static` (a prerendered page) and `/dynamic` (reads a `'use cache'` function at request time) it calls `revalidateTag('t1', { expire: 15 })`, lets the next request regenerate the entry, and requests the page again after the 15 s window.

`data.txt` is changed to `Newer` after the regeneration, with no further revalidation, so `Newer` after the window means the regenerated entry was thrown away and rendered again.
