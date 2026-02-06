#+private
package async

import "core:testing"

import "core:time"
import "core:log"
import "core:mem"

import "base:intrinsics"


@(test, disabled=!IS_SUPPORTED)
test_dispatcher_basic_execution :: proc(t: ^testing.T) {
    tc := min(system_thread_count(), 2)
    log.infof("Initializing dispatcher with %d threads.", tc)
    
    d: Dispatcher
    init(&d, tc)
    defer destroy(&d)

    log.infof("Running task.")
    ran := false
    p, err := run(&d, proc(params: ..any) {
        ran := &params[0].(bool)

        ran^ = true
        log.infof("Result: %v", ran)
    }, ran)
    defer free(p)
    assert(testing.expect_value(t, err, nil))

    _, within_time := await_timeout(p, time.Second).?

    if !testing.expect_value(t, within_time, true) {
        return
    }

    testing.expect_value(t, ran, true)
}

@(test, disabled=!IS_SUPPORTED)
test_multiple_tasks_execute :: proc(t: ^testing.T) {
    tc := min(system_thread_count(), 4)
    log.infof("Initializing dispatcher with %d threads.", tc)

    d: Dispatcher
    init(&d, tc)
    defer destroy(&d)

    err: mem.Allocator_Error
    promises: []^Empty_Promise

    count := 0

    promises, err = make([]^Empty_Promise, 100)
    defer {
        for &p in promises do free(p)
        delete(promises)
    }
    assert(testing.expect_value(t, err, nil))

    #unroll for i in 0..<100 {
        promises[i], err = run(&d, proc(params: ..any) {
            count := &params[0].(int)
            intrinsics.atomic_add(count, 1)
        }, count)
        assert(testing.expect_value(t, err, nil))
    }

    for &p in promises {
        _, within_time := await_timeout(p, time.Millisecond * 200).?
        if !testing.expect_value(t, within_time, true) do break
    }

    testing.expect_value(t, count, 100)
}

@(test, disabled=!IS_SUPPORTED)
test_promise_returns_value :: proc(t: ^testing.T) {
    tc := min(system_thread_count(), 2)
    log.infof("Initializing dispatcher with %d threads.", tc)

    d: Dispatcher
    init(&d, tc)
    defer destroy(&d)

    p, err := run(&d, proc() -> int {
        return 67
    })
    defer free(p)
    assert(testing.expect_value(t, err, nil))

    v, within_time := await_timeout(p, time.Millisecond * 200).?
    testing.expect_value(t, within_time, true)
    testing.expect_value(t, v, 67)
}

@(test, disabled=!IS_SUPPORTED)
test_promise_join_idempotent :: proc(t: ^testing.T) {
    tc := 1
    log.infof("Initializing dispatcher with %d threads.", tc)

    d: Dispatcher
    init(&d, tc)
    defer destroy(&d)

    p, err := run(&d, proc() -> int {
        return 7
    })
    defer free(p)
    assert(testing.expect_value(t, err, nil))

    v1, v2: int
    within_time: bool

    v1, within_time = await_timeout(p, time.Millisecond * 200).?
    testing.expect_value(t, within_time, true)

    v2, within_time = await_timeout(p, time.Millisecond * 200).?
    testing.expect_value(t, within_time, true)

    testing.expect_value(t, v1, 7)
    testing.expect_value(t, v2, 7)
}

@(test, disabled=!IS_SUPPORTED)
test_join_after_completion :: proc(t: ^testing.T) {
    tc := 1
    log.infof("Initializing dispatcher with %d threads.", tc)

    d: Dispatcher
    init(&d, tc)
    defer destroy(&d)

    p, err := run(&d, proc() -> int {
        return 1
    })
    defer free(p)
    assert(testing.expect_value(t, err, nil))

    // Letting task finish
    time.sleep(10 * time.Millisecond)

    v, within_time := await_timeout(p, time.Millisecond * 200).?
    testing.expect_value(t, within_time, true)
    testing.expect_value(t, v, 1)
}