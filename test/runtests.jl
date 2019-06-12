using Marconi, Test

include("test_networkanalysis.jl")

# Build the docs on Julia v1.0
if get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.0"
    cd(joinpath(@__DIR__, "..")) do
        withenv("JULIA_LOAD_PATH" => nothing) do
            cmd = `$(Base.julia_cmd()) --depwarn=no --color=yes --project=docs/`
            coverage = Base.JLOptions().code_coverage == 0 ? "none" : "user"
            run(`$(cmd) -e 'using Pkg; Pkg.instantiate()'`)
            run(`$(cmd) --code-coverage=$(coverage) docs/make.jl`)
        end
    end
end
