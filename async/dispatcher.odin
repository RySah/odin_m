package async

import "core:os"
import "core:thread"
import "core:sync"
import "core:container/queue"
import "core:mem"

import "base:intrinsics"

IS_SUPPORTED :: thread.IS_SUPPORTED

Dispatcher :: struct {
    threads: []^thread.Thread,
    depth: int,
    task_queue: queue.Queue(Task),
    is_running: bool,
    mtx: sync.Mutex
}

system_thread_count :: os.processor_core_count

init_dispatcher :: proc(state: ^Dispatcher, thread_count: int, allocator := context.allocator) -> mem.Allocator_Error {
    assert(thread_count > 0)

    state.threads = make([]^thread.Thread, thread_count, allocator) or_return
    state.depth = 0
    queue.init(&state.task_queue, allocator=allocator) or_return
    state.is_running = true
    for &t in state.threads {
        t = thread.create_and_start_with_data(state, proc(data: rawptr) {
            state := transmute(^Dispatcher)data
            
            for intrinsics.atomic_load(&state.is_running) {
                task: Task
                run_task: bool

                sync.lock(&state.mtx)
                task, run_task = queue.pop_front_safe(&state.task_queue)
                sync.unlock(&state.mtx)

                if run_task {
                    task.procedure(task)
                    intrinsics.atomic_sub(&state.depth, 1)
                }
            }

        })
    }

    return nil
}

join_dispatcher :: proc(state: ^Dispatcher) {
    sync.lock(&state.mtx)
    intrinsics.atomic_store(&state.is_running, false) // All threads will exit their main loop
    sync.unlock(&state.mtx)
    thread.join_multiple(..state.threads)
}

destroy_dispatcher :: proc(state: ^Dispatcher, allocator := context.allocator) -> mem.Allocator_Error {
    join_dispatcher(state) 

    sync.guard(&state.mtx)
    for &t in state.threads {
        thread.destroy(t)
    }
    delete(state.threads, allocator=allocator) or_return
    queue.destroy(&state.task_queue)
    return nil
}

init :: init_dispatcher
destroy :: destroy_dispatcher
join :: join_dispatcher