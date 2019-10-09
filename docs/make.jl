using Marconi, PGFPlotsX, Documenter, DocumenterTools
PGFPlotsX.latexengine!(PGFPlotsX.PDFLATEX)

makedocs(
    modules = [Marconi],
    clean = false,
    doctest = true,
    strict = false,
    checkdocs = :none,
    sitename = "Marconi.jl",
    authors = "Kiran Shila",
    linkcheck = !("skiplinks" in ARGS),
    format = Documenter.HTML(
        canonical = "https://kiranshila.github.io/Marconi.jl/stable/",
        assets = ["assets/favicon.ico"]),
    pages = Any[
        "Home" => "index.md",
        "Manual" => [
            "man/RFAnalysis.md",
            "man/FileIO.md",
            "man/Plot.md",
            "man/NetworkAnalysis.md",
            "man/Antennas.md",
            "man/Metamaterials.md"],
        "Library" => Any[
            "Public" =>"lib/Public.md"]])

@info "Adding custom code to HTML"
pwd()
for (root, dirs, files) in walkdir("build/man/")
    for file in filter(x -> endswith(x, "html"),files)
        open(joinpath(root, file),"r+") do f
            # Read all the file after header
            seek(f,38)
            s = read(f,String)
            seekstart(f)
            header = """<!DOCTYPE html><html lang="en"><head>"""
            write(f,header * """<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>""" * s)
        end
    end
end

@info "calling deploydocs"

deploydocs(
    repo = "github.com/kiranshila/Marconi.jl.git",
    target = "build",
)
