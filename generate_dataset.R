
decide <- function(age, monthly_salary, total_asset, total_required, number_installments){
	if (age <= 18 || age >= 70 + 18){
		return(0)
	}

	age_score <- (70 + 18 - age)/(70) * 100
	
	rate <- total_required / number_installments

	if (rate * 4 > monthly_salary){
		return (0)
	}
	if (rate * 10 < monthly_salary){
		montly_salary_score <- 100
	}
	else{
		montly_salary_score <- (1 - ((rate * 10) - monthly_salary)/(rate*10)) *100
	}
	if (total_asset > total_required){
		total_asset_score <- 100
	}
	else{
		total_asset_score <- (1 - (total_required - total_asset)/total_required) * 100
	}

	return ((age_score + montly_salary_score + total_asset_score)/3) 

}

generate_sample <- function(){
	age <- sample.int(100, 1, replace=TRUE)
        monthly_salary <- sample.int(20000, 1)
        total_asset <- sample.int(1000000, 1)
        total_required <-  sample.int(400000, 1)
        number_installments <-  sample.int(360, 1)

	out <- 100 - decide(age, monthly_salary, total_asset, total_required, number_installments)
	return (c(age, monthly_salary, total_asset, total_required, number_installments, out))
}

data <- replicate(30000, generate_sample())
data <- t(data)
colnames(data) <- c("Age", "MonthlySalary", "TotalAsset", "TotalRequired", "NumberInstallments", "Risk")

write.csv(data, "dataset.csv", row.names=FALSE)
