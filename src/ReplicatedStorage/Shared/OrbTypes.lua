--!strict

export type StarCount = number

export type OrbState = "Available" | "LockedPuzzle" | "Collected"

export type OrbRecord = {
	id: string,
	star: StarCount,
	state: OrbState,
	ownerUserId: number?,
}

return nil
