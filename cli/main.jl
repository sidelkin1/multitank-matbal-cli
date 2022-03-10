using MultiTankMaterialBalance
using NLopt
using TOML
using ArgParse

include("optimize.jl")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--options"
            help = "Path to the file with calculation settings"
            arg_type = String
            required = true
        "--tank_params"
            help = "Path to the file with tank parameters"
            arg_type = String
            required = true
        "--tank_prod"
            help = "Path to the file with tank production/injection data"
            arg_type = String
            required = true
        "--result_params"
            help = "Path to the file with calculated tank parameters"
            arg_type = String
            required = true
        "--result_prod"
            help = "Path to the file with calculated tank reservoir pressures"
            arg_type = String
            required = true
    end

    return parse_args(ARGS, s)
end

function main()
    parsed_args = parse_commandline()
    
    # Settings for calculation
    opts = TOML.parsefile(parsed_args["options"])
    
    # Float-point precision
    Float = eval(Meta.parse(opts["float"]))

    # Initial data for calculation
    df_rates = read_rates(parsed_args["tank_prod"], opts["csv"])
    df_params = read_params(parsed_args["tank_params"], opts["csv"])
    process_params!(df_params, df_rates)

    # Description of the forward problem
    prob = NonlinearProblem{Float}(df_rates, df_params)

    # Parameter scaling method
    if opts["optimizer"]["scaling"] == "linear"
        scale = LinearScaling{Float}(df_params)
    elseif opts["optimizer"]["scaling"] == "sigmoid"
        scale = SigmoidScaling{Float}(df_params)
    end

    # Linear equation solution method
    if opts["solver"]["linalg"] == "dense"
        linalg = DenseLinearSolver{Float}(prob)
    elseif opts["solver"]["linalg"] == "recursive"
        linalg = RecursiveLinearSolver{Float}(prob)
    elseif opts["solver"]["linalg"] == "sparse"
        reorder = Symbol(opts["solver"]["reorder"])
        linalg = SparseLinearSolver{Float}(prob; reorder)
    end

    # Algorithm for solving the forward problem
    solver = NewtonSolver{Float}(prob, linalg, opts["solver"])
    # List of parameters to be fitted
    fset = FittingSet{Float}(df_params, prob, scale)
    # Objective function
    targ = TargetFunction{Float}(df_rates, df_params, prob, fset, opts["target_fun"])
    # Algorithm for calculating the gradient of the objective function
    adjoint = AdjointSolver{Float}(prob, targ, linalg, fset)

    # History-matching of model
    optim_pkg = Symbol(opts["optimizer"]["package"])
    maxiters = opts["optimizer"]["maxiters"]
    optim_opts = opts["optimizer"][String(optim_pkg)]
    optim_fun = fun(fset, solver, targ, adjoint, Val(optim_pkg))
    initial_x = copy(getparams!(fset))
    res = optimize(optim_fun, initial_x, maxiters, optim_opts, scale, Val(optim_pkg))

    # Print the results
    print_result(res, initial_x, optim_fun, targ, Val(optim_pkg))

    # Save the results   
    save_rates!(df_rates, prob, parsed_args["result_prod"], opts["csv"])
    save_params!(df_params, fset, targ, parsed_args["result_params"], opts["csv"])

    nothing
end

@time main()