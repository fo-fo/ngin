local alloc = {}

local kAllocReserveSize = SYM.ngin_kAllocReserveSize[ 1 ]
-- Bookkeeping of active variable allocations, one bool for each byte
local state = {}

function alloc.alloc( symbol, offset, size )
    assert( offset >= 0 and size >= 0 and offset+size <= kAllocReserveSize )

    -- \todo Would be nice if we could print where the previous overlapping
    --       allocation was made.
    for i = offset, offset+size-1 do
        assert( not state[ i ], string.format( "[ngin] allocation " ..
            "overlap at offset %d for symbol '%s'", i, symbol ) )
        state[ i ] = true
    end
end

function alloc.free( symbol, offset, size )
    assert( offset >= 0 and size >= 0 and offset+size <= kAllocReserveSize )

    for i = offset, offset+size-1 do
        assert( state[ i ], string.format( "[ngin] freeing unallocated " ..
            "data at offset %d", i ) )
        state[ i ] = false
    end
end

ngin.alloc = alloc
