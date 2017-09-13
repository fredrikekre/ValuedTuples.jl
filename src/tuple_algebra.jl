"""
    @closure1 e::Expr

Applies closure to the first argument of a function. This is useful for do-block
syntax.
"""
macro closure1(e::Expr)
    if e.head != :call
        error("Must be a function call")
    end
    e.args[2] = :($FastClosures.@closure $(e.args[2]))
    esc(e)
end


export @value
"""
```jdoctest
julia> @value a
Val{:a}()
```
"""
macro value(e)
    Val{e}()
end

export @values
"""
```jdoctest
julia> @values a b
(Val{:a}(), Val{:b}())
```
"""
macro values(es...)
    map(es) do e
        Val{e}()
    end
end

mapfoldr(mapper, reducer, args::Tuple{}) = _empty_reduce_error()
mapfoldr(mapper, reducer, args::Tuple) =
    mapfoldr(mapper, reducer, mapper(first(args)), tail(args))
mapfoldr(mapper, reducer, default, args::Tuple{}) = default
mapfoldr(mapper, reducer, default, args::Tuple) =
    reducer(default, mapfoldr(mapper, reducer, mapper(first(args)), tail(args)))

mapreduce(mapper, reducer, args::Tuple) = mapfoldr(mapper, reducer, args)
mapreduce(mapper, reducer, default, args::Tuple) =
    mapfoldr(mapper, reducer, default, args)

(&)(v1::Val{true}, v2::Val{true}) = Val{true}()
(&)(v1::Val, v2::Val) = Val{false}()

(|)(v1::Val{false}, v2::Val{false}) = Val{false}()
(|)(v1::Val, v2::Val) = Val{true}()

!(::Val{false}) = Val{true}()
!(::Val{true}) = Val{false}()

ifelse(switch::Val{false}, new, old) = old
ifelse(switch::Val{true}, new, old) = new

tuple_mismatch_error(t...) = error("Mismatched tuples: leftovers $(t...)")

getindex(into::Tuple{}, index::Tuple{}) = ()
getindex(into::Tuple, index::Tuple{}) = ()
getindex(into::Tuple{}, index::Tuple) = ()
getindex(into::Tuple, index::Tuple) = begin
    next = getindex(tail(into), tail(index))
    ifelse(first(index), (first(into), next...), next)
end

setindex(old::Tuple{}, new, switch::Tuple{}) = ()
setindex(old::Tuple{}, new, switch::Tuple) = ()
setindex(old::Tuple, new, switch::Tuple{}) = old
setindex(old::Tuple, new, switch::Tuple) =
    ifelse(first(switch), new, first(old)),
    setindex(tail(old), new, tail(switch))...

setindex(old::Tuple{}, new::Tuple{}, switch::Tuple{}) = ()
setindex(old::Tuple{}, new::Tuple{}, switch::Tuple) = ()
setindex(old::Tuple{}, new::Tuple, switch::Tuple{}) = ()
setindex(old::Tuple{}, new::Tuple, switch::Tuple) = ()
setindex(old::Tuple, new::Tuple{}, switch::Tuple{}) = old
setindex(old::Tuple, new::Tuple{}, switch::Tuple) = old
setindex(old::Tuple, new::Tuple, switch::Tuple{}) = old
function setindex(old::Tuple, new::Tuple, switch::Tuple)
    first_switch = first(switch)
    ifelse(first_switch, first(new), first(old)),
    setindex(
        tail(old),
        ifelse(first_switch, tail(new), new),
        tail(switch))...
end

devalue(::Val{T}) where T = T
with(f, v::Val) = Val(f(devalue(v)))
value_wrap(f) = (x, args...) -> Val(f(devalue(x), args...))

fieldtypes(any) = fieldtypes(Val(any))
function fieldtypes(val_type::Val)
    Base.@pure inner_function(i) = value_wrap(fieldtype)(val_type, i)
    ntuple(inner_function, value_wrap(nfields)(val_type))
end

fieldtypes(any) = fieldtypes(Val(any))
function fieldtypes(val_type::Val)
    Base.@pure inner_function(i) = with(val_type) do atype
        fieldtype(atype, i)
    end
    ntuple(inner_function, with(nfields, val_type))
end

function fieldtypes(val_type::Val)
    Base.@pure inner_function(i) = with(val_type) do atype
        fieldtype(atype, i)
    end
    ntuple(inner_function, with(nfields, val_type))
end
