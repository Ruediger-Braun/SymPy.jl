## add plotting commands for various packages (Winston, PyPlot, Gadfly)
##
## Based on Plots.jl v"0.5.4+".  In particular, this assume Julia v"0.4+"
##
##
## SymPy (http://docs.sympy.org/latest/modules/plotting.html ) has its plotting module that provides
## * plot: Plots 2D line plots.
## * plot_parametric: Plots 2D parametric plots.
## * plot3d_parametric_line: Plots 3D line plots, defined by a parameter.
## * plot3d: Plots 3D plots of functions in two variables.
## * plot3d_parametric_surface: Plots 3D parametric surface plots.
## * plot_implicit: Plots 2D implicit and region plots.
##
## Our goal here is to give this a Julia interface
## that doesn't depend on the backend plotting packages, so we
## use the `Plots` package.
##
##
## plot(::Sym, a, b)          2d-line plot of function
## plot(Vector{Sym}, a, b)    plot of expressions over same axis
## plot(::Sym, ::Sym, a, b)   parametric plot of two expressions over [a,b]
## plot(xs, ys, ex::Sym)      contour plot of expression over regions xs x ys
##
## To this we add a light interface for explicitness:
##
## parametricplot(ex1, ex2, [ex3], a, b) # parametric plot in 2 or 3d
## contourplot(ex, (xvar, a, b), (yvar, c,d))  # also Plots.contour(xs, ys, ex)
## plot_surface(ex, (xvar, a, b), (yvar, c,d)) # also Plots.surface(xs, ys, ex)
## plot_parametric_surface((ex1, ex2, ex3), (uvar, a, b), (cvar, c,d))
##
## we also add
## vectorfieldplot([ex1, ex2], (xvar, a, b), (yvar, a, b)) for a vector field plot
##
## The `plot_implicit` function gives access to `plot_implicit`, but requixres `PyPlot` to be installed.


"""

Plotting of symbolic objects.

The `Plots` package provide a uniform interface to many of `Julia`'s
plotting packages. `SymPy` extends the methods for functions to plot
symbolic objects.

The basic goal is that when `Plots` provides an interface for function
objects, this package extends the interface to symbolic
expressions. The convenience comes at a cost -- the plots are
slow to render. (There is a conversion from SymPy value to numeric values that is slow.)

If no backend plotting package is loaded directly, then the `plot` and
`plot!` methods of `Plots` allow for direct plotting of `SymPy`
objects.

In particular:


* `plot(ex::Sym, a, b; kwargs...)` will plot a function evaluating `ex` over [a,b]

Example. Here we use the default backend for `Plots` to make a plot:

```
@vars x
plot(x^2 - 2x, 0, 4)
```

The backend could be switched out with a call like, `pyplot()` or `backend(:pyplot)`, say.

* `plot(exs::Vector{Sym}, a, b; kwargs...)` will plot the functions evaluating `exs` over [a,b]

Example:

```
@vars x
plot([sin(x), cos(x)], 0, 2pi)
```

* `plot(ex1, ex2, a, b; kwargs...)` will plot the two expressions in a parametric plot over the interval `[a,b]`.   

Example:

```
@vars x
plot(sin(2x), cos(3x), 0, 4pi) ## also 
```

For explicitness, we provide `parametricplot(ex1, ex2, a, b)` as an alternative.

For a few backends (those that support `:path3d`) a third symbolic
expression may be added to have a 3d parametric plot rendered:

```
parametricplot(sin(x), cos(x), x, 0, 4pi) # helix in 3d
```

* `vectorfieldplot([ex1, ex2], (x,x0,x1), (y,y0,y1), ...)` will create a vectorfield plot where for a grid of values `(x,y)`, a vector in the direction `[ex1, ex2]`, evaluated at `(x,y)`, will be plotted.

```
vectorfield([-y,x], (x, -5,5), (y, -5,5))
```


* `plot(xs, ys, expression)` will make a contour plot (for many backends).

```
@vars x y
plot(linspace(0,5), linspace(0,5), x*y)
```

For explicitness, we provide `contourplot(ex::Sym, (xvar, a, b), (yvar, c, d))` as an alternative:

```
contourplot(x^2 - y^2, (x,-5,5), (y,-5,5)) # default is [-5,5] x [-5,5]
```



* To plot the surface  `z=ex(x,y)` over a region we have `plot_surface(ex, (x,-5,5), (y,-5,5); kwargs...)`. For example,

```
@vars x y
plot_surface(25 - (x^2 + y^2), (x,0,5), (y,0,5)) # default region could have been dropped
```

The `Plots.surface` function (for a few backends) can also make sureface plots through the syntax:

`Plots.surface(xs, ys, expression)`

(The `surface` method is not exported, as `plot` is by `SymPy`, hence the qualification of the package. The syntax `plot(xs, ys, expression, linetype=:surf)` should also work.)



* `plot_parametric_surface(exs::Tuple, (uvar,a0,b0), (vvar,a1,b1);
  kwargs)` will make parametrically defined surface plots.

Plot the parametrically defined surface `[exs[1](u,v), exs[2](u,v), exs[3](u,v)]` over `[a0,a1] x
[b0,b1]`. The specification of the variables uses a tuple of the form
`(Sym, Real, Real)` following the style of SymPy in `integrate`, say,
where disambiguation of variable names is needed.

Requires `PyPlot`.

```
@vars theta, phi
r = 1
plot_parametric_surface((r*sin(theta)*sin(phi), r*sin(theta)*cos(phi), r*cos(theta)),
                        (theta, 0, pi), (phi, 0, pi/2))
```

(The SymPy name for this function is `plot3d_parametric_surface`, we have dropped the "`3d`" part.)

"""
sympy_plotting = nothing
export sympy_plotting




