#' Categorize Robson values into main groups
#'
#' @param Robson A character or numeric vector of Robson values (e.g., '1.0', '2A', '10')
#' @return A character vector of simplified Robson categories ('1'-'7', '9', '10')
categorize_robson <- function(Robson) {
  dplyr::case_when(
    grepl("^10($|[^0-9])", Robson) ~ "10",
    grepl("^1($|[^0-9])", Robson) ~ "1",
    grepl("^2($|[^0-9])", Robson) ~ "2",
    grepl("^3($|[^0-9])", Robson) ~ "3",
    grepl("^4($|[^0-9])", Robson) ~ "4",
    grepl("^5($|[^0-9])", Robson) ~ "5",
    grepl("^6($|[^0-9])", Robson) ~ "6",
    grepl("^7($|[^0-9])", Robson) ~ "7",
    grepl("^9($|[^0-9])", Robson) ~ "9",
    TRUE ~ NA_character_
  )
}
