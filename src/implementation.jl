function wordhunt(
    Words::Array{String,1};
    D=[:E, :S, :W, :N, :SE, :NE],
    Gridsize=7,
    printres=true,
    prefmode=2,
    limit=true,
    optimizer=optimizer_with_attributes(Cbc.Optimizer, MOI.Silent() => true),
)
    Maxlength = maximum(length.(Words))
    M = 1:Gridsize
    N = uppercase.(Words)
    L = unique(join(N, ""))

    model = Model(optimizer)

    @variable(model, x[M, M, L], Bin)  # Letter in location M,M
    @variable(model, y[N, M, M, D])    # Word in location M,M in direction D

    # Allowed start positions for each direction in D
    for n in N, i in M, j in M, d in D
        if (d == :E) && (j > Gridsize - length(n) + 1)
            @constraint(model, y[n, i, j, d] <= 0)
        elseif (d == :S) && (i > Gridsize - length(n) + 1)
            @constraint(model, y[n, i, j, d] <= 0)
        elseif (d == :W) && (j < length(n))
            @constraint(model, y[n, i, j, d] <= 0)
        elseif (d == :N) && (i < length(n))
            @constraint(model, y[n, i, j, d] <= 0)
        elseif (d == :SE) &&
               ((i > Gridsize - length(n) + 1) || (j > Gridsize - length(n) + 1))
            @constraint(model, y[n, i, j, d] <= 0)
        elseif (d == :NE) && ((j > Gridsize - length(n) + 1) || (i < length(n)))
            @constraint(model, y[n, i, j, d] <= 0)
        else
            set_binary(y[n, i, j, d])
        end
    end

    # Each position has maximum one letter
    for i in M, j in M
        @constraint(model, sum(x[i, j, l] for l in L) <= 1)
    end

    # Each word is allowed one position and direction (if inserted)
    for n in N
        @constraint(model, sum(y[n, i, j, d] for i in M, j in M, d in D) <= 1)
    end

    # Placement of words
    for n in N, i in M, j in M, d in D
        ii = i
        jj = j
        for l in 1:length(n)
            if ii in M && jj in M
                @constraint(model, x[ii, jj, n[l]] >= y[n, i, j, d])
                if d == :E
                    jj = jj + 1
                elseif d == :S
                    ii = ii + 1
                elseif d == :SE
                    ii = ii + 1
                    jj = jj + 1
                elseif d == :NE
                    ii = ii - 1
                    jj = jj + 1
                elseif d == :W
                    jj = jj - 1
                elseif d == :N
                    ii = ii - 1
                end
            end
        end
    end

    # Symmetry breaking constraints:

    # Distance from a corner
    if prefmode == 2
        euc = ones(Gridsize, Gridsize)
        for i in M, j in M
            euc[i, j] = sqrt(i^2 + j^2) / Gridsize
        end
    elseif prefmode == 3
        euc = reshape(shuffle!(collect(1:(Gridsize^2))), (Gridsize, Gridsize)) ./ Gridsize^2
    end

    # Objective function
    if prefmode == 1
        most_words = sum(2 * MaxLength * y[n, i, j, d] for n in N, i in M, j in M, d in D)
    elseif prefmode == 2 || prefmode == 3
        most_words = sum(
            Gridsize * length(n) * y[n, i, j, d] for n in N, i in M, j in M, d in D
        )
    else
        most_words = 0
    end
    least_letters = sum(x[i, j, b] for i in M, j in M, b in L)

    P = [:W, :N, :SE]
    if prefmode == 1 && !isempty(intersect(P, D))
        pref = sum(y[n, i, j, d] for n in N, i in M, j in M, d in intersect(P, D))
    elseif prefmode == 2 && !isempty(intersect(P, D))
        pref = sum(
            euc[i, j] * y[n, i, j, d] for n in N, i in M, j in M, d in intersect(P, D)
        )
    else
        pref = 0
    end

    if limit # Use all directions at least once
        for d in D[1:min(length(D), length(N))]
            @constraint(model, sum(y[n, i, j, d] for n in N, i in M, j in M) >= 1)
        end
    end

    @objective(model, Max, most_words - least_letters + 0.1 * pref)

    optimize!(model)

    if printres
        # Show status and objective value
        print(JuMP.termination_status(model), "\t")
        println(JuMP.objective_value(model))
        println()

        # Print solution to console
        printSol(x)
    end

    return JuMP.termination_status(model), model
end

function printSol(xsol; fillrand=true, highlight=true, highlightcolor=:blue)
    x = JuMP.value.(xsol)
    N = size(xsol, 1)
    Random.seed!(42)
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    h = fill(false, (N, N))       # Highlight solution
    if fillrand
        s = [letters[rand(1:end)] for i in 1:N, j in 1:N]
    else
        s = fill(' ', (N, N))
    end
    for i in 1:N, j in 1:N, l in axes(x)[3]
        if x[i, j, l] > 0.5
            s[i, j] = l
            h[i, j] = true
        end
    end
    h1 = Highlighter(
        (data, i, j) -> h[i, j], Crayon(; bold=true, foreground=highlightcolor)
    )
    pretty_table(s; highlighters=tuple(h1), noheader=true, tf=borderless)
    return s
end
