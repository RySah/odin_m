package async

import "base:intrinsics"

Cancellation_Token :: distinct ^bool

cancellation_requested :: proc(token: Cancellation_Token) -> bool {
    return token != nil && intrinsics.atomic_load(token)
}