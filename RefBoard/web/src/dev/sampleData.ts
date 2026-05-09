import type { RosterMember } from '../types/local'

// ── チーム定義（10 チーム、欧州風架空名） ──
interface SeedTeam {
  name: string
  shortName: string
  colorHex: string
  nationality: 'de' | 'fr' | 'es' | 'it' | 'nl' | 'pt' | 'se' | 'be' | 'at' | 'pl'
}

export const SEED_TEAMS: SeedTeam[] = [
  { name: 'FC Drachenburg', shortName: 'DRB', colorHex: '#c81d25', nationality: 'de' },
  { name: 'AS Roselune', shortName: 'ROS', colorHex: '#0a3d62', nationality: 'fr' },
  { name: 'Real Sancavero', shortName: 'SCV', colorHex: '#f4a300', nationality: 'es' },
  { name: 'AC Pontevecchio', shortName: 'PVC', colorHex: '#1e3a8a', nationality: 'it' },
  { name: 'Ostervik IF', shortName: 'OST', colorHex: '#0e7c3a', nationality: 'se' },
  { name: 'SV Eichenfeld', shortName: 'EIC', colorHex: '#5b2a83', nationality: 'at' },
  { name: 'Sporting Aldemar', shortName: 'ALD', colorHex: '#0f766e', nationality: 'pt' },
  { name: 'KV Hesseldam', shortName: 'HES', colorHex: '#dc2626', nationality: 'nl' },
  { name: 'RKS Czarnogora', shortName: 'CZN', colorHex: '#facc15', nationality: 'pl' },
  { name: 'Standard Verviron', shortName: 'VER', colorHex: '#0369a1', nationality: 'be' },
]

// ── 国籍別の姓・名プール ──
const FIRST_NAMES: Record<SeedTeam['nationality'], string[]> = {
  de: ['Lukas', 'Felix', 'Jonas', 'Maximilian', 'Leon', 'Niklas', 'Tobias', 'Florian', 'Sebastian', 'Andreas', 'Dominik', 'Patrick', 'Stefan', 'Markus', 'Christoph'],
  fr: ['Antoine', 'Julien', 'Mathieu', 'Romain', 'Théo', 'Baptiste', 'Nicolas', 'Florian', 'Hugo', 'Pierre', 'Lucas', 'Guillaume', 'Alexandre', 'Maxime', 'Benjamin'],
  es: ['Carlos', 'Javier', 'Pablo', 'Sergio', 'Adrián', 'Álvaro', 'Miguel', 'Diego', 'Hugo', 'Iván', 'Rubén', 'Marcos', 'Mario', 'Daniel', 'Raúl'],
  it: ['Marco', 'Luca', 'Andrea', 'Matteo', 'Alessandro', 'Davide', 'Lorenzo', 'Simone', 'Federico', 'Stefano', 'Gabriele', 'Riccardo', 'Tommaso', 'Giulio', 'Filippo'],
  nl: ['Daan', 'Sem', 'Lucas', 'Milan', 'Jesse', 'Thijs', 'Stijn', 'Bram', 'Tim', 'Tom', 'Niels', 'Joost', 'Pieter', 'Ruben', 'Wouter'],
  pt: ['João', 'Tiago', 'Rui', 'Pedro', 'Bruno', 'André', 'Diogo', 'Miguel', 'Ricardo', 'Filipe', 'Hugo', 'Vasco', 'Nuno', 'Gonçalo', 'Tomás'],
  se: ['Erik', 'Anders', 'Johan', 'Magnus', 'Lars', 'Per', 'Henrik', 'Mattias', 'Oskar', 'Viktor', 'Linus', 'Anton', 'Gustav', 'Olof', 'Niklas'],
  be: ['Thomas', 'Maxime', 'Antoine', 'Jérôme', 'Romain', 'Florian', 'Xavier', 'Olivier', 'Vincent', 'Benoît', 'Loïc', 'Damien', 'Pascal', 'Mathieu', 'Fabrice'],
  at: ['Stefan', 'Markus', 'Christian', 'Andreas', 'Michael', 'Lukas', 'Florian', 'Patrick', 'Daniel', 'Sebastian', 'Manuel', 'Tobias', 'Philip', 'Bernhard', 'Wolfgang'],
  pl: ['Jakub', 'Mateusz', 'Piotr', 'Krzysztof', 'Tomasz', 'Michał', 'Łukasz', 'Paweł', 'Marcin', 'Adam', 'Bartosz', 'Wojciech', 'Kamil', 'Rafał', 'Dominik'],
}

