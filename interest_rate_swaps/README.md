# Interest-rate swaps

This is a sample of how interest-rate swaps can be handled on a blockchain using
fabric and state-based endorsement.

An interest-rate swap is a financial swap traded over the counter. It is a
contractual agreement between two parties, where two parties (A and B) exchange
payments. The height of the payments is based on the principal amount of the
swap and an interest rate. The interest rates of the two parties differ. In a
typical scenario, one payment (A to B) is based on a fixed rate set in the
contract. The other payment (B to A) is based on a floating rate. This rate is
defined through a reference rate, such as LIBOR from LSE, and an offset to this
rate.

## Network

We assume organizations of the following roles participate in our network:
 * Parties that want to exchange payments
 * Parties that provide reference rates
 * Auditors that need to audit certain swaps

The chaincode-level endorsement policy is set to require an endorsement from any
auditor as well as an endorsement from either a swap participant or a reference
rate provider.

## Data model
We represent a swap on the ledger as a JSON with the following fields:
 * `StartDate` and `EndDate` of the swap
 * `PaymentInterval` - the time interval of the payments
 * `PrincipalAmount` - the principal amount of the swap
 * `FixedRate` - the fixed rate of the swap
 * `FloatingRate` - the floating rate of the swap (offset to the reference rate)
 * `ReferenceRate` - a pointer to the reference rate

The key for the swap is a unique identifier combined with a common prefix. Upon
creation the key-level endorsement policy for swap is set to the participants
of the swap and, potentially, an auditor.

We represent the payment information as a single KVS entry per swap with the
same unique identifier as the swap itself and a common prefix for payments.
If payments are due, the entry states the amount due. Otherwise, it is nil.
The payment information KVS entries have the same key-level endorsement policy
set as their corresponding swap entry.

We represent the reference rates as a KVS entry per rate with an identifier per
rate and a common prefix for reference rates. The key-level endorsement policy
for a reference rate entry is set to the provider of the corresponding reference
rate, such as LSE for LIBOR.

## Chaincode
The interest-rate swap chaincode provides the following API:
 * `createSwap(swapID, swap_info, partyA, partyB)` - create a new swap with the
   given identifier and swap parameters among the two parties specified. This
   function creates the entry for the swap and the corresponding payment. It
   also sets the key-level endorsement policies for both keys to the participants
   to the swap. In case the swap's prinicpal amount exceeds a certain threshold,
   it adds an auditor to the endorsement policy for the keys.
 * `calculatePayment(swapID)` - calculate the net payment from party A to party
   B and set the payment key accordingly. If the payment information is negative,
   the payment due flows from B to A. The payment information is calculated based
   on the rates specified in the swap and the principal amount. If the payment
   key is not nil, this function returns an error, indicating that a prior
   payment has not been settled yet.
 * `settlePayment(swapID)` - set the payment key for the given swap ID to nil.
   This function is supposed to be invoked after the two parties have settled the
   payment off-chain.
 * `setReferenceRate(rrID, value)` - set a given reference rate to a given value.
 * `Init(threshold, rrProviders...)` - the chaincode namespace is initialized
   with a threshold for the principal amount above which an auditor needs to be
   involved as well as a list of reference rate providers.

## Trust model
The state-based endorsement policies used in this sample ensure the following trust model:
 * All operations related to a specific swap need to be endorsed (at least) by
   the participants to that swap. This includes both creation of a swap, as well
   as calculating the payment information and agreeing that the payments have
   been settled.
 * Operations related to a reference rate need to be endorsed by the provider of
   a reference rate.
 * Under certain circumstances an auditor needs to endorse operations for a swap,
   e.g., if it exceeds a threshold for the principal amount.
