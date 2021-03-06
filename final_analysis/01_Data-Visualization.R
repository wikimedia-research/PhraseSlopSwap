fig.dir <- "figures"
if ( !dir.exists(fig.dir) ) dir.create(fig.dir)

library(magrittr)
library(ggplot2)
library(ggthemes)

compress <- function(x, round.by = 2) {
  # by StackOverflow user 'BondedDust' : http://stackoverflow.com/a/28160474
  div <- findInterval(as.numeric(gsub("\\,", "", x)),
                      c(1, 1e3, 1e6, 1e9, 1e12) )
  paste(round( as.numeric(gsub("\\,","",x))/10^(3*(div-1)), round.by),
        c("","K","M","B","T")[div], sep = "" )
}

queries <- cbind(total = c(937042, 2749225, 2953510, 2978894, 3022186, 3054733, 2952947, 2949640, 2692848, 2784347, 3150729, 3015855),
                 fulltext_nonauto = c(327299, 994429, 1136251, 1000404, 953339, 923068, 876143, 875088, 844753, 921708, 1014520, 928063))
queries %<>% as.data.frame
queries$date <- log_dates
queries %<>% tidyr::gather("type", "n", 1:2)
# compress(seq(0, round(max(queries$total), -5), 2e5), 2) %>% paste0(collapse = "', '")

ggplot(data = queries, aes(x = date, y = n, color = type)) +
  geom_line(size = 1) + geom_point(size = 3) +
  scale_y_continuous(breaks = seq(0, round(max(queries$n), -5), 2e5),
                     labels = c('0K', '200K', '400K', '600K', '800M', '1M', '1.2M', '1.4M', '1.6M', '1.8M', '2M', '2.2M', '2.4M', '2.6M', '2.8M', '3M', '3.2M')) + 
  scale_x_datetime(breaks = scales::pretty_breaks(6),
                   labels = scales::date_format("%a, %m/%d")) +
  labs(title = "Data collected over test's duration") +
  scale_color_discrete(labels = c("total queries", "full-text, no-known-automata only")) +
  theme_fivethirtyeight()
ggsave(filename = file.path(fig.dir, "queries_over_time.png"), height = 4.5, width = 8)
rm(queries)

logs[[1]]$project %>% table %>% sort(decreasing = TRUE)

import::from(dplyr, full_join, group_by, summarise, arrange, keep_where = filter, select)

# Breakdown numbers by projects:
projects_n <- lapply(logs, with, expr = as.data.frame(table(project, group)))
for ( i in 1:length(projects_n) ) names(projects_n[[i]]) <- c('project', 'group', names(projects_n)[i])
rm(i)
projects_n <- Reduce(full_join, projects_n) %>% tidyr::gather("day", "n", 3:14)
projects_n %>% group_by(project, group) %>%
  summarise(total = sum(n, na.rm = TRUE)) %>%
  tidyr::spread(key = "group", value = "total") %>%
  dplyr::mutate(total = a + b + c) %>%
  dplyr::select(c(project, total, a, b, c)) %>%
  dplyr::mutate(a = sprintf("%.2f%%", 100*a/total),
                b = sprintf("%.2f%%", 100*b/total),
                c = sprintf("%.2f%%", 100*c/total)) %>%
  knitr::kable()
rm(projects_n)

projects_n <- lapply(logs_small, with, expr = as.data.frame(table(project, group)))
for ( i in 1:length(projects_n) ) names(projects_n[[i]]) <- c('project', 'group', names(projects_n)[i])
rm(i)
projects_n <- Reduce(full_join, projects_n) %>% tidyr::gather("day", "n", 3:14)
projects_n %>% group_by(project, group) %>%
  summarise(total = sum(n, na.rm = TRUE)) %>%
  tidyr::spread(key = "group", value = "total") %>%
  dplyr::mutate(total = a + b + c) %>%
  dplyr::select(c(project, total, a, b, c)) %>%
  dplyr::mutate(a = sprintf("%.2f%%", 100*a/total),
                b = sprintf("%.2f%%", 100*b/total),
                c = sprintf("%.2f%%", 100*c/total)) %>%
  knitr::kable()
rm(projects_n)

png(filename = file.path(fig.dir, "sampled_logs_mosaic.png"),
    height = 24, width = 12, units = "in", res = 300)
par(mfrow = c(6, 2), cex = 1.1)
for ( i in 1:12 ) {
  mosaicplot(outcome ~ group, data = logs_small[[i]], col = 2:4, shade = TRUE,
             main = as.character(as.Date(names(logs_small)[i]), format = "%A %m/%d"))
}; rm(i)
dev.off()

load("statistics/group_outcome_comparisons.RData")

stats_all <- dplyr::bind_rows(
  cbind(stats_AvsB, date = log_dates, `Slop Parameter Test` = "0 vs 1"),
  cbind(stats_AvsC, date = log_dates, `Slop Parameter Test` = "0 vs 2"),
  cbind(stats_BvsC, date = log_dates, `Slop Parameter Test` = "1 vs 2"))
ggplot(data = stats_all, aes(x = date,
                             y = `Odds Ratio`)) +
  geom_hline(y = 1, size = 1.25) +
  geom_ribbon(aes(ymin = Lower, ymax = Upper, fill = `Slop Parameter Test`), alpha = 0.25) +
  geom_point(aes(color = `Slop Parameter Test`), size = 4) +
  geom_line(aes(color = `Slop Parameter Test`), size = 1.1) +
  scale_x_datetime(breaks = scales::pretty_breaks(6),
                   labels = scales::date_format("%a, %m/%d")) +
  annotate("text", x = lubridate::ymd("2015-08-27"), y = 2,
           label = "Second group MORE likely than first group") +
  annotate("text", x = lubridate::ymd("2015-08-27"), y = 0.3,
           label = "Second group LESS likely than first group") +
  labs(title = "Odds ratios (relative likelihoods)") +
  theme_fivethirtyeight()
ggsave(filename = file.path(fig.dir, "odds_ratios_over_time.png"), height = 6, width = 8)
rm(stats_all)
