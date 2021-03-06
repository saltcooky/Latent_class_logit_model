# 潜在クラスロジットモデルの実装

library(tidyverse)
library(mlogit)
library(flexmix)
data(Catsup)

# 時間ステップの追加
Catsup <- Catsup %>% 
  mutate(t = seq_len(nrow(Catsup))) 
  
# 変換の関数
tranceforme_catsup <- function(brand){
  df <- Catsup %>% 
   select(id, contains(brand), choice, t) %>% 
    rename(display = starts_with("dis"),
           price = starts_with("pri"),
           feature = starts_with("fea")) %>% 
    mutate(brand = brand)
  return(df)
}

Cdata <- Catsup$choice %>%
  unique() %>% 
  as.character() %>% 
  map(tranceforme_catsup) %>% 
  bind_rows() %>% 
  mutate(choice = with(.,choice == brand)) 

#hunts32のブランド価値を0に設定
Cdata$brand <- relevel(factor(Cdata$brand), "hunts32")

# いくつかのクラス数モデルを作成して当てはまりの良いクラス数を調べる
I <- 10
aic <- as.numeric(c())
bic <- as.numeric(c())

set.seed(42)

for(i in 1:I){
  print(i)
  tmp_model = flexmix(choice ~ display + feature + price + brand | id, 
               model = FLXMRcondlogit(strata = ~ t), 
               data = Cdata, 
               k = i)
  #print(AIC(tmp_model))
  aic[i] <- AIC(tmp_model)
  bic[i] <- BIC(tmp_model)
}

# グラフ作成
plot_data <- data.frame(class_num = c(1:I), aic, bic) %>% 
  gather(key = type, value = value, aic, bic)
gp <- ggplot(plot_data, aes(x = class_num, y = value, color = type)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks=seq(1,10,1))
gp

# BICが最小になるクラス数でモデル作成
LCLModel = flexmix(choice ~ display + feature + price + brand | id, 
                    model = FLXMRcondlogit(strata = ~ t), 
                    data = Cdata, 
                    k = which.min(bic))

summary(LCLModel)
parameters(LCLModel)