##################################################
### Plug into Plots interface. Where there is something defined for Functions we
### define for symbolic expressions
## Additions to Plots so that expressions are treated like functions
function Plots._apply_recipe(d::Plots.KW, v1, v2, f::Sym, args...; kw...)
    (v1, v2, lambdify(f))
end

function Plots._apply_recipe(d::Plots.KW, s::Sym, args...; kw...)
    (lambdify(s), args...)
end
function Plots._apply_recipe(d::Plots.KW, v::AbstractVector{Sym}, args...; kw...)
    (map(lambdify, v), args...)
end

function Plots._apply_recipe(d::Plots.KW, mf1::Sym, mf2::Sym, args...; kw...)
    (lambdify(mf1), lambdify(mf2), args...)
end

function Plots._apply_recipe(d::Plots.KW, mf1::Sym, mf2::Sym, mf3::Sym, args...; kw...)
    (lambdify(mf1), lambdify(mf2), lambdify(mf3), args...)
end

##################################################

## Our alternatives
"""

Create a parametric plot of the expressions over the interval `[a,b]`.

(A more explicit call of the type `plot(ex1, ex2, a, b)`.
"""
function parametricplot(ex1::Sym, ex2::Sym, a::Real, b::Real, args...; kwargs...)
    Plots.plot(ex1, ex2, a,b, args...; kwargs...)
end
function parametricplot(ex1::Sym, ex2::Sym, ex3::Sym, a::Real, b::Real, args...; n=250, kwargs...)
    ts = linspace(a, b,n)
    x = free_symbols([ex1, ex2, ex2])[1]
    xs, ys, zs = [mapsubs(ex,x,ts) for ex in [ex1, ex2, ex3]]
    Plots.path3d(xs, ys, z=zs, args...; kwargs...)
end
export(parametricplot)


"""

Vector plot. At each (x,y) on a grid, plot a "vector" of [fx(x,y), fy(x,y)], suitably scaled.

Example:
```
fx(x,y) = -y; fy(x,y) = x
vectorfieldplot(fx, fy)
```

We can plot a direction field of an ODE too.

```
F(y,x) = 1 - y/x   # solution to y'(x) = F(y(x),x) is C/x + x/2
fx(x,y) = 1; fy(x,y) = F(y,x)
vectorfieldplot(fx, fy, xlim=(1,5))
y(x) = 2/x + x/2
plot!(y, 1, 5, linewidth=3)
```

"""
function vectorfieldplot(fx::Function, fy::Function; xlim=(-5,5), ylim=(-5,5),  n::Int=15, kwargs...)

    x₀, x₁ = xlim
    y₀, y₁ = ylim
    Δx = (x₁ - x₀) / (n-1)
    Δy = (y₁ - y₀) / (n-1)

    xs = x₀:Δx:x₁
    ys = y₀:Δy:y₁
    p = plot(xlim=xlim, ylim=ylim, legend=false, kwargs...)

    mx, my = 0.0, 0.0

    ## two loops, first to identify scaling factor so
    ## lines stay within box of width Δx by Δy
    for x in xs, y in ys
        mx = max(mx, abs(fx(x,y)))
        my = max(my, abs(fy(x,y)))
    end

    ## we want all lines to be in the box, so we scale
    λ = .95 *  min(Δx/mx, Δy/my)
    
    for x in xs, y in ys
        plot!([x, x + λ * fx(x,y)], [y, y + λ * fy(x,y)])
    end
    
    p
