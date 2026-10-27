# Construcción reproducible del panel analítico Q1
# Usa reglas congeladas en pilot_q1/design-freeze.md.
# Calcula métricas; no estima modelos explicativos.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

dir.create("pilot_q1/analysis_ready", recursive=TRUE, showWarnings=FALSE)

raw <- readr::read_csv(
  "pilot_q1/eurostat_mobs02.csv",
  show_col_types=FALSE,
  progress=FALSE,
  name_repair="minimal"
)

country_destinations <- raw %>%
  distinct(geo) %>%
  filter(str_detect(geo, "^[A-Z]{2}$")) %>%
  pull(geo)

country_origins <- raw %>%
  distinct(partner) %>%
  filter(str_detect(partner, "^[A-Z]{2}$")) %>%
  pull(partner)

x <- raw %>%
  filter(
    TIME_PERIOD >= 2013, TIME_PERIOD <= 2024,
    unit == "NR", sex == "T", isced11 == "ED5-8",
    geo %in% country_destinations,
    partner %in% country_origins
  ) %>%
  transmute(
    destination=geo,
    origin=partner,
    year=as.integer(TIME_PERIOD),
    value=as.numeric(OBS_VALUE),
    obs_flag=OBS_FLAG
  )

n_origins <- n_distinct(x$origin)

quality <- x %>%
  group_by(destination, year) %>%
  summarise(
    n_nonmissing=sum(!is.na(value)),
    completeness=n_nonmissing/n_origins,
    .groups="drop"
  )

dest_quality <- quality %>%
  group_by(destination) %>%
  summarise(
    n_years=n_distinct(year),
    years_ge95=sum(completeness >= .95),
    baseline_years=sum(year %in% 2017:2019 & completeness >= .95),
    disruption_years=sum(year %in% 2020:2021 & completeness >= .95),
    post_years=sum(year %in% 2022:2024 & completeness >= .95),
    .groups="drop"
  ) %>%
  mutate(
    primary = n_years == 12 & years_ge95 == 12,
    sensitivity = n_years >= 10 & years_ge95 >= 10 &
      baseline_years >= 2 & disruption_years == 2 & post_years >= 2
  )

primary_dest <- dest_quality %>% filter(primary) %>% pull(destination)
sensitivity_dest <- dest_quality %>% filter(sensitivity) %>% pull(destination)

write_csv(dest_quality, "pilot_q1/analysis_ready/sample_rules.csv")
write_csv(tibble(destination=primary_dest), "pilot_q1/analysis_ready/primary_destinations.csv")
write_csv(tibble(destination=sensitivity_dest), "pilot_q1/analysis_ready/sensitivity_destinations.csv")

calc_metrics <- function(dat) {
  dat %>%
    filter(!is.na(value), value >= 0) %>%
    group_by(destination, year) %>%
    mutate(
      total_students=sum(value, na.rm=TRUE),
      share=ifelse(total_students > 0, value/total_students, NA_real_)
    ) %>%
    summarise(
      total_students=first(total_students),
      n_positive=sum(value > 0, na.rm=TRUE),
      hhi=sum(share^2, na.rm=TRUE),
      top1_share=ifelse(total_students>0, sum(sort(share, decreasing=TRUE)[1:min(1,n())], na.rm=TRUE), NA_real_),
      top3_share=ifelse(total_students>0, sum(head(sort(share, decreasing=TRUE),3), na.rm=TRUE), NA_real_),
      top5_share=ifelse(total_students>0, sum(head(sort(share, decreasing=TRUE),5), na.rm=TRUE), NA_real_),
      shannon=ifelse(
        total_students>0,
        -sum(ifelse(share>0, share*log(share), 0), na.rm=TRUE),
        NA_real_
      ),
      .groups="drop"
    ) %>%
    mutate(
      effective_origins=ifelse(hhi>0, 1/hhi, NA_real_),
      entropy_norm=ifelse(n_positive>1, shannon/log(n_positive), 0)
    )
}

primary_metrics <- calc_metrics(x %>% filter(destination %in% primary_dest))
sensitivity_metrics <- calc_metrics(x %>% filter(destination %in% sensitivity_dest))

write_csv(primary_metrics, "pilot_q1/analysis_ready/primary_country_year_metrics.csv")
write_csv(sensitivity_metrics, "pilot_q1/analysis_ready/sensitivity_country_year_metrics.csv")

period_metrics <- primary_metrics %>%
  mutate(period=case_when(
    year %in% 2017:2019 ~ "baseline",
    year %in% 2020:2021 ~ "disruption",
    year %in% 2022:2024 ~ "post",
    TRUE ~ "other"
  )) %>%
  filter(period != "other") %>%
  group_by(destination, period) %>%
  summarise(
    mean_volume=mean(total_students, na.rm=TRUE),
    mean_hhi=mean(hhi, na.rm=TRUE),
    mean_effective_origins=mean(effective_origins, na.rm=TRUE),
    .groups="drop"
  ) %>%
  pivot_wider(
    names_from=period,
    values_from=c(mean_volume, mean_hhi, mean_effective_origins)
  ) %>%
  mutate(
    volume_retention=mean_volume_disruption/mean_volume_baseline,
    post_volume_ratio=mean_volume_post/mean_volume_baseline,
    shock_hhi_change=mean_hhi_disruption-mean_hhi_baseline,
    post_hhi_change=mean_hhi_post-mean_hhi_baseline
  )

write_csv(period_metrics, "pilot_q1/analysis_ready/primary_resilience_metrics.csv")

cat("\n=== PANEL ANALÍTICO CONGELADO ===\n")
cat("Muestra primaria:", length(primary_dest), "destinos\n")
cat("Muestra sensibilidad:", length(sensitivity_dest), "destinos\n")
cat("Filas país-año primarias:", nrow(primary_metrics), "\n")
cat("Esperadas panel balanceado:", length(primary_dest)*12, "\n")
cat("Primary destinations:", paste(primary_dest, collapse=", "), "\n")

if (length(primary_dest) != 25) stop("BLOCK: muestra primaria distinta de 25 tras reglas congeladas.")
if (nrow(primary_metrics) != 25*12) stop("BLOCK: panel primario no balanceado.")
if (any(is.na(primary_metrics$hhi))) stop("BLOCK: HHI faltante en panel primario.")

cat("PASS: muestra primaria y métricas reconstruidas según design-freeze.md.\n")
