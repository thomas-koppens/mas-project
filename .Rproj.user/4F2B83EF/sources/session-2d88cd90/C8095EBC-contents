# Data
data <- read.csv2("Adjusted-experiment.csv", sep = ',', header = TRUE)

print(head(data))
print(tail(data))
print(summary(data))
print(str(data))


# Model
model = lm(proportion ~ pop.weight * fam.weight, data = data)
print(summary(model))


# Graph
library(dplyr)
library(ggplot2)

data$proportion <- as.numeric(as.character(data$proportion))
data$proportion <- data$proportion * 100

average_data <- data %>%
  group_by(pop.weight, fam.weight) %>%
  summarize(average_proportion = mean(proportion), .groups = 'drop')

plot <- ggplot(average_data, aes(pop.weight, fam.weight, fill= average_proportion)) + 
  geom_tile() +
  scale_fill_gradient(low="white", high="Blue") + 
  theme_bw() + 
  labs(x = "Popularity Weight", y = "Familiarity Weight", title = "Heat Map Showing Dominant Percentage")
plot <- plot + guides(fill=guide_legend(title="Dominant Percentage"))

ggsave("HeatMap_DominantPercentage.png", last_plot(), width = 8, height = 5)