using PGFPlotsX

export plotSmithData
export plotSmithData!
export plotSmithCircle!

"""
    plotSmithData(network,(1,1))

Plots the S(1,1) parameter from `network` on a Smith Chart.

Returns a `PGFPlotsX.SmithChart` object.
"""
function plotSmithData(network::Network,parameter::Tuple{Int,Int};
                  axopts::PGFPlotsX.Options = @pgf({}),
                  opts::PGFPlotsX.Options = @pgf({}))
  # Check that data is in bounds
  if parameter[1] > size(network.s_params[1])[1] || parameter[2] < 1
    throw(DomainError(parameter[1], "Port 1 Out of Bounds"))
  end
  if parameter[2] > size(network.s_params[1])[1] || parameter[2] < 1
    throw(DomainError(parameter[1], "Port 2 Out of Bounds"))
  end
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  # Create the PGFslotsX axis
  p = @pgf SmithChart({axopts...},Plot({opts...},Coordinates(data)))
  # Draw on smith chart
  return p
end

"""
    plotSmithData!(sc, network,(1,1))

Plots the S(1,1) parameter from `network` on an existing Smith Chart `sc`

Returns the `sc` object
"""
function plotSmithData!(smith::SmithChart,network::Network,parameter::Tuple{Int,Int};
                    opts::PGFPlotsX.Options = @pgf({}))
  # Collect the data we want
  data = [s[parameter[1],parameter[2]] for s in network.s_params]
  # Convert to normalized input impedance
  data = [(1+datum)/(1-datum) for datum in data]
  # Split into coordinates
  data = [(real(z),imag(z)) for z in data]
  push!(smith,@pgf Plot({opts...},Coordinates(data)))
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
