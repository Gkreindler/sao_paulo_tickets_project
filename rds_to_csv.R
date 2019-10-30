# library for writing to .dta
library(foreign)

# set working directory
setwd("/Users/san/Dropbox/sao_paulo_tickets_project/")

# read tickets files
tickets <- readRDS("data/tickets/all_tickets.rds")

# write tickets file as dta
write.dta(tickets, "data/tickets_v2/tickets.dta")

# write tickets file to .csv
# write.csv(tickets, file = "tickets.csv")
