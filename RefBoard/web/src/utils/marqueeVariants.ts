/** Sprint 08 設計書の初期値。実機テスト後の調整は VARIANTS のみを変更する。 */
export type MarqueeVariant = 'default' | 'scoreboard' | 'ticker' | 'subtle'

export const VARIANTS: Record<MarqueeVariant, { speed: number; gap: number; delay: number }> = {
  default: { speed: 40, gap: 48, delay: 1000 },
  scoreboard: { speed: 28, gap: 64, delay: 2200 },
  ticker: { speed: 60, gap: 32, delay: 500 },
  subtle: { speed: 35, gap: 40, delay: 1500 },
}

export function resolveMarqueeTiming(
  variant: MarqueeVariant,
  overrides: { speed?: number; gap?: number; delay?: number },
): { speed: number; gap: number; delay: number } {
  const b = VARIANTS[variant]
  return {
    speed: overrides.speed ?? b.speed,
    gap: overrides.gap ?? b.gap,
    delay: overrides.delay ?? b.delay,
  }
}
