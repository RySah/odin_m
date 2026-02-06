package async

import "core:sync"
import "core:container/queue"
import "core:thread"
import "core:mem"
import "core:slice"
import "core:reflect"
import "core:log"

import "base:intrinsics"

Info :: struct($RT: typeid) {
    params: []any,
    promise: ^Promise(RT),
    procedure: rawptr
}

Info_For_Shared :: struct($RT: typeid) {
    params: []any,
    promise: ^Promise(RT),
    procedure: rawptr,
    ct: Cancellation_Token
}

run_proc_with_params_and_return :: proc(
    d: ^Dispatcher,
    p: #type proc(params: ..any) -> $RT,
    params: ..any,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(params: ..any) -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(RT), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: thread.Task) {
                info := transmute(^Info(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    promise.result = procedure(..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_params :: proc(
    d: ^Dispatcher,
    p: #type proc(params: ..any),
    params: ..any,
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(params: ..any)

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(struct{}), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    procedure(..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_return :: proc(
    d: ^Dispatcher,
    p: #type proc() -> $RT,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc() -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(RT), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    promise.result = procedure()
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }

        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc :: proc(
    d: ^Dispatcher,
    p: #type proc(),
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc()

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(struct{}), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    procedure()
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        
        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }
    return promise, nil
}

run_proc_with_params_and_return_and_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token, params: ..any) -> $RT,
    params: ..any,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token, params: ..any) -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(RT), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: thread.Task) {
                info := transmute(^Info(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    promise.result = procedure(transmute(Cancellation_Token)(&promise._cancel_flag), ..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_params_and_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token, params: ..any),
    params: ..any,
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token, params: ..any)

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(struct{}), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    procedure(transmute(Cancellation_Token)(&promise._cancel_flag),..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_return_and_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token) -> $RT,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc() -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(RT), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    promise.result = procedure(transmute(Cancellation_Token)(&promise._cancel_flag))
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }

        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token),
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token)

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info(struct{}), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure

                if sync.guard(&promise.mtx) {
                    procedure(transmute(Cancellation_Token)(&promise._cancel_flag))
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        
        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }
    return promise, nil
}

run_proc_with_params_and_return_and_parent_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token, params: ..any) -> $RT,
    ct: Cancellation_Token, params: ..any,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token, params: ..any) -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info_For_Shared(RT), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p
    info.ct = ct

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: thread.Task) {
                info := transmute(^Info_For_Shared(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure
                ct := info.ct

                if sync.guard(&promise.mtx) {
                    promise.result = procedure(ct, ..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_params_and_parent_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token, params: ..any),
    ct: Cancellation_Token, params: ..any,
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token, params: ..any)

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info_For_Shared(struct{}), allocator=allocator) or_return
    info.params = slice.clone(params, allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p
    info.ct = ct

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info_For_Shared(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                params := info.params
                procedure := transmute(_Proc_Sig)info.procedure
                ct := info.ct

                if sync.guard(&promise.mtx) {
                    procedure(ct,..params)
                
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        success := queue.append(&d.task_queue, task) or_return

        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_return_and_parent_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token) -> $RT,
    ct: Cancellation_Token,
    allocator := context.allocator
) -> (promise: ^Promise(RT), err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc() -> RT

    promise = new(Promise(RT), allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info_For_Shared(RT), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p
    info.ct = ct

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info_For_Shared(RT))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure
                ct := info.ct

                if sync.guard(&promise.mtx) {
                    promise.result = procedure(ct)
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }

        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }

    return promise, nil
}

run_proc_with_parent_cancellation_token :: proc(
    d: ^Dispatcher,
    p: #type proc(ct: Cancellation_Token),
    ct: Cancellation_Token,
    allocator := context.allocator
) -> (promise: ^Empty_Promise, err: mem.Allocator_Error) #optional_allocator_error {
    _Proc_Sig :: proc(ct: Cancellation_Token)

    promise = new(Empty_Promise, allocator=allocator) or_return
    promise.worker = transmute(Worker)d.depth

    info := new(Info_For_Shared(struct{}), allocator=allocator) or_return
    info.promise = promise
    info.procedure = transmute(rawptr)p

    if sync.guard(&d.mtx) {
        intrinsics.atomic_add(&d.depth, 1)

        task := Task{
            procedure = proc(task: Task) {
                info := transmute(^Info_For_Shared(struct{}))task.data
                defer {
                    delete(info.params, allocator=task.allocator)
                    free(info, allocator=task.allocator)
                }
                
                promise := info.promise
                procedure := transmute(_Proc_Sig)info.procedure
                ct := info.ct

                if sync.guard(&promise.mtx) {
                    procedure(ct)
                    
                    sync.cond_broadcast(&promise._await_sync)
                    promise._no_await_flag = true
                }
            },
            data = info,
            user_index = transmute(int)info.promise.worker,
            allocator = allocator
        }
        
        success := queue.append(&d.task_queue, task) or_return
        assert(success, "Failed to queue task in dispatcher")
    }
    return promise, nil
}

run :: proc{
    run_proc_with_params_and_return,
    run_proc_with_params,
    run_proc_with_return,
    run_proc,
}

run_with_cancellation_token :: proc{
    run_proc_with_params_and_return_and_cancellation_token,
    run_proc_with_params_and_cancellation_token,
    run_proc_with_return_and_cancellation_token,
    run_proc_with_cancellation_token,
}
run_with_ct :: run_with_cancellation_token

run_with_parent_cancellation_token :: proc{
    run_proc_with_params_and_return_and_parent_cancellation_token,
    run_proc_with_params_and_parent_cancellation_token,
    run_proc_with_return_and_parent_cancellation_token,
    run_proc_with_parent_cancellation_token,
}
run_with_parent_ct :: run_with_parent_cancellation_token

auto_run :: proc{
    run_proc_with_params_and_return,
    run_proc_with_params,
    run_proc_with_return,
    run_proc,
    run_proc_with_params_and_return_and_cancellation_token,
    run_proc_with_params_and_cancellation_token,
    run_proc_with_return_and_cancellation_token,
    run_proc_with_cancellation_token,
    run_proc_with_params_and_return_and_parent_cancellation_token,
    run_proc_with_params_and_parent_cancellation_token,
    run_proc_with_return_and_parent_cancellation_token,
    run_proc_with_parent_cancellation_token,
}