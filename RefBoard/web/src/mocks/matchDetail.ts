import type { MatchDetailModel } from '../types/match'

export const mockMatchDetail: MatchDetailModel = {
  id: 1,
  team1Id: 1,
  team2Id: 2,
  matchName: 'リーグ戦 第7節',
  venue: 'Maze Bank Arena',
  matchDate: '2026-05-05',
  kickoffTime: '20:00',
  uiStatus: 'second_half',
  home: { name: 'Los Santos FC', short: 'LS', isHome: true },
  away: { name: 'Vinewood United', short: 'VW', isHome: false },
  score: { home: 2, away: 1 },
  clockLabel: '試合終了',
  clockMmSs: '90:00',
  breakdown: {
    firstHalf: { home: 1, away: 0 },
    secondHalf: { home: 1, away: 1 },
    extra: { home: 0, away: 0 },
    pk: { home: 0, away: 0 },
  },
  serverHalf: '2nd',
  pkFirstTeamId: 1,
  homePlayers: [
    { id: '101', number: 1, name: 'Alex Rivera', position: 'GK', status: 'playing', yellowCards: 0 },
    { id: '102', number: 10, name: 'James Brown', position: 'FW', status: 'warning', yellowCards: 1 },
    { id: '103', number: 7, name: 'Matthew Jackson', position: 'MF', status: 'warning', yellowCards: 1 },
    { id: '104', number: 4, name: 'Chris Lee', position: 'DF', status: 'playing', yellowCards: 0 },
  ],
  awayPlayers: [
    { id: '201', number: 9, name: 'Samuel Green', position: 'FW', status: 'sent_off', yellowCards: 2 },
    { id: '202', number: 6, name: 'Daniel White', position: 'MF', status: 'playing', yellowCards: 0 },
    { id: '203', number: 3, name: 'Ryan Scott', position: 'DF', status: 'bench', yellowCards: 0 },
  ],
  dbStatus: 'draft',
  events: [
    { id: 'e1', minute: "15'", kind: 'goal', text: '⚽ 10 James Brown' },
    { id: 'e2', minute: "32'", kind: 'yellow', text: '🟨 7 Matthew Jackson' },
    { id: 'e3', minute: "45+1'", kind: 'goal', text: '⚽ 9 Samuel Green' },
    { id: 'e4', minute: "78'", kind: 'goal', text: '⚽ 4 Chris Lee' },
  ],
}
