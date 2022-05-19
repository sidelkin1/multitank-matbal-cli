# multitank-matbal-cli

*Read this in other languages: [English](README.md), [Русский](README.ru.md)*

Command Line Interface (CLI) for the package [MultiTankMaterialBalance](https://github.com/sidelkin1/MultiTankMaterialBalance.jl) is implemented.

## Quick installation

[Julia](http://julialang.org/downloads/) and [Git Bash](https://git-scm.com/downloads) must be installed first. Next you need

- Download CLI repository using command

```
git clone https://github.com/sidelkin1/multitank-matbal-cli
```

- Start `Julia REPL` and run the command
 
```julia
cd("path/to/multitank-matbal-cli")
```

where you need to specify the correct path to the downloaded CLI repository.

- Install additional required packages via `Julia REPL` with the command
 
```julia
using Pkg; Pkg.activate("."); Pkg.instantiate()
```

## Command interface

Inside the directory with the downloaded repository there is the `cli` folder, in which for the running the main script `main.jl` you need to run the batch file `start.bat`.

### Command line arguments

| Argument     | Description |
| :---         |     :--- |
| `--options` | Path to the file with the parameters of the script `options.toml` |
| `--tank_params` | Path to the file with the initial values of the tank parameters `tank_params.csv` |
| `--tank_prod` | Path to file with production/injection history `tank_prod.csv` |
| `--result_params` | Path to the file with calculated tank parameter values `result_params.csv` |
| `--result_prod` | Path to the file with calculated reservoir pressures inside the tanks `result_prod.csv` |

### Script parameters

| Argument     | Description |
| :---         |  :---    |
| `float` | Floating-point precision |
| **[csv]** | **Options for reading csv files** |
| `dateformat` | Date format |
| `delim` | Delimeter |
| **[solver]** | **Base solver settings** |
| `linalg` | Method for solving linear equations (`dense`, `recursive`, `sparse`) |
| `reorder` | Reordering scheme of a sparse matrix (`none`, `amd`, `metis`) |
| `maxiters` | Maximum number of iterations in Newton method |
| `P_tol` | Maximum pressure tolerance |
| `r_tol` | Maximum residual tolerance |
| **[optimizer]** | **Optimization package settings** |
| `package` | Objective function minimization package (`NLopt`, `SciPy`) |
| `scaling` | Parameter scaling method (`linear`, `sigmoid`) |
| `maxiters` | Maximum number of iterations for looping through optimization methods |
| **[optimizer.[package name]]** | **List of optimization methods from the package `package name`** |
| `active` | Methods that will be cycled in the process of minimizing the objective function |
| `methods` | List of optimization method parameters |
| **[target_fun]** | **Weights of objective function terms** |
| `alpha_resp` | Reservoir pressure convergence |
| `alpha_bhp` | Bottom-hole pressure of producers convergence |
| `alpha_inj` | Bottom-hole pressure of injectors convergence |
| `alpha_lb` | Penalty when reservoir pressure drops below the minimum level |
| `alpha_ub` | Penalty when reservoir pressure exceeds the maximum level |
| `alpha_l2` | L2-regularization |

> **Note:** The currently supported optimization packages are [NLopt](https://github.com/JuliaOpt/NLopt.jl) and [SciPy](https://github.com/AtsushiSakai/SciPy.jl).

## Data formats

Inside the directory with the downloaded repository there is the `data` folder, which contains examples of input data required for the CLI to work.

### Tank parameters

Tank parameters are stored in the `tank_params.csv` file.

#### Header description

| Header     | Type           | Description |
| :---:         |     :---:     |     :--- |
| `Field` | `String` | Field name |
| `Tank` | `String` | Tank name |
| `Reservoir` | `String` | Reservoir name |
| `Neighb` | `Union{Missing, String}` | Neighbouring tank name |
| `Parameter`| `String` | Parameter name |
| `Date` | `Date` | Start date of the parameter value fixing interval |
| `Init_value` | `Float64` | Initial parameter value |
| `Min_value` | `Float64` | Minimum parameter value |
| `Max_value` | `Float64` | Maximum parameter value |
| `alpha` | `Union{Missing, Float64}` | Weight of L2-regularization term |

> **Note:** The non-missing value `Neighb` only makes sense for the `Tconn` parameter.

> **Note:** An missing `alpha` value corresponds to a null value.

> **Note:** For any tank, the same parameter can have several **_non-overlapping_** intervals for fixing its value. Thus, each parameter can be represented as a piecewise constant function of time.

#### Parameter names

| Parameter | Descrition |
| :---:    |     :--- |
| `Tconn` | Inter-tank transmissibility (m<sup>3</sup>/day/bar)[^1]
| `Pi` | Initial reservoir pressure (atm)[^2]
| `Bwi` | Initial fractional volume of water (frac.)[^2]
| `Boi` | Initial fractional volume of oil (frac.)[^2]
| `cw` | Water compressibility (1/bar)[^2]
| `co` | Oil compressibility (1/bar)[^2]
| `cf` | Porous volume compressibility (1/bar)[^2]
| `Swi` | Initial water saturation (frac.)[^2]
| `Vpi` | Initial porous volume (m<sup>3</sup>)[^1]
| `Tconst` | Constant-pressure boundary transmissibility (m<sup>3</sup>/day/bar)[^1]
| `Prod_index` | Productivity index (m<sup>3</sup>/day/bar)[^3]
| `Inj_index` | Injectivity index (m<sup>3</sup>/day/bar)[^3]
| `Frac_inj` | Injection efficiency factor (frac.)[^1]
| `Min_Pres` | Minimum tank pressure (bar)[^2]
| `Max_Pres` | Maximum tank pressure (bar)[^2]
| `muw` | Water viscosity (cPs)[^4]
| `muo` | Oil viscosity (cPs)[^4]
| `krw_max` | Maximum water relative permeability value (frac.)[^4]
| `kro_max` | Maximum oil relative permeability value (д.ед.)[^4]
| `Geom_factor` | Well geometric factor ((m<sup>3</sup>/day)*cPs/bar)[^5]

[^1]: Can be fitted during objective function minimization.
[^2]: Can't be fitted during objective function minimization.
[^3]: It is fitted automatically after each reservoir pressure calculation.
[^4]: Reserved. Not used in calculations.
[^5]: Generated automatically in the resulting files. It's used when calculating `Prod_index = Geom_factor * Total_mobility`, i.e. actually `Geom_factor` is fitted instead of `Prod_index`.

> **Note:** In order for a parameter to be considered as requiring fitting, the condition `Min_value != Max_value` must be satisfied.

> **Note:** The `Prod_index` and `Inj_index` parameters, for which `Min_value == Max_value` is true, are further divided into the following groups:
> - if `Init_value != Min_value`, then the parameter is considered fixed, but **_does not_** affect the calculation of the objective function;
> - if `Init_value == Min_value`, then the parameter is considered fixed, but **_do_** affects the calculation of the objective function.

### History of production/injection

The production/injection history for each tank is stored in the `tank_prod.csv` file.

| Header     | Type           | Description |
| :---:         |     :---:     |     :--- |
| `Field` | `String` | Field name |
| `Tank` | `String` | Tank name |
| `Reservoir` | `String` | Reservoir name |
| `Date` | `Date` | Record date formatted as `dd.mm.yyyy` |
| `Qoil` | `Float64` | Oil flow rate (m<sup>3</sup>/day) |
| `Qwat` | `Float64` | Water flow rate (m<sup>3</sup>/day) |
| `Qliq` | `Float64` | Liquid flow rate (m<sup>3</sup>/day) (`Qliq = Qoil + Qwat`) |
| `Qinj` | `Float64` | Injection flow rate (m<sup>3</sup>/day) |
| `Pres` | `Union{Missing, Float64}` | Reservoir pressure measurement (bar) |
| `Source_resp` | `Union{Missing, String}` | Text designation of reservoir pressure measurement source |
| `Pbhp_prod` | `Union{Missing, Float64}` | Bottom-hole pressure measurement of producer (bar) |
| `Pbhp_inj` | `Union{Missing, Float64}` | Bottom-hole pressure measurement of injector (bar) |
| `Source_bhp` | `Union{Missing, String}` | Text designation of bottom-hole pressure measurement source |
| `Wellwork` | `Union{Missing, String}` | Text designation of the carried out workover |
| `Wcut` | `Float64` | Water-cut (frac.) |
| `Total_mobility` | `Float64` | Total fluid mobility (1/cPs) |
| `Wres` | `Union{Missing, Float64}` | Weight of reservoir pressure measurement |
| `Wbhp_prod` | `Union{Missing, Float64}` | Weight of bottom-hole pressure measurement of producer |
| `Wbhp_inj` | `Union{Missing, Float64}` | Weight of bottom-hole pressure measurement of injector |
| `Pres_min` | `Union{Missing, Float64}` | The minimum allowable value of the calculated reservoir pressure |
| `Pres_max` | `Union{Missing, Float64}` | The maximum allowable value of the calculated reservoir pressure |

> **Note:** To correctly take into account the initial conditions at the earliest date, there should be zero production/injection rates for all tanks (i.e. `Qoil == Qwat == Qliq == Qinj == 0`).

> **Note:** Each record must be submitted with step size in one calendar month.