end

"""

Vector field plot. At each point (x,y) on a grid, plots the vector specified by the expression.

The limits are passed in as tuples of the form `(a,b)` or `(x,a,b)`. The latter specifies the symbol. The former will assign the "`x`" symbol to be the first free symbol and the "`y`" variable the second.

Example
```
@vars x y
vectorfieldplot([-y, x], (x, -5, 5), (y, -5, 5))
```
"""
function vectorfieldplot(exs::Vector{Sym},
            xvar=(-5.0, 5.0),
            yvar=(-5.0, 5.0);
            n::Int=15,
            kwargs...) 
            
    length(exs) == 2 || throw(DimensionMismatch("vector of symbolic objects must have length 2"))
    for ex in exs
                nvars = length(free_symbols(ex))
        nvars <= 2 || throw(DimensionMismatch("Expression has $nvars, expecting 2 for a quiver plot"))
    end
    
    ## get variables, U, V, xlim, ylim
    vars = free_symbols(exs)
    if length(xvar) == 2
        U = vars[1]
        xlim = xvar
    else
        U, xlim = xvar[1], xvar[2:3]
    end
    if length(yvar) == 2
        V, ylim = vars[2], yvar
    else
        V, ylim = yvar[1], yvar[2:3]
    end

    fx(x,y) = convert(Float64, exs[1](U=>x, V=>y))
    fy(x,y) = convert(Float64, exs[2](U=>x, V=>y))

    vectorfieldplot(fx, fy; xlim=xlim, ylim=ylim, n=n, kwargs...)
end
export vectorfieldplot


"""

Create a contour plot of the expression over the indicated region. The
region is specified as a tuple `(a,b)` or `(x,a,b)`. The former has
the associated variable inferred using the ordering of `free_symbols`.

(This is a more explicit form of interface provided by `Plot`:
`plot(xs, ys, ex::Sym)`.)

"""
function contourplot(ex::Sym,
                 xvar=(-5.0, 5.0),
                 yvar=(-5.0, 5.0),
                 args...;
                     n::Int=50,
                     linetype=:contour,
                 kwargs...)
    U,V,xs,ys = _find_us_vs(ex, xvar, yvar, n)
    zs = mapsubs2(ex, U, xs, V,ys)
    plot(xs, ys, zs, args...; linetype=:contour, kwargs...)
end
export(contourplot)

## XXX Rename these?? surface?)
## surface plot. Uses surface()
"""

Make a surface plot defined by the expression of two variables. 


Example
```
plot_surface(x*y, (x,0,3), (y,0,2))
```

This is an *alternative* to the use of surface plots in Plots.
That is, the above is the same as:

```
xs = linspace(0,3, 35)
ys = linspace(0,2,35)
Plots.surface(xs, ys, x*y)
```

Eventually uses `Plots.plot(..., linetype=:surf)`, so surface plots must be defined for the backend in use.
"""
function plot_surface(ex::Sym,
                      xvar=(-5.0, 5.0),
                      yvar=(-5.0, 5.0),
                      args...;
                      n::Int=35,
                      kwargs...)
    
    vars = free_symbols(ex)
    length(vars) == 2 || throw(DimensionMismatch("Expression has wrong number of variables. Expecting 2 for a surface plot"))
    
    U,V,xs,ys = _find_us_vs(ex, xvar, yvar, n)        
    zs = mapsubs2(ex, U, xs, V,ys)

    Plots.surface(xs, ys, z=Surface(zs), args...; kwargs...)
end
export plot_surface


## ## surface plot xvar = Tuple(Sym, Real, Real)
## ##
## """

## Render a parametrically defined surface plot.

## Example:
## ```
## @vars u, v
## plot_parametric_surface((u*v,u-v,u+v), (u,0,1), (v,0,1))
## ```

## Eventually uses `Plots.plot(..., linetype=:surf)`, so surface plots must be defined for the backend in use.
## """
## function plot_parametric_surface(exs::(@compat Tuple{Sym,Sym,Sym}),
##                                  xvar=(-5.0, 5.0),
##                                  yvar=(-5.0, 5.0),
##                                  args...;
##                                  n::Int=25, # really small, as otherwise this takes forever to plot
##                                  kwargs...)
    
##     vars = free_symbols(exs)
    
##     nvars = length(vars)
##     nvars == 2 || throw(DimensionMismatch("Expression has $nvars, expecting 2 for a surface plot"))
            
