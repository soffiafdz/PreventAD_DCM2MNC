#!/usr/bin/env Rscript

library(here)
library(data.table)
library(stringr)

## This needs to be done manually by year ##
# Year to parse
year        <- 2019

## Sequences to keep
mnc_seqs.DT <- data.table(mnc_name = c("T1w", "T1w", "T1w",
                                       "FLAIR", "T2w"),
                          mnc_flag = c("mprage", "MP2RAGE", "cor",
                                       "Flair", "T2W"))
## This needs to be done manually by year ##

# Parse files to extract filenames
files.DT    <-
  here("metadata", year)      |>
  list.files(full.names = T)  |>
  str_subset("\\.files$")     |>
  lapply(fread,
         select = c(1, 4, 6)) |>
  rbindlist(idcol = "file")

setnames(files.DT, c("dir", "snum", "sname", "fname"))

# Filter only sequences in mnc_seqs.DT
for (pattern in mnc_seqs.DT[, mnc_flag]) {
  files.DT[sname %like% pattern, mnc_flag := pattern]
}

# Extract directory names
dirnames.DT <-
  here("metadata", year)      |>
  list.files()                |>
  str_subset("\\.meta$")      |>
  str_remove("\\.[^.]*$")     |>
  as.data.table()

setnames(dirnames.DT, "dirname")
dirnames.DT[, dir := 1:.N]

# Join everything together
fnames.DT   <-
  mnc_seqs.DT[files.DT[!is.na(mnc_flag)], on = "mnc_flag"
            ][dirnames.DT, on = "dir",
              .(dirname, affix = paste(mnc_name, snum, sep = "-"), fname)]

seqs.DT     <- fnames.DT[, .N, .(dirname, affix)]

unique(fnames.DT[, .(dirname, affix)])[, .N]  ## 1,264 unique sequences

# Create lists of files
for (i in 1:seqs.DT[, .N]) {
  outdir    <- here("lists", year, seqs.DT[i, dirname])
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  outfile   <- here(outdir, seqs.DT[i, paste0(affix, ".lst")])
  fnames.DT[seqs.DT[i], on = .(dirname, affix), .(fname)] |>
  fwrite(outfile, col.names = FALSE)
}
