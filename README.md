# Analysis of Pregnant Women Data

This project analyzes data from pregnant women, focusing on factors such as type of birth, color/race, and marital status. The analysis is performed using an R script that processes an Excel dataset and generates various visualizations.

## Dataset

The primary dataset is an Excel file named `BD_completo_corrigido_12-02-2025.xlsx`. This file contains:
- A sheet named "Sheet1" with the main data on pregnant women.
- A sheet named "Dicionário" which serves as a data dictionary, providing explanations for the fields in the main data sheet.

## R Script: `2025_03_29_analisesGestantes.R`

The core analysis is performed by the R script `2025_03_29_analisesGestantes.R`.

### Required R Libraries
The script requires the following R libraries to be installed:
- `tidyverse`
- `readxl`
- `vcd`
- `ggplot2`
- `scales`

You can install these libraries in R using the command `install.packages("library_name")`.

### Script Workflow
The script follows these main steps:
1.  **Loads Libraries:** Imports all necessary R packages.
2.  **Reads Data:** Loads data from the "Sheet1" and "Dicionário" sheets in the `BD_completo_corrigido_12-02-2025.xlsx` Excel file.
3.  **Filters Data:** Applies several filtering criteria:
    *   Removes records with missing type of birth (`tipo_parto`).
    *   Removes records with missing age (`idade`).
    *   Includes only ages between 11 and 34 years (inclusive of 11, exclusive of 35).
    *   Excludes records where the origin (`origem`) is "Adolescentes" and age (`idade`) is 20.
4.  **Performs Analysis and Visualization:**
    *   Analyzes and creates visualizations for the relationship between the type of pregnant woman (`origem`) and:
        *   Type of birth (`tipo_parto`).
        *   Color/Race (`cor_cat`).
        *   Marital status (`estado_civil_cat`, which is recategorized).
    *   Generates mosaic plots, association plots, and bar charts for these analyses.
    *   Saves some of the generated charts as PNG files.

## Generated Outputs

The R script generates and saves the following plots as PNG files:

-   **`graficoGestantesCor.png`**: Bar chart showing the absolute number of pregnant women grouped by self-declared color/race category and type of pregnant woman (`origem`).
-   **`graficoGestantesCorFreq.png`**: Bar chart showing the percentage of pregnant women grouped by self-declared color/race category and type of pregnant woman (`origem`).
-   **`graficoGestantesEstadoCivil.png`**: Bar chart showing the absolute number of pregnant women grouped by marital status and type of pregnant woman (`origem`).
-   **`graficoGestantesEstadoCivilFreq.png`**: Bar chart showing the percentage of pregnant women grouped by marital status and type of pregnant woman (`origem`).

These files are saved in the same directory where the script is executed.

## How to Run the Script

1.  **Ensure R is installed:** You need a working R environment.
2.  **Install Required Libraries:** Open R or RStudio and install the necessary packages if you haven't already:
    ```R
    install.packages("tidyverse")
    install.packages("readxl")
    install.packages("vcd")
    install.packages("ggplot2")
    install.packages("scales")
    ```
3.  **Prepare Files:**
    *   Place the R script `2025_03_29_analisesGestantes.R` in a directory on your computer.
    *   Ensure the Excel data file `BD_completo_corrigido_12-02-2025.xlsx` is in the *same directory* as the R script. If it's not, you will need to modify the file path in the `read_excel` functions within the script.
4.  **Execute the Script:**
    *   Open the `2025_03_29_analisesGestantes.R` script in RStudio or your preferred R environment.
    *   Run the entire script.
5.  **Check Outputs:** The script will print summaries and test results to the console. The generated PNG image files (`graficoGestantesCor.png`, `graficoGestantesCorFreq.png`, `graficoGestantesEstadoCivil.png`, `graficoGestantesEstadoCivilFreq.png`) will be saved in the same directory where the script was run.

## Notes

-   The script includes several data filtering steps. Users should review these filters (e.g., age range, exclusion of specific cases) to ensure they are appropriate for their analysis context if reusing or modifying the script.
-   The data dictionary ("Dicionário" sheet in the Excel file) is crucial for understanding the variables used in the analysis.
