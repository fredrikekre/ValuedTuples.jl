module ValuedTuples

import MacroTools
import FastClosures
import FastClosures.@closure
import Base.tail
import Base.mapfoldr
import Base._empty_reduce_error
import Base.mapreduce
import Base.eltype
import Base.&
import Base.|
import Base.!
import Base.ifelse
import Base.getindex
import Base.setindex
import Base.merge

include("tuple_algebra.jl")

export ValuedTuple
"""
    struct ValuedTuple{T, N}
        tuple::T
        names::N
    end

A valued tuple can be indexed only with `Val`s (create
with [`@value`](@ref) or [`@values`](@ref)). Valued tuples can be manipulated in
a type-stable way because the names are directly encoded into the type. You can
use repeated values. `getindex` will take the last match when trying to index at
a repeated value; for all matches, use [`match_index`](@ref) instead. A vector of
tuples with consistent names will conveniently print as a markdown table.

```jldoctest
julia> using ValuedTuples

julia> v = ValuedTuple((1, 2.0, "3"), @values a b a)
ValuedTuples.ValuedTuple(a = 1, b = 2.0, a = 3)

julia> v[@value a]
3

julia> v[@value c]
ERROR: Value Val{:c}() not found
[...]

julia> ValuedTuple((1, 2, 3), @values a)
ERROR: Tuple size mismatch: leftovers (2, 3)
[...]

julia> ValuedTuple((1,), @values a b c)
ERROR: Tuple size mismatch: leftovers (Val{:b}(), Val{:c}())
[...]

julia> ValuedTuple((1, 2), (3, 4))
ERROR: All names must be Vals
[...]
```
"""
struct ValuedTuple{T, N}
    tuple::T
    names::N
end

Base.show(io::IO, v::ValuedTuple) =
    print(io, "$ValuedTuple(" * join(map(v.names, v.tuple) do value, item
        "$(devalue(value)) = $item"
    end, ", ") * ")")

which_index(v, value) = @closure1 map(v.names) do name
    Val(name == value)
end

export match_index
"""
    match_index(v::ValuedTuple, value)

```jldoctest
julia> using ValuedTuples

julia> v = ValuedTuple((1, 2, 3), @values a b c)
ValuedTuples.ValuedTuple(a = 1, b = 2, c = 3)

julia> match_index(v, @value a)
(1, 3)
```
"""
match_index(v, value) = v.tuple[which_index(v, value)]

last_error(x, value) = last(x)
last_error(x::Tuple{}, value) = error("Value $value not found")

Base.getindex(v::ValuedTuple, value) =
    last_error((match_index(v, value)), value)

Base.getindex(v::ValuedTuple, names::Tuple) =
    @closure1 map(names) do name
        v[name]
    end

with(f, v::ValuedTuple) = ValuedTuple(f(v.tuple), v.names)

setindex(v::ValuedTuple, value, name) =
    @closure1 with(v) do tuple
        setindex(tuple, value, which_index(v, name))
    end

#DotOverloading.get_field(v::ValuedTuple, value) = getindex(v, value)

"""
    Base.merge(v1::ValuedTuple, v2::ValuedTuple)

```jldoctest
julia> using ValuedTuples

julia> merge(ValuedTuple((1, "b"), @values a b), ValuedTuple((3, "d"), @values c d))
ValuedTuples.ValuedTuple(a = 1, b = b, c = 3, d = d)
```
"""
merge(v1::ValuedTuple, v2::ValuedTuple) =
    ValuedTuple((v1.tuple..., v2.tuple...), (v1.names..., v2.names...))

export delete
"""
    delete(v::ValuedTuple, value)

```jldoctest
julia> using ValuedTuples

julia> delete(ValuedTuple(@kws a = 1 b = 2), @value a)
(@VT b = 2)
```
"""
delete(v::ValuedTuple, value) = begin
    keeps = .!(which_index(v, value))
    ValuedTuple(v.tuple[keeps], v.names[keeps])
end


value_names(t) = map(fieldtypes(fieldtype(t, :names))) do valtype
    devalue(valtype)()
end
tuple_types(t) = fieldtypes(fieldtype(t, :tuple))

export value_names
"""
    valued_tuple_structure(t)

Construct a named tuple of the element types of a named tuple type.

```jldoctest
julia> using ValuedTuples

julia> t = typeof(ValuedTuple((1, "a"), @values a b));

julia> valued_tuple_structure(typeof(v))
ValuedTuple(a = Val{Int64}(), b = Val{String}())
```
"""
valued_tuple_structure(t) = ValuedTuple(tuple_types(t), value_names(t))

const LeafValuedTuple = ValuedTuple{E, V} where V <: Tuple where E <: Tuple

Base.showarray(io::IO, v::AbstractVector{T}, repr::Bool) where T <: LeafValuedTuple = begin
    fnames = value_names(T)
    if !repr && get(io, :limit, false) && length(v) > 10
        v = v[1:10]
        println(io, "First 10 rows")
    end
    show(io,
        Markdown.MD([Markdown.Table(
            unshift!(
                map(v) do named_tuple
                    [string.(named_tuple.tuple)...]
                end,
                [string.(devalue.(fnames))...]),
            repeat([:l], outer = length(fnames)))]))
end

Base.haskey(v::ValuedTuple, key) = devalue(mapreduce(x -> Val(x == key), |, v.names))

