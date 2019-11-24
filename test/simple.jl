
const Words = ["Ada","Claire","Hugo","Idris","Julia","Karel","Mary","Max","Maya","Miranda"]

# Tests:
@testset "Simple hunts" begin
    # Able to solve problem    
    st,m = wordhunt(Words,[:E],4,false)
    @test st == MOI.OPTIMAL
    st,m = wordhunt(["Anne","Anna","Arne"],[:E,:S,:SE],4,false);
    x = JuMP.value.(m[:x])
    # Unique solution:
    @test x[1,1,'A'] ≈ 1
    @test (x[4,1,'A'] + x[1,4,'A']) ≈ 1
    @test x[4,4,'E'] ≈ 1
end