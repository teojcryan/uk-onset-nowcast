suppressMessages(require(here, quietly = TRUE))
require(dplyr, quietly = TRUE, warn.conflicts = FALSE)
require(readr, quietly = TRUE)
require(data.table, quietly = TRUE)

### nhse to LTLA lookup table ------------------------------------
ltla_nhser <- readRDS(here::here("data", "ltla_nhser.rds"))

### Early archived data (20200409 - 20210223) --------------------
# credit to theosanderson
date_start <- as.Date('2020-08-11')
date_end <- as.Date('2021-02-23')
date_lst <- seq.Date(date_start, date_end, by='days')

for (i in 1:length(date_lst)){
  date <- date_lst[i]
  skip_to_next <- FALSE
  
  tryCatch({
    dt <- fread(paste0(
      "https://raw.githubusercontent.com/theosanderson/covid_uk_data_timestamped/master/all/",date,".csv"
    ))
    
    dt_clean <- dt[`Area name` == "England"
    ][
      , .(date = as.Date(`Specimen date`),
          region = `Area name`,
          cases = `Daily lab-confirmed cases`
      )
    ]
    
    rm(dt)
    gc()
    saveRDS(dt_clean, 
            here::here(paste0("data/cases_specimen/national/",
                              gsub("-", "_", date),
                              ".rds")))    
  }, error = function(e) { skip_to_next <- TRUE })
  
  if (skip_to_next) { next }
}

### COVID-19 dashboard archived data (20210224 - ) ------------------- 
# set start and end date
date_start <- as.Date("2021-02-23")
date_end <- Sys.Date() - 1
n_days <- as.numeric(date_end - date_start)

# load data 
for (n in 1:n_days){
  print(paste0(round(100*n/n_days, 3), "%"))
  date <- Sys.Date() - n
  skip_to_next <- FALSE
  
  tryCatch({
    dt <- data.table::fread(paste0(
      "https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&",
      "areaCode=E92000001&", # England data only
      "metric=newCasesBySpecimenDate&",
      "metric=newCasesLFDConfirmedPCRBySpecimenDate&",
      "metric=newCasesLFDOnlyBySpecimenDate&",
      "metric=newCasesPCROnlyBySpecimenDate&",
      "format=csv&",
      "release=", date
    ))
    
    dt_clean <- dt[
        , .(date = as.Date(date),
            cases = `newCasesBySpecimenDate`,
            cases_lfd_pcr = `newCasesLFDConfirmedPCRBySpecimenDate`,
            cases_lfd = `newCasesLFDOnlyBySpecimenDate`,
            cases_pcr = `newCasesPCROnlyBySpecimenDate`
      )
    ]
    
    saveRDS(dt_clean, 
            here::here(paste0("data/cases/national/", date, ".rds")))
  }, error = function(e) { skip_to_next <- TRUE })
  
  if (skip_to_next) { next }
}

