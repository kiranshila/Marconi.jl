using PGFPlotsX

export plotSmith
export plotSmith!
export plotSmithCircle!

"""
    plotSmith(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmith(network::Network,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  pltopts::PGFPlotsX.Options = @pgf({}))
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  # Create the PGFslotsX axis
  p = @pgf SmithChart({axopts...},Plot({pltopts...},Coordinates(data)))
  # Draw on smith chart
  return p
end

"""
    plotSmith!(sc, network,(1,1))

Plots the S(1,1) parameter from `network` on an existing Smith Chart `sc`

Returns the `sc` object
"""
function plotSmith!(smith::SmithChart,network::Network,parameter::Tuple{Int,Int};
                    pltopts::PGFPlotsX.Options = @pgf({}))
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  push!(smith,@pgf Plot({pltopts...},Coordinates(data)))
  return smith
end

"""
    plotSmithCircle!(sc, xc, yc, rad)

Plots a cricle with center coordinates `(xc,yc)` on the ``\\Gamma`` plane with radius rad
on an existing Smith Chart object.

Returns the `sc` object
"""
function plotSmithCircle!(smith::SmithChart,xc::A,yc::B,rad::C;
                          opts::PGFPlotsX.Options = @pgf({})) where {A <: Real, B <: Real, C <: Real}
  # Create an array to represent the circle
  x = [rad*cosd(v) for v = -180:180]
  y = [rad*sind(v) for v = -180:180]

  circle = @pgf Plot({"is smithchart cs", opts...},Coordinates(x.+xc,y.+yc))
  push!(smith,circle)
  return smith
end
