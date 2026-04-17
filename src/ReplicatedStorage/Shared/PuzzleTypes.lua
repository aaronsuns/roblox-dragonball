--!strict

export type PuzzleKind = "Multiplication" | "RpsBestOf3"

export type MultiplicationPayload = {
	a: number,
	b: number,
	expiresAtUnix: number,
}

export type RpsPayload = {
	yourWins: number,
	oppWins: number,
	roundIndex: number,
	maxRounds: number,
	expiresAtUnix: number,
}

return nil
