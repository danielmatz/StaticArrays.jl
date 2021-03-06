
@generated function eig{T<:Real, SM <: StaticMatrix}(A::Base.LinAlg.RealHermSymComplexHerm{T,SM}; permute::Bool=true, scale::Bool=true)
    if size(SM) == (1,1)
        return quote
            $(Expr(:meta, :inline))
            @inbounds return (SVector{1,T}((A[1],)), eye(SMatrix{1,1,T}))
        end
    elseif size(SM) == (2,2)
        return quote
            $(Expr(:meta, :inline))
            a = A.data

            if A.uplo == 'U'
                @inbounds t_half = real(a[1] + a[4])/2
                @inbounds d = real(a[1]*a[4] - a[3]'*a[3]) # Should be real

                tmp2 = t_half*t_half - d
                tmp2 < 0 ? tmp = zero(tmp2) : tmp = sqrt(tmp2) # Numerically stable for identity matrices, etc.
                vals = SVector(t_half - tmp, t_half + tmp)

                @inbounds if a[3] == 0
                    vecs = eye(SMatrix{2,2,T})
                else
                    @inbounds v11 = vals[1]-a[4]
                    @inbounds n1 = sqrt(v11'*v11 + a[3]'*a[3])
                    v11 = v11 / n1
                    @inbounds v12 = a[3]' / n1

                    @inbounds v21 = vals[2]-a[4]
                    @inbounds n2 = sqrt(v21'*v21 + a[3]'*a[3])
                    v21 = v21 / n2
                    @inbounds v22 = a[3]' / n2

                    vecs = @SMatrix [ v11  v21 ;
                                      v12  v22 ]
                end
                return (vals,vecs)
            else
                @inbounds t_half = real(a[1] + a[4])/2
                @inbounds d = real(a[1]*a[4] - a[2]'*a[2]) # Should be real

                tmp2 = t_half*t_half - d
                tmp2 < 0 ? tmp = zero(tmp2) : tmp = sqrt(tmp2) # Numerically stable for identity matrices, etc.
                vals = SVector(t_half - tmp, t_half + tmp)

                @inbounds if a[2] == 0
                    vecs = eye(SMatrix{2,2,T})
                else
                    @inbounds v11 = vals[1]-a[4]
                    @inbounds n1 = sqrt(v11'*v11 + a[2]'*a[2])
                    v11 = v11 / n1
                    @inbounds v12 = a[2] / n1

                    @inbounds v21 = vals[2]-a[4]
                    @inbounds n2 = sqrt(v21'*v21 + a[2]'*a[2])
                    v21 = v21 / n2
                    @inbounds v22 = a[2] / n2

                    vecs = @SMatrix [ v11  v21 ;
                                      v12  v22 ]
                end
                return (vals,vecs)
            end
        end
    elseif size(SM) == (3,3)
        if !(T <: Real) # TODO adapt the below to be complex-safe
            return quote
                $(Expr(:meta, :inline))
                eigen = eigfact(A)
                return (eigen.values, eigen.vectors)
            end
        else
            S = typeof((one(T)*zero(T) + zero(T))/one(T))

            return quote
                $(Expr(:meta, :inline))

                uplo = A.uplo
                data = A.data
                if uplo == 'U'
                    @inbounds A = SMatrix{3,3}(data[1], data[4], data[7], data[4], data[5], data[8], data[7], data[8], data[9])
                else
                    @inbounds A = SMatrix{3,3}(data[1], data[2], data[3], data[2], data[5], data[6], data[3], data[6], data[9])
                end

                # Adapted from Wikipedia
                @inbounds p1 = A[4]*A[4] + A[7]*A[7] + A[8]*A[8]
                if (p1 == 0)
                    # A is diagonal.
                    @inbounds eig1 = A[1]
                    @inbounds eig2 = A[5]
                    @inbounds eig3 = A[9]

                    return (SVector{3,$S}(eig1, eig2, eig3), eye(SMatrix{3,3,$S}))
                else
                    q = trace(A)/3
                    @inbounds p2 = (A[1] - q)^2 + (A[5] - q)^2 + (A[9] - q)^2 + 2 * p1
                    p = sqrt(p2 / 6)
                    B = (1 / p) * (A - UniformScaling(q)) # q*I
                    r = det(B) / 2

                    # In exact arithmetic for a symmetric matrix  -1 <= r <= 1
                    # but computation error can leave it slightly outside this range.
                    if (r <= -1)
                        phi = pi / 3
                    elseif (r >= 1)
                        phi = 0
                    else
                        phi = acos(r) / 3
                    end

                    # the eigenvalues satisfy eig1 <= eig2 <= eig3
                    eig3 = q + 2 * p * cos(phi)
                    eig1 = q + 2 * p * cos(phi + (2*pi/3))
                    eig2 = 3 * q - eig1 - eig3     # since trace(A) = eig1 + eig2 + eig3

                    # Now get the eigenvectors
                    # TODO branch for when eig1 == eig2?
                    @inbounds tmp1 = SVector(A[1] - eig1, A[2], A[3])
                    @inbounds tmp2 = SVector(A[4], A[5] - eig1, A[6])
                    v1 = cross(tmp1, tmp2)
                    v1 = v1 / vecnorm(v1)

                    @inbounds tmp1 = SVector(A[1] - eig2, A[2], A[3])
                    @inbounds tmp2 = SVector(A[4], A[5] - eig2, A[6])
                    v2 = cross(tmp1, tmp2)
                    v2 = v2 / vecnorm(v2)

                    v3 = cross(v1, v2) # should be normalized already

                    @inbounds return (SVector((eig1, eig2, eig3)), SMatrix{3,3}((v1[1], v1[2], v1[3], v2[1], v2[2], v2[3], v3[1], v3[2], v3[3])))
                end
            end
        end
    else
        return quote
            $(Expr(:meta, :inline))
            eigen = eigfact(A)
            return (eigen.values, eigen.vectors)
        end
    end
end

# TODO: the non-symmetric case: type stable version (real -> real) since it is more useful to us!

#=
@generated function eig{T<:Real, SM <: StaticMatrix}(A::Base.LinAlg.RealHermSymComplexHerm{T,SM}; permute::Bool=true, scale::Bool=true)
    if size(SM) == (1,1)
        return quote
            $(Expr(:meta, :inline))
            @inbounds return (SVector{1,T}((A[1],)), eye(SMatrix{1,1,T}))
        end
    elseif size(SM) == (2,2)
        return quote
            $(Expr(:meta, :inline))
            a = A.data

            if m2.uplo == 'U'
                @inbounds t_half = real(A[1] + A[4])/2
                @inbounds d = real(A[1]*A[4] - A[3]'*A[3]) # Should be real

                tmp2 = t_half*t_half - d
                tmp2 < 0 ? tmp = zero(tmp2) : tmp = sqrt(tmp2) # Numerically stable for identity matrices, etc.
                vals = SVector(t_half - tmp, t_half + tmp)

                @inbounds if A[3] == 0
                    @inbounds if A[3] == 0
                        vecs = eye(SMatrix{2,2,T})
                    else
                        @inbounds vecs = @SMatrix [ A[3]          A[3]         ;
                                                    vals[1]-A[1]  vals[2]-A[1] ]
                    end
                else
                    @inbounds v11 = vals[1]-A[4]
                    @inbounds n1 = sqrt(v11'*v11 + A[2]'*A[2])
                    v11 = v11 / n1
                    @inbounds v12 = A[2] / n1

                    @inbounds v21 = vals[2]-A[4]
                    @inbounds n2 = sqrt(v21'*v21 + A[2]'*A[2])
                    v21 = v21 / n2
                    @inbounds v22 = A[2] / n2

                    vecs = @SMatrix [ v11  v21 ;
                                      v12  v22 ]
                end
                return (vals,vecs)
            else

            end
        end
    elseif size(SM) == (3,3)
        error("not implemented")
    else
        return quote
            $(Expr(:meta, :inline))
            eigen = eigfact(A)
            return (eigen.values, eigen.vectors)
        end
    end
end
=#
