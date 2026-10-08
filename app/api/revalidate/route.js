import { revalidateTag } from 'next/cache'

export async function GET(request) {
  const expire = Number(new URL(request.url).searchParams.get('expire'))
  revalidateTag('t1', { expire })
  return Response.json({ expire, now: Date.now() })
}
