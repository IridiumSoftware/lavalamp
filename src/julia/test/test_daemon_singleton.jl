# Hermetic unit test for the LL-040 daemon singleton guard
# (cold-start IPC bug fix, 2026-05-29 — see
# docs/ll040_ipc_coldstart_bug_companion.md).
#
# Exercises acquire / exclude / release of the flock(2)-based lock
# against a TEMP lock file. It never touches ~/.lavalamp and never
# starts the daemon: the daemon's main() is guarded by
# `abspath(PROGRAM_FILE) == @__FILE__`, so including the file here
# defines its functions without running it.
#
# Run standalone:
#   julia --project=src/julia src/julia/test/test_daemon_singleton.jl
# or via the suite (included from runtests.jl).

using Test

# Include the daemon into an isolated module so its many top-level
# consts (VERIFY_SOCKET, IPC_*, LIBCRYPTO, …) don't collide with the
# rest of the suite. main() does NOT run (PROGRAM_FILE guard).
module DaemonUnderTest
    include(joinpath(@__DIR__, "..", "daemon", "lavalamp_daemon.jl"))
end

@testset "LL-040 daemon singleton guard (cold-start IPC bug fix)" begin
    tmp = mktempdir()
    lockpath = joinpath(tmp, "daemon.lock")

    # Clean slate (the include leaves LOCK_HANDLE at its initial nothing).
    DaemonUnderTest.LOCK_HANDLE[] = nothing

    # First acquire succeeds, creates the lock file, and stashes the
    # open handle so the flock is held for the lifetime of the process.
    @test DaemonUnderTest.acquire_singleton_lock(lockpath) == true
    @test DaemonUnderTest.LOCK_HANDLE[] !== nothing
    @test isfile(lockpath)

    # A second acquire while the first is still held is excluded — this
    # is the property that stops an overlapping instance from stomping
    # the incumbent's verify.sock / verify.pub. flock excludes across
    # distinct open file descriptions even within one process.
    @test DaemonUnderTest.acquire_singleton_lock(lockpath) == false
    # The incumbent handle is untouched by the failed attempt.
    @test DaemonUnderTest.LOCK_HANDLE[] !== nothing

    # Releasing clears the handle (and releases the flock).
    DaemonUnderTest.release_singleton_lock()
    @test DaemonUnderTest.LOCK_HANDLE[] === nothing

    # release is idempotent.
    DaemonUnderTest.release_singleton_lock()
    @test DaemonUnderTest.LOCK_HANDLE[] === nothing

    # After release the lock can be re-acquired (a clean restart).
    @test DaemonUnderTest.acquire_singleton_lock(lockpath) == true

    # The lock file is intentionally LEFT on disk across release
    # (avoids the unlink-vs-relock race); re-acquire reuses it.
    @test isfile(lockpath)

    # Cleanup (test-local only).
    DaemonUnderTest.release_singleton_lock()
    rm(tmp; recursive=true, force=true)
end
