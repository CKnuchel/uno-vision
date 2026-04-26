package errors

import "errors"

var (
	ErrPlayerNotFound       = errors.New("player not found")
	ErrPartyNotFound        = errors.New("party not found")
	ErrPartyNotJoinable     = errors.New("party is not joinable")
	ErrPartyAlreadyStarted  = errors.New("party already started")
	ErrPartyNotFinished     = errors.New("party not finished")
	ErrPlayerAlreadyInParty = errors.New("player is already in party")
	ErrPlayerNotInParty     = errors.New("player is not in party")
	ErrNotHost              = errors.New("only host can start the party")
	ErrNotEnoughPlayers     = errors.New("need at least 2 players")
	ErrGameNotStarted       = errors.New("game is not started")
	ErrAlreadySubmitted     = errors.New("player already submitted score")
	ErrWinnerCannotSubmit   = errors.New("winner cannot submit score")
	ErrRoundNotFound        = errors.New("round not found")
	ErrInvalidScore         = errors.New("score need to be bigger than 0")
	ErrCannotLeaveDuringGame = errors.New("cannot leave during active game")
)
