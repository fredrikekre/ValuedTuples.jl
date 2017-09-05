var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ValuedTuples.ValuedTuple",
    "page": "Home",
    "title": "ValuedTuples.ValuedTuple",
    "category": "Type",
    "text": "julia> using ValuedTuples\n\njulia> ValuedTuple((1, 2, 3), @values a b c)\n(@VT a = 1 b = 2 c = 3)\n\njulia> ValuedTuple((1, 2, 3), @values a)\nERROR: Tuple size mismatch: leftovers (2, 3)\n[...]\n\njulia> ValuedTuple((1,), @values a b c)\nERROR: Tuple size mismatch: leftovers (Val{:b}(), Val{:c}())\n[...]\n\njulia> ValuedTuple((1, 2), (3, 4))\nERROR: All names must be Vals\n[...]\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.delete-Tuple{ValuedTuples.ValuedTuple,Any}",
    "page": "Home",
    "title": "ValuedTuples.delete",
    "category": "Method",
    "text": "delete(v::ValuedTuple, value)\n\njulia> using ValuedTuples\n\njulia> delete((@VT a = 1 b = 2), @value a)\n(@VT b = 2)\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.match_index-Tuple{ValuedTuples.ValuedTuple,Any}",
    "page": "Home",
    "title": "ValuedTuples.match_index",
    "category": "Method",
    "text": "match_index(v::ValuedTuple, value)\n\njulia> using ValuedTuples\n\njulia> v = @VT a = 1 b = 2 a = 3\n(@VT a = 1 b = 2 a = 3)\n\njulia> match_index(v, @value a)\n(1, 3)\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.value_names-Union{Tuple{Type{T}}, Tuple{T}} where T<:ValuedTuples.ValuedTuple",
    "page": "Home",
    "title": "ValuedTuples.value_names",
    "category": "Method",
    "text": "value_names(t::Type{T}) where T <: ValuedTuple\n\nExtract the names of a valued tuple exclusively based on its type.\n\njulia> using ValuedTuples\n\njulia> v = @VT a = 1 b = 2;\n\njulia> value_names(typeof(v))\n(:a, :b)\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.@VT-Tuple",
    "page": "Home",
    "title": "ValuedTuples.@VT",
    "category": "Macro",
    "text": "@VT args...\n\nMake a ValuedTuple. A valued tuple can be indexed only with Vals (create with @value). Valued tuples can be manipulated in a type-stable way because the names are directly encoded into the type. You can use repeated values. getindex will take the last match when trying to index at a repeated value; for all matches, use match_index instead. A vector of tuples with consistent names will conveniently print as a markdown table.\n\njulia> using ValuedTuples\n\njulia> b = 2;\n\njulia> v = @VT a = 1 b a = 3\n(@VT a = 1 b = 2 a = 3)\n\njulia> v[@value b]\n2\n\njulia> v[@value d]\nERROR: BoundsError: attempt to access ()\n[...]\n\njulia> v[@value a]\n3\n\njulia> @VT x * y\nERROR: Unable to decompose assignment x * y\n[...]\n\njulia> [(@VT a = 1 b = 2), (@VT b = 2 c = 3)]\n2-element Array{ValuedTuples.ValuedTuple{Tuple{Int64,Int64},N} where N<:Tuple,1}:\n (@VT a = 1 b = 2)\n (@VT b = 2 c = 3)\n\njulia> t = [(@VT a = 1 b = 2), (@VT a = 3 b = 4)]\n| a   | b   |\n|:--- |:--- |\n| 1   | 2   |\n| 3   | 4   |\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.@value-Tuple{Any}",
    "page": "Home",
    "title": "ValuedTuples.@value",
    "category": "Macro",
    "text": "julia> using ValuedTuples\n\njulia> @value a\nVal{:a}()\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.@values-Tuple",
    "page": "Home",
    "title": "ValuedTuples.@values",
    "category": "Macro",
    "text": "julia> using ValuedTuples\n\njulia> @values a b\n(Val{:a}(), Val{:b}())\n\n\n\n"
},

{
    "location": "index.html#Base.merge-Tuple{ValuedTuples.ValuedTuple,ValuedTuples.ValuedTuple}",
    "page": "Home",
    "title": "Base.merge",
    "category": "Method",
    "text": "Base.merge(v1::ValuedTuple, v2::ValuedTuple)\n\njulia> using ValuedTuples\n\njulia> merge((@VT a = 1 b = \"b\"), (@VT c = 3 d = \"d\"))\n(@VT a = 1 b = \"b\" c = 3 d = \"d\")\n\n\n\n"
},

{
    "location": "index.html#ValuedTuples.jl-1",
    "page": "Home",
    "title": "ValuedTuples.jl",
    "category": "section",
    "text": "Modules = [ValuedTuples]"
},

]}
