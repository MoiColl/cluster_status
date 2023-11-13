library(tidyverse)
library(cowplot)
library(ggiraph)

#Instead of manually creating running the .cluster_status.sh in the cluster and later downloading the output file, you can let R to do it with those commads
#You still need to have a copy of .cluster_status.sh in your home directory on the cluster
#system("ssh <USER>@login.genome.au.dk 'bash .cluster_status.sh'")
#system("scp <USER>l@login.genome.au.dk:.cluster_status.txt ~/cluster_status.txt")

path_cluster_status <- "~/cluster_status.txt"
color_users <- c()

read.table(path_cluster_status, header = T) %>%
  filter(STATE != "COMPLETING") %>%
  mutate(STATE = ifelse(NODELIST.REASON. == "(Dependency)", paste("D", STATE, sep = ""), STATE)) %>%
  select(-c(NODELIST.REASON.)) %>%
  mutate(START_TIME =  as.POSIXct(strptime(START_TIME, "%Y-%m-%dT%H:%M:%S")),
         SUBMIT_TIME = as.POSIXct(strptime(SUBMIT_TIME, "%Y-%m-%dT%H:%M:%S")),
         WAITING = log10(as.numeric(START_TIME-SUBMIT_TIME))) %>%
  mutate(MEM = ifelse(str_detect(MIN_MEMORY, "M"),
                        as.numeric(as.character(gsub("M", "", MIN_MEMORY)))**0.001,
                        as.numeric(as.character(gsub("G", "", MIN_MEMORY))))) %>%
  separate(TIME,             c("TIME_D", "TIME_HOURS"),                         sep = "-", fill = "left") %>%
  separate(TIME_HOURS,       c("TIME_H", "TIME_M", "TIME_S"),                   sep = ":", fill = "left") %>%
  separate(TIME_LIMIT,       c("TIME_LIMIT_D", "TIME_LIMIT_HOURS"),             sep = "-", fill = "left") %>%
  separate(TIME_LIMIT_HOURS, c("TIME_LIMIT_H", "TIME_LIMIT_M", "TIME_LIMIT_S"), sep = ":", fill = "left") %>%
  mutate(TIME_D       = ifelse(is.na(TIME_D),       0, as.numeric(as.character(TIME_D))*24),
         TIME_H       = ifelse(is.na(TIME_H),       0, as.numeric(as.character(TIME_H))),
         TIME_M       = ifelse(is.na(TIME_M),       0, as.numeric(as.character(TIME_M))/60),
         TIME_S       = ifelse(is.na(TIME_S),       0, as.numeric(as.character(TIME_S))/(60*60)),
         TIME_LIMIT_D = ifelse(is.na(TIME_LIMIT_D), 0, as.numeric(as.character(TIME_LIMIT_D))*24),
         TIME_LIMIT_H = ifelse(is.na(TIME_LIMIT_H), 0, as.numeric(as.character(TIME_LIMIT_H))),
         TIME_LIMIT_M = ifelse(is.na(TIME_LIMIT_M), 0, as.numeric(as.character(TIME_LIMIT_M))/60),
         TIME_LIMIT_S = ifelse(is.na(TIME_LIMIT_S), 0, as.numeric(as.character(TIME_LIMIT_S)))/(60*60)) %>%
  mutate(TIME       = TIME_D+TIME_H+TIME_M+TIME_S,
         TIME_LIMIT = TIME_LIMIT_D+TIME_LIMIT_H+TIME_LIMIT_M+TIME_LIMIT_S,
         TIME_PERC  = TIME*100/TIME_LIMIT) %>%
  select(-c(TIME_D, TIME_H, TIME_M, TIME_S, TIME_LIMIT_D, TIME_LIMIT_H, TIME_LIMIT_M, TIME_LIMIT_S, MIN_MEMORY, SUBMIT_TIME, START_TIME)) -> df

df %>% head()

df %>%
  group_by(USER, STATE) %>%
  summarize(n = n()) %>%
  spread(STATE, n, fill = 0) %>%
  arrange(RUNNING) %>%
  pull(USER) -> user_order

df %>%
  mutate(USER = factor(USER, levels = user_order)) -> df


df %>%
  gather("stat", "value", c(TIME, TIME_LIMIT, TIME_PERC, MEM, PRIORITY, WAITING)) %>% 
  ggplot() +
  geom_boxplot_interactive(aes(x = USER, y = value, tooltip = USER, data_id = USER)) +
  facet_grid(stat~STATE, scales = "free_y") +
  theme(#axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.x = element_blank()) -> plot1

df %>%
  group_by(USER, STATE) %>%
  summarize(n = n()) %>%
  ggplot() +
  geom_bar_interactive(stat = "identity", aes(x = USER, y = log10(n), tooltip = USER, data_id = USER)) +
  facet_grid("NUM_JOBS"~STATE) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
        strip.text.x = element_blank()) -> plot2

if(length(color_users)){
  plot1 <- plot1 + 
    geom_boxplot_interactive(data = . %>% filter(USER %in% color_users), aes(x = USER, y = value, color = USER, tooltip = USER, data_id = USER), width = 1, show.legend = FALSE) 

  plot2 <- plot2 + 
    geom_bar_interactive(data = .%>% filter(USER %in% color_users), stat = "identity", aes(x = USER, y = log10(n), fill = USER, tooltip = USER, data_id = USER), width = 1, show.legend = FALSE)
}


plot_grid(
  plot1,
  NULL,
  plot2,
  ncol = 1, rel_heights = c(2, -0.035, 1), align = "v") -> plot
  

girafe(ggobj = plot, width_svg = 9, height_svg = 6, opts_sizing(rescale = FALSE))

