suppressWarnings(suppressPackageStartupMessages({
	library(tidyverse)
	library(glue)
	library(logger)
}))

# See scripts/orbis_data_cleanup_log.qmd for code genesis

log_info("Cleanup Berlin Orbis panel to create sample for analysis")

dta <- readRDS("data/generated/orbis_panel_berlin.rds")

# Data tests

nobs_bvd_id_missing <- sum(is.na(dta$bvdid))
if (nobs_bvd_id_missing > 0) stop(
	glue(
		"Data contains {nobs_bvd_id_mssing} obsverations with missing bvd_id. ",
		"Check your data."
	)
)

year_missing <- sum(is.na(dta$year))
if (year_missing > 0) stop(
	glue(
		"Data contains {year_mssing} obsverations with a missing fiscal year. ", 
		"Check your data."
	)
)

dups <- dta %>%
	group_by(bvdid, year) %>%
	filter(n() > 1)

if (nrow(dups) > 0) stop(
	glue(
		"Found {nrow(dups)} duplicate obsverations at the firm/year level.", 
		"Check your data."
	)
) 

log_info("Data verified to be organized by bvdid and year.")

smp <- dta %>% 
	filter(
		!is.na(postcode), !is.na(shfd), !is.na(toas), 
		toas == tshf, toas >= shfd,
		year %in% 2006:2021
	) %>%
	mutate(
		name = name_native,
		equity = shfd,
		total_assets = toas,
		log_total_assets = log(total_assets),
		equity_ratio = shfd/(toas - ifelse(shfd < 0, shfd, 0)) 
	) %>%
	select(
		bvdid, year, name, postcode, equity, total_assets, 
		log_total_assets, equity_ratio
	)

log_info("Created sample")

# This below might happen if there are observations with total assets = 0
# and no negative equity in the data.
if (anyNA(smp)) stop("Sample contains missing observations. Check your data")

log_info("Verified that sample does not contain missing data")
saveRDS(smp, "data/generated/berlin_sample.rds")
