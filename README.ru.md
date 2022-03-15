# multitank-matbal-cli

*Переключиться на другой язык: [English](README.md), [Русский](README.ru.md)*

Реализован интерфес коммандной строки (CLI) для пакета [MultiTankMaterialBalance](https://github.com/sidelkin1/MultiTankMaterialBalance.jl).

## Быстрая установка

Предварительно должны быть установлены [Julia](http://julialang.org/downloads/) и [Git Bash](https://git-scm.com/downloads). Далее требуется

- Скачать CLI репозиторий с помощью команды 

```
git clone https://github.com/sidelkin1/multitank-matbal-cli
```

- Запустить `Julia REPL` и выполнить команду 
 
```julia
pwd("path/to/multitank-matbal-cli")
```

где требуется указать правильный путь к скачанному CLI репозиторию.

- Установить дополнительно требуемые пакеты через `Julia REPL` с помощью команды
 
```julia
using Pkg; Pkg.activate("."); Pkg.instantiate()
```

## Коммандный интерфейс

Внутри каталога со скачанным репозиторием находится папка `cli`, в которой для запуска основного скрипта `main.jl` требуется запустить пакетный файл `start.bat`.

### Аргументы коммандной строки

| Аргумент     | Описание |
| :---         |     :--- |
| `--options` | Путь к файлу с параметрами работы скрипта `options.toml` |
| `--tank_params` | Путь к файлу с начальными значениями параметров блоков `tank_params.csv` |
| `--tank_prod` | Путь к файлу с историей добычи/закачки `tank_prod.csv` |
| `--result_params` | Путь к файлу с рассчитанными значениями параметров блоков `result_params.csv` |
| `--result_prod` | Путь к файлу с рассчитанными давлениями внутри блоков `result_prod.csv` |

### Параметры работы скрипта

| Аргумент     | Описание |
| :---         |  :---    |
| `float` | Разрядность вещественных чисел |
| **[csv]** | **Параметры для чтения csv-файлов** |
| `dateformat` | Формат даты |
| `delim` | Формат разделителя |
| **[solver]** | **Настройки основного расчетчика** |
| `linalg` | Метод решения линейных уравнений (`dense`, `recursive`, `sparse`) |
| `reorder` | Способ переупорядочивания разреженой матрицы (`none`, `amd`, `metis`) |
| `maxiters` | Макисмальное число итераций в методе Ньютона |
| `P_tol` | Максимальная погрешность по давлению |
| `r_tol` | Максимальная погрешность по невязке |
| **[optimizer]** | **Настройка пакета оптимизации** |
| `package` | Пакет для минимизации целевой функции (`NLopt`, `SciPy`) |
| `scaling` | Способ масштабирования параметров (`linear`, `sigmoid`) |
| `maxiters` | Максимальное число итераций перебора методов оптимизации |
| **[optimizer.[package name]]** | **Список методов оптимизации из пакета `package name`** |
| `active` | Методы, которые будут перебираться в процессе минимизации целевой функции |
| `methods` | Список параметров метода оптимизации |
| **[target_fun]** | **Веса членов целевой функции** |
| `alpha_resp` | Cходимость пластового давления |
| `alpha_bhp` | Cходимость забойного давления добывающих скважин |
| `alpha_inj` | Cходимость забойного давления нагнетательных скважин |
| `alpha_lb` | Штраф при снижении пластового давления ниже минимального уровня |
| `alpha_ub` | Штраф при превышении пластового давления максимального уровня |
| `alpha_l2` | L2-регуляризация |

> **Примечание:** На текущий момент поддерживаются пакеты оптимизации [NLopt](https://github.com/JuliaOpt/NLopt.jl) и [SciPy](https://github.com/AtsushiSakai/SciPy.jl).

## Форматы данных

Внутри каталога со скачанным репозиторием находится папка `data`, в которой приведены примеры входных данных нужного формата для работы CLI.

### Параметры блоков

Параметры блоков хранятся в файле `tank_params.csv`.

#### Обозначения заголовка

| Заголовок     | Тип           | Описание |
| :---:         |     :---:     |     :--- |
| `Field` | `String` | Название месторождения |
| `Tank` | `String` | Идентификатор блока |
| `Reservoir` | `String` | Название пласта |
| `Neighb` | `Union{Missing, String}` | Идентификатор соседнего блока |
| `Parameter`| `String` | Обозначение параметра |
| `Date` | `Date` | Дата начала интервала фиксации значения параметра |
| `Init_value` | `Float64` | Начальное значения параметра |
| `Min_value` | `Float64` | Минимальное значения параметра |
| `Max_value` | `Float64` | Максимальное значения параметра |
| `alpha` | `Union{Missing, Float64}` | Множитель L2-регуляризации |

> **Примечание:** Непустое значение `Neighb` имеет смысл только для параметра `Tconn`.

> **Примечание:** Пустое значение `alpha` соответствует нулевому значению.

> **Примечание:** Для любого блока один и тот же параметр может иметь несколько **_непересекающихся_** интервалов фиксации своего значения. Т.о. каждый параметр можно представить в виде кусочно-постоянной функции от времени.

#### Обозначения параметров

| Параметр | Описание |
| :---:    |     :--- |
| `Tconn` | Межблочная проводимость (м<sup>3</sup>/сут/бар)[^1]
| `Pi` | Начальное пластовое давление (бар)[^2]
| `Bwi` | Начальный объемный коэффициент воды (д.ед.)[^2]
| `Boi` | Начальный объемный коэффициент нефти (д.ед.)[^2]
| `cw` | Сжимаемость воды (1/бар)[^2]
| `co` | Сжимаемость нефти (1/бар)[^2]
| `cf` | Сжимаемость порового пространства (1/бар)[^1]
| `Swi` | Начальная водонасыщенность (д.ед.)[^2]
| `Vpi` | Начальный поровый объем (м<sup>3</sup>)[^1]
| `Tconst` | Проводимость с границей постоянного давления (м<sup>3</sup>/сут/бар)[^1]
| `Prod_index` | Коэффициент продуктивности (м<sup>3</sup>/сут/бар)[^3]
| `Inj_index` | Коэффициент приемистости (м<sup>3</sup>/сут/бар)[^3]
| `Frac_inj` | Коэффициент эффективности закачки (д.ед.)[^1]
| `Min_Pres` | Минимальное давление в блоке (бар)[^2]
| `Max_Pres` | Максимальное давление в блоке (бар)[^2]
| `muw` | Вязкость воды (сПз)[^4]
| `muo` | Вязкость нефти (сПз)[^4]
| `krw_max` | Максимальное значение ОФП по воде (д.ед.)[^4]
| `kro_max` | Максимальное значение ОФП по нефти (д.ед.)[^4]
| `Geom_factor` | Геометрический фактор скважины ((м<sup>3</sup>/сут)*сПз/бар)[^5]

[^1]: Может быть настроен в процессе минимизации целевой функции.
[^2]: Не может быть настроен в процессе минимизации целевой функции.
[^3]: Настраивается автоматически после расчета пластового давления.
[^4]: Зарезервировано. Не используется в расчетах.
[^5]: Генерируется автоматически в результирующих файлах. Используется при расчете `Prod_index = Geom_factor * Total_mobility`, т.е. фактически настраивается параметр `Geom_factor` вместо `Prod_index`.

> **Примечание:** Для того, чтобы параметр рассматривался как требующий настройки, необходимо чтобы выполнялось условие `Min_value != Max_value`.

> **Примечание:** Параметры `Prod_index` и `Inj_index`, у которых `Min_value == Max_value`, дополнительно делятся на следующие группы:
> - если `Init_value != Min_value`, то параметр считается фиксированным, но **_не влияет_** на на расчет целевой функции;
> - если `Init_value == Min_value`, то параметр считается фиксированным, но **_влияет_** на расчет целевой функции.

### История добычи/закачки

История добычи/закачки для каждого блока хранится в файле `tank_prod.csv`.

| Заголовок     | Тип           | Описание |
| :---:         |     :---:     |     :--- |
| `Field` | `String` | Название месторождения |
| `Tank` | `String` | Идентификатор блока |
| `Reservoir` | `String` | Название пласта |
| `Date` | `Date` | Дата записи в формате `dd.mm.yyyy` |
| `Qoil` | `Float64` | Дебит нефти (м<sup>3</sup>/сут) |
| `Qwat` | `Float64` | Дебит воды (м<sup>3</sup>/сут) |
| `Qliq` | `Float64` | Дебит жидкости (м<sup>3</sup>/сут) (`Qliq = Qoil + Qwat`) |
| `Qinj` | `Float64` | Приемистость (м<sup>3</sup>/сут) |
| `Pres` | `Union{Missing, Float64}` | Замер пластового давления (бар) |
| `Source_resp` | `Union{Missing, String}` | Текстовое обозначение источника замера пластового давления |
| `Pbhp_prod` | `Union{Missing, Float64}` | Замер забойного давления добывающей скважины (бар) |
| `Pbhp_inj` | `Union{Missing, Float64}` | Замер забойного давления нагнетательной скважины (бар) |
| `Source_bhp` | `Union{Missing, String}` | Текстовое обозначение источника замера забойного давления |
| `Wellwork` | `Union{Missing, String}` | Текстовое обозначение проведенного геолого-технологического мероприятия |
| `Wcut` | `Float64` | Обводненность (д.ед.) |
| `Total_mobility` | `Float64` | Суммарная подвижность флюида (1/сПз) |
| `Wres` | `Union{Missing, Float64}` | Вес замера пластового давления |
| `Wbhp_prod` | `Union{Missing, Float64}` | Вес замера забойного давления добывающей скважины |
| `Wbhp_inj` | `Union{Missing, Float64}` | Вес замера забойного нагнетательной добывающей скважины |
| `Pres_min` | `Union{Missing, Float64}` | Минимально допустимое значение расчетного пластового давления |
| `Pres_max` | `Union{Missing, Float64}` | Максимально допустимое значение расчетного пластового давления |

> **Примечание:** Для корректного учета начальных условий на самую раннюю дату должна быть нулевая добыча/закачка по всем блокам (т.е. `Qoil == Qwat == Qliq == Qinj == 0`).

> **Примечание:** Каждая запись должна быть представлена с шагом в один календарный месяц.