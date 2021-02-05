library(tidyverse)
library(purrr)
library(kableExtra) # for modifying table width
library(randomForest)
library(dplyr)
library(sandwich)
library(broom)


sales <- "SalesKaggle3.csv" %>% 
  read.csv %>%
  as_tibble %>%     
  rename(
    order = Order, 
    file_type = File_Type, 
    SKU_number = SKU_number,
    sold_flag = SoldFlag, 
    sold_count = SoldCount, 
    marketing_type = MarketingType, 
    release_number = ReleaseNumber, 
    new_release_flag = New_Release_Flag, 
    strength_factor = StrengthFactor, 
    price_reg = PriceReg, 
    release_year = ReleaseYear, 
    item_count = ItemCount, 
    low_user_price = LowUserPrice, 
    low_net_price = LowNetPrice
  ) %>% 
  mutate_at(
    vars(contains("flag")),
    as.factor
  )
sales %>% 
  count(file_type) %>% 
  knitr::kable(format = "html") %>% 
  kable_styling(full_width = F)
sales %>% sample_n(10000) %>% arrange(order) %>% visdat::vis_dat()

my_data <- sales[, c(7,9,10,11,12,13)]
round(cor(my_data),2)

## dividing into historical and active data
historical <- sales %>% filter(file_type == "Historical")
active <- sales %>% select(-one_of("sold_flag", "sold_count")) %>%filter(file_type == "Active")

##Verifying the Historical data count
historical %>% 
  filter(sold_count <= 5) %>% 
  mutate(sold_count = sold_count %>% as.factor) %>% # makes graph look better
  ggplot(aes(x = sold_count)) + 
  geom_bar(na.rm = TRUE, fill = "#00BFC4")

##Data Exploration
numeric_cols <- c(
  "release_year", "price_reg", "low_net_price", "low_user_price", 
  "item_count", "strength_factor", "release_number"
)
historical %>% select(numeric_cols) %>% GGally::ggpairs()


## Categorization
historical_train <- 
  historical %>% filter(sold_flag == 0) %>% sample_frac(0.8) %>% 
  rbind(
    historical %>% filter(sold_flag == 1) %>% sample_frac(0.8)
  )
head(historical_train)
historical_test <- historical %>% 
  anti_join(historical_train, by = "SKU_number")
view(historical_train)
##Smote
historical_SMOTE <- historical_train %>%
  as.data.frame %>% # DMwR package doesn't work with tibbles
  DMwR::SMOTE(
    sold_flag ~ marketing_type + release_number + 
      release_year + price_reg + low_net_price + 
      low_user_price + item_count + strength_factor,
    data = .
  ) %>% 
  as_tibble

##Regression categorisation with Random Forest
rf_smote_flag <- historical_SMOTE %>%   
  randomForest(
    formula = sold_flag ~ marketing_type + release_number + price_reg + low_net_price + 
      low_user_price + item_count + strength_factor,
    data = .,
    ntree = 1000
  )
rf_smote_flag_preds <- predict(rf_smote_flag, historical_test, "response") 
rf_smote_flag_cm <- rf_smote_flag_preds %>%
  caret::confusionMatrix(historical_test$sold_flag)
rf_smote_flag_cm

## Logisting Regression 
logistic_flag <- historical_SMOTE %>% glm(
  formula = sold_flag ~ marketing_type + release_number+ release_year + price_reg + low_net_price + 
    low_user_price + item_count + strength_factor,
  data = .,
  family = binomial(link = "logit")
)
summary(logistic_flag)
logistic_flag_cm <- logistic_flag %>% 
  predict(historical_test, type = "response") %>% 
  {ifelse(. > 0.5, 1, 0)} %>%
  as.factor %>% caret::confusionMatrix(historical_test$sold_flag)
logistic_flag_cm

##Linear Regression
lm_SMOTE_count <- historical_SMOTE %>% 
  lm(
    sold_count ~ marketing_type + release_number + price_reg + low_net_price + 
      low_user_price + item_count + strength_factor,
    data = .
  )

lm_SMOTE_count_preds <- predict(lm_SMOTE_count, historical_test)
lm_SMOTE_count %>% summary

## Predicting sale in the active inventory
active$sold_flag <- rf_smote_flag %>% predict(active, "response")
active$sold_flag_prob <-  (rf_smote_flag %>% predict(active, "prob"))[,2]

## For historical Data 
historical %>% 
  count(sold_flag) %>% 
  mutate(proportion = {100 * n / nrow(historical)} %>% round %>% paste0("%")) %>% 
  knitr::kable(format = "html") %>% 
  kable_styling(full_width = F)

## For active Data
active %>% 
  count(sold_flag) %>% 
  mutate(proportion = {100 * n / nrow(active)} %>% round %>% paste0("%")) %>% 
  knitr::kable(format = "html") %>% 
  kable_styling(full_width = F)

active <- active %>% 
  mutate(expected_value = sold_flag_prob * low_user_price)
active %>% 
  select(SKU_number, low_user_price, sold_flag_prob, expected_value) %>%
  arrange(-expected_value) %>% 
  {rbind(head(.), "...", tail(.))} %>%  # top 6 and bottom 6
  knitr::kable(format = "html") %>% 
  kable_styling(full_width = F)


preds_on_history <- predict(rf_smote_flag, historical_SMOTE, "vote")[,2]
plotData <- lapply(numeric_cols, function(x) {
  out <- tibble(
    var = x,
    value = historical_SMOTE[[x]],
    sold_flag = preds_on_history
  )
  out$value <- out$value-min(out$value) #Normalize to [0,1]
  out$value <- out$value/max(out$value)
  out
})
plotData <- do.call(rbind, plotData)
qplot(value, sold_flag, data = plotData, facets = ~ var, geom='smooth', 
      span = 0.5)

rf_smote_flag %>% 
  varImpPlot(main = "Variable effect according to random forest")