const LAST_NAMES: Record<SeedTeam['nationality'], string[]> = {
  de: ['Müller', 'Schmidt', 'Weber', 'Becker', 'Hoffmann', 'Schäfer', 'Wagner', 'Bauer', 'Richter', 'Klein', 'Wolf', 'Neumann', 'Fischer', 'Lang', 'Köhler'],
  fr: ['Martin', 'Bernard', 'Dubois', 'Petit', 'Durand', 'Leroy', 'Moreau', 'Laurent', 'Simon', 'Lefebvre', 'Roux', 'Vincent', 'Fournier', 'Girard', 'Bonnet'],
  es: ['García', 'Martínez', 'López', 'Sánchez', 'Pérez', 'Gómez', 'Fernández', 'Jiménez', 'Hernández', 'Ruiz', 'Díaz', 'Moreno', 'Álvarez', 'Romero', 'Navarro'],
  it: ['Rossi', 'Russo', 'Ferrari', 'Esposito', 'Bianchi', 'Romano', 'Colombo', 'Greco', 'Conti', 'De Luca', 'Mancini', 'Costa', 'Giordano', 'Rizzo', 'Lombardi'],
  nl: ['de Jong', 'van Dijk', 'Bakker', 'Janssen', 'Visser', 'Smit', 'Meijer', 'de Vries', 'de Boer', 'Mulder', 'Kok', 'Jacobs', 'van Leeuwen', 'Hendriks', 'Dekker'],
  pt: ['Silva', 'Santos', 'Ferreira', 'Pereira', 'Oliveira', 'Costa', 'Rodrigues', 'Martins', 'Almeida', 'Carvalho', 'Sousa', 'Gonçalves', 'Pinto', 'Lopes', 'Marques'],
  se: ['Andersson', 'Johansson', 'Karlsson', 'Nilsson', 'Eriksson', 'Larsson', 'Olsson', 'Persson', 'Svensson', 'Gustafsson', 'Pettersson', 'Jonsson', 'Jansson', 'Hansson', 'Bengtsson'],
  be: ['Janssens', 'Peeters', 'Maes', 'Jacobs', 'Mertens', 'Willems', 'Claes', 'Goossens', 'Wouters', 'De Smet', 'Dubois', 'Lambert', 'Dupont', 'Martens', 'Lemmens'],
  at: ['Gruber', 'Huber', 'Bauer', 'Wagner', 'Mayr', 'Steiner', 'Moser', 'Hofer', 'Berger', 'Fuchs', 'Eder', 'Lang', 'Reiter', 'Schmid', 'Wimmer'],
  pl: ['Nowak', 'Kowalski', 'Wiśniewski', 'Wójcik', 'Kowalczyk', 'Kamiński', 'Lewandowski', 'Zieliński', 'Szymański', 'Woźniak', 'Dąbrowski', 'Kozłowski', 'Mazur', 'Krawczyk', 'Piotrowski'],
}

const POSITIONS: Array<NonNullable<RosterMember['position']>> = [
  'GK',
  'DF',
  'DF',
  'DF',
  'DF',
  'MF',
  'MF',
  'MF',
  'MF',
  'MF',
  'FW',
  'FW',
  'FW',
]

export interface SeedRosterRow {
  number: number
  name: string
  position: string
}

/** チームごとに 13 名固定生成。同じシードから何度呼んでも同じ結果になるよう純粋関数。 */
export function buildSeedRoster(team: SeedTeam): SeedRosterRow[] {
  const firsts = FIRST_NAMES[team.nationality]
  const lasts = LAST_NAMES[team.nationality]
  const rows: SeedRosterRow[] = []
  for (let i = 0; i < 13; i++) {
    const f = firsts[(i * 3) % firsts.length]
    const l = lasts[(i * 7) % lasts.length]
    rows.push({
      number: i + 1,
      name: `${f} ${l}`,
      position: POSITIONS[i] ?? 'MF',
    })
  }
  return rows
}

