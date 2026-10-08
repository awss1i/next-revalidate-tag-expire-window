import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { cacheLife, cacheTag } from 'next/cache'

export async function getValue() {
  'use cache'
  cacheLife('max')
  cacheTag('t1')
  const value = readFileSync(join(process.cwd(), 'data.txt'), 'utf8').trim()
  console.log('[repro] getValue ran, value=' + value)
  return value
}
