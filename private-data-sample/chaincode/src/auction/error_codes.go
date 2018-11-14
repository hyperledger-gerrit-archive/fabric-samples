/*
* Copyright Persistent Systems 2018. All Rights Reserved.
* 
* SPDX-License-Identifier: Apache-2.0
*/


package main

/*-------- This file maintains all error codes ----------*/

/*--- GENERAL ERROR CODES ----*/

/* To handle error while fetching from ledger */
type ErrFetchFromLedger struct{
	message string
}

func NewErrFetchFromLedger (message string) *ErrFetchFromLedger{
	return &ErrFetchFromLedger{
		message:message,
	}
}
func (e *ErrFetchFromLedger) Error() string{
	return e.message
}

/* To handle ledger key mismatch */
type ErrLedgerKeyMismatch struct{
	message string
}

func NewErrLedgerKeyMismatch (message string) *ErrLedgerKeyMismatch{
	return &ErrLedgerKeyMismatch{
		message:message,
	}
}
func (e *ErrLedgerKeyMismatch) Error() string{
	return e.message
}

/* To handle error while marshalling */
type ErrUnmarshal struct{
	message string
}

func NewErrUnmarshal (message string) *ErrUnmarshal{
	return &ErrUnmarshal{
		message:message,
	}
}
func (e *ErrUnmarshal) Error() string{
	return e.message
}


/* To handle error while marshalling object */
type ErrMarshal struct{
	message string
}

func NewErrMarshal (message string) *ErrMarshal{
	return &ErrMarshal{
		message:message,
	}
}
func (e *ErrMarshal) Error() string{
	return e.message
}

/* To handle error while setting event */
type ErrSetEvent struct{
	message string
}

func NewErrSetEvent (message string) *ErrSetEvent{
	return &ErrSetEvent{
		message:message,
	}
}
func (e *ErrSetEvent) Error() string{
	return e.message
}
