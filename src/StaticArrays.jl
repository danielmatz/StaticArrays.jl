__precompile__()

module StaticArrays

import Base: @pure, @propagate_inbounds, getindex, setindex!, size, similar,
             length, convert, promote_op, map, map!, reduce, mapreduce,
             broadcast, broadcast!, conj, transpose, ctranspose, hcat, vcat,
             ones, zeros, eye, cross, vecdot, reshape, fill, fill!, det, inv,
             eig, trace, vecnorm, dot

export StaticArray, StaticVector, StaticMatrix
export SArray, SVector, SMatrix
export MArray, MVector, MMatrix
export FieldVector, MutableFieldVector

export @SVector, @SMatrix, @SArray
export @MVector, @MMatrix, @MArray

export similar_type

include("util.jl")

include("core.jl")
include("SVector.jl")
include("FieldVector.jl")
include("SMatrix.jl")
include("SArray.jl")
include("MVector.jl")
include("MMatrix.jl")
include("MArray.jl")


include("indexing.jl")
include("abstractarray.jl")
include("mapreduce.jl")
include("arraymath.jl")
include("linalg.jl")
include("matrix_multiply.jl")
include("deque.jl")
include("det.jl")
include("inv.jl")
include("eigen.jl")
include("cholesky.jl")

include("FixedSizeArrays.jl")

# TODO list
# ---------
#
# * tests
#
# * reshape() - accept Val? Currently uses `ReshapedArray`. Cool :)
#
# * permutedims() - accept Val? Or wait for `PermutedDimsArray` ?
#
# * Linear algebra - matrix functions (det, inv, eig, svd, qr, etc...)
#                    (currently, we use pointers to interact with LAPACK, etc)


end # module
