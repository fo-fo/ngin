local alloc = {}

local kAllocReserveUserSize = SYM.ngin_kAllocReserveUserSize[ 1 ]
local kAllocReserveInternalSize = SYM.ngin_kAllocReserveInternalSize[ 1 ]
local kAllocReserveTotalSize = kAllocReserveUserSize + kAllocReserveInternalSize
-- Bookkeeping of active variable allocations, one bool for each byte
local state = {}

function alloc.alloc( symbol, offset, size )
    -- \todo Better error message.
    assert( offset >= 0 and size >= 0 and offset+size <= kAllocReserveTotalSize )

    -- \todo Would be nice if we could print where the previous overlapping
    --       allocation was made.
    for i = offset, offset+size-1 do
        assert( not state[ i ], string.format( "[ngin] allocation " ..
            "overlap at offset %d for symbol '%s'", i, symbol ) )
        state[ i ] = true
    end
end

function alloc.free( symbol, offset, size )
    assert( offset >= 0 and size >= 0 and offset+size <= kAllocReserveTotalSize )

    for i = offset, offset+size-1 do
        assert( state[ i ], string.format( "[ngin] freeing unallocated " ..
            "data at offset %d", i ) )
        state[ i ] = false
    end
end

ngin.alloc = alloc