// ── 試合シード ──
export interface SeedMatch {
  title: string
  homeIndex: number
  awayIndex: number
  status: 'draft' | 'live' | 'finished'
  homeScore: number
  awayScore: number
  liveElapsedMinutes?: number
  finishedGoals?: { home: number; away: number }
  scheduledOffsetDays?: number
}

export const SEED_MATCHES: SeedMatch[] = [
  { title: 'リーグ第1節 第1試合', homeIndex: 0, awayIndex: 1, status: 'finished', homeScore: 2, awayScore: 1, finishedGoals: { home: 2, away: 1 } },
  { title: 'リーグ第1節 第2試合', homeIndex: 2, awayIndex: 3, status: 'finished', homeScore: 0, awayScore: 0, finishedGoals: { home: 0, away: 0 } },
  { title: 'リーグ第1節 第3試合', homeIndex: 4, awayIndex: 5, status: 'finished', homeScore: 3, awayScore: 2, finishedGoals: { home: 3, away: 2 } },
  { title: 'リーグ第1節 第4試合', homeIndex: 6, awayIndex: 7, status: 'finished', homeScore: 1, awayScore: 0, finishedGoals: { home: 1, away: 0 } },
  { title: 'リーグ第1節 第5試合', homeIndex: 8, awayIndex: 9, status: 'finished', homeScore: 2, awayScore: 2, finishedGoals: { home: 2, away: 2 } },
  { title: 'リーグ第2節 第1試合', homeIndex: 1, awayIndex: 2, status: 'finished', homeScore: 1, awayScore: 1, finishedGoals: { home: 1, away: 1 } },
  { title: 'リーグ第2節 第2試合', homeIndex: 3, awayIndex: 4, status: 'finished', homeScore: 0, awayScore: 1, finishedGoals: { home: 0, away: 1 } },
  { title: 'リーグ第2節 第3試合', homeIndex: 5, awayIndex: 6, status: 'finished', homeScore: 2, awayScore: 0, finishedGoals: { home: 2, away: 0 } },
  { title: 'リーグ第2節 第4試合', homeIndex: 7, awayIndex: 8, status: 'finished', homeScore: 3, awayScore: 1, finishedGoals: { home: 3, away: 1 } },
  { title: 'リーグ第2節 第5試合', homeIndex: 9, awayIndex: 0, status: 'finished', homeScore: 1, awayScore: 2, finishedGoals: { home: 1, away: 2 } },
  { title: '練習試合 A', homeIndex: 0, awayIndex: 5, status: 'finished', homeScore: 2, awayScore: 0, finishedGoals: { home: 2, away: 0 } },
  { title: '練習試合 B', homeIndex: 3, awayIndex: 8, status: 'finished', homeScore: 1, awayScore: 1, finishedGoals: { home: 1, away: 1 } },
  { title: 'カップ戦 1回戦 第1試合', homeIndex: 1, awayIndex: 4, status: 'live', homeScore: 1, awayScore: 0, liveElapsedMinutes: 20 },
  { title: 'カップ戦 1回戦 第2試合', homeIndex: 2, awayIndex: 7, status: 'live', homeScore: 0, awayScore: 0, liveElapsedMinutes: 46 },
  { title: 'カップ戦 1回戦 第3試合', homeIndex: 6, awayIndex: 9, status: 'live', homeScore: 2, awayScore: 1, liveElapsedMinutes: 78 },
  { title: 'リーグ第3節 第1試合', homeIndex: 0, awayIndex: 2, status: 'draft', homeScore: 0, awayScore: 0, scheduledOffsetDays: 1 },
  { title: 'リーグ第3節 第2試合', homeIndex: 3, awayIndex: 5, status: 'draft', homeScore: 0, awayScore: 0, scheduledOffsetDays: 2 },
  { title: 'リーグ第3節 第3試合', homeIndex: 4, awayIndex: 6, status: 'draft', homeScore: 0, awayScore: 0, scheduledOffsetDays: 3 },
  { title: 'リーグ第3節 第4試合', homeIndex: 7, awayIndex: 9, status: 'draft', homeScore: 0, awayScore: 0, scheduledOffsetDays: 4 },
  { title: 'リーグ第3節 第5試合', homeIndex: 8, awayIndex: 1, status: 'draft', homeScore: 0, awayScore: 0, scheduledOffsetDays: 5 },
]
