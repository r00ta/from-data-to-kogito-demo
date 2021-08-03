library(pmml)
library(randomForest)

data <- read.csv("dataset.csv")

formula <- as.formula(paste("Risk", ' ~ .' ))

model <- randomForest(formula, data=data, ntree=3)

saveXML(pmml(model), "risk_rf.pmml")