##     U,V,us,vs = _find_us_vs(exs, xvar, yvar, n)        
    
##     xs = mapsubs2(exs[1], U, us, V,vs)
##     ys = mapsubs2(exs[2], U, us, V,vs)
##     zs = mapsubs2(exs[3], U, us, V,vs)            

##     println(typeof(xs))
##     println(typeof(zs))
    
##     Plots.surface(xs, ys, z=Surface(zs), args...; kwargs...)
## end
## export plot_parametric_surface

## Helper functions

## the fallback pattern Float64[ex(x) for x in xs] has the
## disadvantage of several round trips between Julia and Python (and
## being v0.3 incompatible.  This functions tries to pass the xs all at once
## to Python, has it loop there, and then return the values. They
## come back as an array of type Any, so need conversion.
function mapsubs(ex::Sym, x::Sym, vals::AbstractVector)
    out = Float64[]
    try
        out = map(lambdify(ex), vals)
        out = map(Float64, out)
    catch err
        try
            out = pyeval("[fn(x,val) for val in vals]", fn=project(ex)[:subs], x=project(x), vals=vals)
            out = map(Float64, out)
        catch err
            out = Float64[ex(x) for x in vals]
        end
    end
    out
end

## This is similar to the above, but is used for two variables. It
## mimics Float64[ex(x,y) for x in xs, y in ys]
function mapsubs2(ex::Sym, x,xs, y, ys)
    out = Float64[]
    try
        fn = lambdify(ex, [x,y])
        out = [fn(u,v) for u in xs, v in ys]
        out = map(Float64, out)
    catch err
        try
            out = PyCall.pyeval("[fn(x,xval).subs(y,yval) for yval in yvals for xval in xvals]",
                                fn=ex.x[:subs],x=x.x,y=y.x,xvals=xs, yvals=ys)
            out = reshape(out, (length(xs), length(ys)))
            out = map(Float64, out)
        catch err
            out =Float64[ex(x,y) for x in xs, y in ys]
        end
    end
    out
end



## prepare parametic takes exs, [t0,t1] and returns [xs, ys] or [xs, ys, zs]
function _prepare_parametric(exs, t0, t1, n=250)
    vars = free_symbols(exs)
    nexs = length(exs)
    (nexs==2) | (nexs==3) || throw(DimensionMismatch("parametric plot requires the initial tuple to have 2 or 3 variables"))
    length(vars) == 1 ||  error("parametric plot allows only one free variable")

    ts = linspace(t0, t1, n)
    [Float64[convert(Float64, convert(Function, exs[i])(t)) for t in ts] for i in 1:nexs] # [[xs...], [ys...], [zs...]]
end

## parse (ex, ([x], a, b), ([y], c,d)) into variables x,y and ranges xs, ys.
function _find_us_vs(ex, xvar, yvar, n=100)
    vars = free_symbols(ex)
    if length(xvar) == 2
        U = vars[1]
        x1,x2 = xvar
    else
        U, x1, x2 = xvar
    end
    if length(yvar) == 2
        V = vars[2]
        y1,y2 = yvar
    else
        V, y1, y2 = yvar
    end
    xs = linspace(x1, x2, n)
    ys = linspace(y1, y2, n)
    U, V, xs, ys
end



## These functions give acces to SymPy's plotting module. They will work if PyPlot is installed, but may otherwise cause an error

## surface plot xvar = Tuple(Sym, Real, Real)
##
"""

Render a parametrically defined surface plot.

Example:
```
@vars u, v
plot_parametric_surface((u*v,u-v,u+v), (u,0,1), (v,0,1))
```

This uses `PyPlot`, not `Plots` for now.
"""
function plot_parametric_surface(exs::(@compat Tuple{Sym,Sym,Sym}),
                                 xvar=(-5.0, 5.0),
                                 yvar=(-5.0, 5.0),
                                 args...;
                                 n::Int=25, # really small, as otherwise this takes forever to plot
                                 kwargs...)

    SymPy.call_sympy_fun(sympy[:plotting][:plot3d_parametric_surface], exs..., args...; kwargs...)
    
end
export plot_parametric_surface





"""
Plot an implicit equation

```
@syms x y
plot(Eq(x^2+ y^2,3), (x, -2,2), (y,-2,2))
```

"""
plot_implicit(ex, args...; kwargs...) = SymPy.call_sympy_fun(sympy[:plotting][:plot_implicit], ex, args...; kwargs...)
export plot_implicit

## no Requires means no init this will be removed...
init_plot() = nothing
