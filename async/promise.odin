package async

import "core:sync"
import "core:time"

import "base:intrinsics"

Worker :: distinct int

Promise :: struct($RT: typeid) {
    result: RT,
    worker: Worker,
    _await_sync: sync.Cond,
    _no_await_flag: bool,
    _cancel_flag: bool,
    mtx: sync.Mutex
}

Empty_Promise :: Promise(struct {})

promise_join :: proc(p: ^Promise($RT)) -> RT {
    sync.guard(&p.mtx)
    if p._no_await_flag do return p.result
    sync.cond_wait(&p._await_sync, &p.mtx)
    return p.result
}

promise_join_with_timeout :: proc(p: ^Promise($RT), duration: time.Duration) -> Maybe(RT) {
    sync.guard(&p.mtx)
    if p._no_await_flag do return p.result
    if sync.cond_wait_with_timeout(&p._await_sync, &p.mtx, duration) {
        return p.result
    } else {
        return nil // timeout was reached
    }
}

promise_cancel :: proc(p: ^Promise($RT)) {
    intrinsics.atomic_store(&p._cancel_flag, true)
}

await :: promise_join
await_timeout :: promise_join_with_timeout
cancel :: promise_cancel