struct AppliedVector{T, F, V} <: AbstractVector{T}
    afunction::F
    vector::V
end

Base.IndexStyle(a::AppliedVector) = IndexLinear()
Base.size(a::AppliedVector) = size(a.vector)
Base.getindex(a::AppliedVector, i::Int) = a.afunction(a.vector[i])

AppliedVector{T}(f::F, v::V) where {T, F, V} = AppliedVector{T, F, V}(f, v)

struct GroupedVector{T} <: AbstractVector{T}
    vector::T
    windows::Vector{UnitRange{Int64}}
end

Base.IndexStyle(g::GroupedVector) = IndexLinear()
Base.size(g::GroupedVector) = size(g.windows)
Base.getindex(g::GroupedVector, i::Int) = g.vector[g.windows[i]]
Base.setindex!(g::GroupedVector, values, i::Int) =
    g.vector[g.windows[i]] .= values

export ZipVector
struct ZipVector{T, TupleType} <: AbstractVector{T}
    tuple::TupleType
end

ZipVector(tuple::T) where T =
    ZipVector{Tuple{eltype.(tuple)...}, T}(tuple)

getindex_over(vectors, index) =
    @closure1 map(vectors) do vector
        vector[index]
    end

setindex_over!(vectors, values, index) =
    @closure1 map(vectors, values) do vector, value
        vector[index] = value
    end

Base.IndexStyle(e::ZipVector) = IndexLinear()
Base.size(e::ZipVector) = size(first(e.tuple))
Base.getindex(e::ZipVector, i::Int) =
    getindex_over(e.tuple, i)
Base.setindex!(e::ZipVector, values, i::Int) =
    setindex_over!(e.tuple, values, i)

struct GroupedZipVector{T} <: AbstractVector{T}
    tuple::T
    windows::Vector{UnitRange{Int64}}
end

GroupedZipVector(tuple::T, windows) where T =
    GroupedZipVector{T}(tuple, windows)

Base.IndexStyle(g::GroupedZipVector) = IndexLinear()
Base.size(g::GroupedZipVector) = length(g.windows)
Base.getindex(g::GroupedZipVector, i::Int) =
    getindex_over(g.tuple, g.windows[i])
Base.setindex!(g::GroupedZipVector, values, i::Int) =
    setindex_over!(g.tuple, values, g.windows[i])

export rowwise
rowwise(v::ValuedTuple{T, N}) where {T, N} = begin
    zipped = ZipVector(v.tuple)
    @closure1 AppliedVector{ValuedTuple{eltype(zipped), N}}(zipped) do row
        ValuedTuple(row, names)
    end
end

export columnwise
columnwise(v::Vector{T}) where T <: LeafValuedTuple = begin
    structure = valued_tuple_structure(eltype(v))
    names = structure.names
    f = let v = v
        (val_type, name) -> begin
            @closure1 AppliedVector{devalue(val_type)}(v) do row
                row[name]
            end
        end
    end
    atuple = map(f, structure.tuple, names)
    ValuedTuple(atuple, names)
end

export unnest
unnest(v::ValuedTuple, column) = begin
    deleted = delete(v, column)
    tuple_of_vectors = deleted.tuple
    nested = v[column]
    outer_length = length(nested)
    lengths = length.(nested)
    inner_length = sum(lengths)
    results = @closure1 map(tuple_of_vectors) do vector
        @boundscheck @assert length(vector) == outer_length
        similar(vector, inner_length)
    end
    nested_result = Vector{eltype(eltype(nested))}(inner_length)
    position = 0
    for i in 1:outer_length
        start_position = position + 1
        @inbounds position = position + lengths[i]
        range = start_position:position
        @inbounds nested_result[range] .= nested[i]
        @closure1 map(tuple_of_vectors, results) do vector, result
            vector[range] = result[i]
        end
    end
    together = ValuedTuple((nested_result, results...), (column, deleted.names...))
    manyindex(together, v.names)
end

unnest(v::Vector, column) = begin
    outer_length = length(v)
    lengths = map(v) do v
        length(v[column])
    end
    inner_length = sum(lengths)
    # ugly code to statically generate a return type
    structure = valued_tuple_structure(eltype(v))
    edited = setindex(structure, with(eltype, structure[column]), column)
    result = Vector{ValuedTuple{Tuple{devalue.(edited.tuple)...}, typeof(edited.names)}}(inner_length)
    position = 0
    for i in 1:outer_length
        @inbounds template = v[i]
        for item in template[column]
            position = position + 1
            @inbounds result[position] = setindex(template, item, column)
        end
    end
    result
end

export order
order(v::Vector{T}, column) where T <: ValuedTuple =
    v[sortperm([item[column] for item in v])]

make_windows(vector) = begin
    alength = length(vector)
    windows = Vector{UnitRange{Int}}()
    start_position = 1
    stop_position = 1
    current_item = first(vector)
    for current_position in 2:alength
        @inbounds next_item = vector[current_position]
        if next_item != current_item
            stop_position = current_position - 1
            push!(windows, start_position:stop_position)
            start_position = current_position
        end
        current_item = next_item
    end
    push!(windows, start_position:alength)
    windows
end

export group
group(vector, grouping) = GroupedVector(vector, make_windows(grouping))

end
