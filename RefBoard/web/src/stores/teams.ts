import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { loadLocal, saveLocal } from '../utils/localPersist'
import { nextId } from '../utils/localId'
import type { Team, RosterMember } from '../types/local'

const KEY_TEAMS = 'teams'
const KEY_ROSTER = 'roster_members'

export const useTeamsStore = defineStore('teams', () => {
  const teams = ref<Team[]>(loadLocal<Team[]>(KEY_TEAMS, []))
  const rosters = ref<RosterMember[]>(loadLocal<RosterMember[]>(KEY_ROSTER, []))

  watch(teams, (v) => saveLocal(KEY_TEAMS, v), { deep: true })
  watch(rosters, (v) => saveLocal(KEY_ROSTER, v), { deep: true })

  function nowIso() {
    return new Date().toISOString()
  }

  function createTeam(input: { name: string; shortName?: string; colorHex?: string }): Team {
    const t: Team = {
      id: nextId('team'),
      name: input.name.trim(),
      shortName: input.shortName?.trim() || null,
      colorHex: input.colorHex || null,
      createdAt: nowIso(),
      updatedAt: nowIso(),
    }
    teams.value.push(t)
    return t
  }

  function updateTeam(id: number, patch: Partial<Team>) {
    const i = teams.value.findIndex((x) => x.id === id)
    if (i < 0) return
    teams.value[i] = { ...teams.value[i], ...patch, updatedAt: nowIso() }
  }

  function deleteTeam(id: number) {
    teams.value = teams.value.filter((t) => t.id !== id)
    rosters.value = rosters.value.filter((r) => r.teamId !== id)
  }

  function getTeam(id: number) {
    return teams.value.find((t) => t.id === id) || null
  }

  function rosterFor(teamId: number): RosterMember[] {
    return rosters.value.filter((r) => r.teamId === teamId)
  }

  function addRosterMember(
    teamId: number,
    input: { name: string; number?: number; position?: string; note?: string },
  ): RosterMember {
    const m: RosterMember = {
      id: nextId('rosterMember'),
      teamId,
      name: input.name.trim(),
      number: input.number ?? null,
      position: input.position?.trim() || null,
      note: input.note?.trim() || null,
    }
    rosters.value.push(m)
    return m
  }

  function updateRosterMember(id: number, patch: Partial<RosterMember>) {
    const i = rosters.value.findIndex((x) => x.id === id)
    if (i < 0) return
    rosters.value[i] = { ...rosters.value[i], ...patch }
  }

  function removeRosterMember(id: number) {
    rosters.value = rosters.value.filter((r) => r.id !== id)
  }

  function reload() {
    teams.value = loadLocal<Team[]>(KEY_TEAMS, [])
    rosters.value = loadLocal<RosterMember[]>(KEY_ROSTER, [])
  }

  return {
    teams,
    rosters,
    reload,
    createTeam,
    updateTeam,
    deleteTeam,
    getTeam,
    rosterFor,
    addRosterMember,
    updateRosterMember,
    removeRosterMember,
  }
})
