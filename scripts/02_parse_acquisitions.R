#!/usr/bin/env Rscript

library(here)
library(data.table)
library(stringr)

## Year to parse
year        <- 2022
output      <- here("metadata",
                    str_glue("y{year}_{c('sequences', 'files')}.csv"))

## Read all acquisition files and compile in one data.table
here("metadata", year)        |>
  list.files(full.names = T)  |>
  str_subset("\\.acquis$")    |>
  lapply(fread, drop = 1)     |>
  rbindlist()                 |>
  unique()                    |>
  setnames(make.names)        |>
  setorder(Name.of.series)    |>
  fwrite(output[1])

here("metadata", year)        |>
  list.files(full.names = T)  |>
  str_subset("\\.files$")     |>
  lapply(fread,
         drop = c(2,3,5,6))   |>
  rbindlist()                 |>
  unique()                    |>
  setorder(Series)            |>
  fwrite(output[2])
