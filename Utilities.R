
prep=function(Data){
  
  require(psych)  
  
  # Remove practice trials and unused left button recording 
  Data <- Data[-c(1:16),]
  Data <- Data[,-c(6)]
  names(Data) = c("trial", "Foreperiod", "RTsec", "vis", "aud", "RF")
  ntrials=nrow(Data)
  
  
  #Remove outliers
  Data <- Data[ which(Data$RTsec<1.000), ]  #Misses
  Out<-100*(ntrials-nrow(Data))/ntrials
  print(paste0("% misses: ", Out))
  ntrials <- nrow(Data)
  
  
  Data <- Data[ which(Data$RTsec>0.100 ), ]  #Anticipations
  Out<-100*(ntrials-nrow(Data))/ntrials
  print(paste0("% anticipations: ", Out))
  ntrials <- nrow(Data)
  

  #Transform RT data from seconds to milliseconds for interpretability
  Data$RT <- Data[,"RTsec"]*1000

  
  # Create factors
  Data$vis_levels <- as.factor(Data$vis)
  Data$aud_levels <- as.factor(Data$aud)
  levels(Data$vis_levels) <- c('Null', 'low', 'high')
  levels(Data$aud_levels) <- c('Null', 'low', 'high')
  

  #Standardize the data
  Data$ZRT<- with(Data, (RT-mean(RT))/sd(RT))
  Data$ZRF<- with(Data, (RF-mean(RF))/sd(RF))

  
  # Invert RT in seconds to represent speed
  Data$speed <-  1/Data$RTsec

  
  # compute power
  Data$Pow <-  with(Data, RF*speed)

  
  # some descriptives
  with(Data, describeBy(x=RT, list(vis_levels,aud_levels) ) )
  with(Data, describeBy(x=RF, list(vis_levels,aud_levels) ) )
  with(Data, describeBy(x=speed, list(vis_levels,aud_levels) ) )
  with(Data, describeBy(x=Pow, list(vis_levels,aud_levels) ) )
  
  
  detach("package:psych", unload=TRUE)
  
  
  return(Data)
}


prep_unimodal=function(Data){
  
  #subset the data the analysis
  uni_vis <- subset(Data, aud_levels=="Null")
  uni_aud <- subset(Data, vis_levels=="Null") 
  bimodal <- subset(Data, vis_levels!="Null" & aud_levels!="Null" )
  
  uni_vis$modality=factor(c("vis"))
  colnames(uni_vis)[8] <- "intensity"
  uni_vis$aud_levels <- NULL
  
  uni_aud$modality=factor(c("aud"))
  colnames(uni_aud)[9] <- "intensity"
  uni_aud$vis_levels <- NULL
  
  
  Unimodal <- rbind(uni_vis,uni_aud)
  Unimodal <- droplevels(Unimodal)
  
  Unimodal$int_N <-as.numeric(Unimodal$intensity) - 1 # 0-low, 1-High
  Unimodal$mod_N <-as.numeric(Unimodal$modality) - 1  # 0-visual, 1-auditory
  
  
  return(Unimodal)
}

prep_bimodal=function(Data){
  
  #subset the data the analysis
  uni_vis <- subset(Data, aud_levels=="Null")
  uni_aud <- subset(Data, vis_levels=="Null") 
  bimodal <- subset(Data, vis_levels!="Null" & aud_levels!="Null" )
  
  bimodal <- droplevels(bimodal)
  
  
  bimodal$vis_N <-as.numeric(bimodal$vis_levels) - 1 #0 low, 1 High
  bimodal$aud_N <-as.numeric(bimodal$aud_levels) - 1 #0 low, 1 High
  
  
  return(bimodal)
}


BF_anal = function(d_uni, d_bi, DV) { 
  
  require(BayesFactor)
  
  #### Unimodal ########
  
  print("Unimodal")
  
  if(DV=="RT"){
      lm_modUni <- lm(formula = RT ~ modality + intensity + modality:intensity, data = d_uni)
      print(summary(lm_modUni))
  
      full_Uni <- lmBF(RT ~ modality + intensity + modality:intensity, data = d_uni)
      noInteraction_Uni <- lmBF(RT ~ modality + intensity, data = d_uni)
      onlymodality_Uni <- lmBF(RT ~ modality, data = d_uni)
      onlyintensity_Uni <- lmBF(RT ~ intensity, data = d_uni)
  } else if (DV=="RF") {
      lm_modUni <- lm(formula = RF ~ modality + intensity + modality:intensity, data = d_uni)
      print(summary(lm_modUni))
    
      full_Uni <- lmBF(RF ~ modality  + intensity + modality:intensity, data = d_uni)
      noInteraction_Uni <- lmBF(RF ~ modality + intensity, data = d_uni)
      onlymodality_Uni <- lmBF(RF ~ modality , data = d_uni)
      onlyintensity_Uni <- lmBF(RF ~ intensity, data = d_uni)  
  } else if (DV=="Pow") {
    lm_modUni <- lm(formula = Pow ~ modality + intensity + modality:intensity, data = d_uni)
    print(summary(lm_modUni))
    
    full_Uni <- lmBF(Pow ~ modality + intensity + modality:intensity, data = d_uni)
    noInteraction_Uni <- lmBF(Pow ~ modality  + intensity, data = d_uni)
    onlymodality_Uni <- lmBF(Pow ~ modality , data = d_uni)
    onlyintensity_Uni <- lmBF(Pow ~ intensity, data = d_uni)  
  } else {print("Error")}
  
  
  
  allBFs_Uni <- c(full_Uni, noInteraction_Uni, onlymodality_Uni, onlyintensity_Uni)
  print(allBFs_Uni)
  
  print(head( allBFs_Uni, n = 3))
  print(head( allBFs_Uni/max(allBFs_Uni), n = 3))
  
  print(allBFs_Uni[4] / allBFs_Uni[2])
  plot(allBFs_Uni)

  #### bimodal ########
  
  print("Bimodal")
  if(DV=="RT"){
    lm_modbi <- lm(formula = RT ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    print(summary(lm_modbi))
  
    full_bi <- lmBF(RT ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    noInteraction_bi <- lmBF(RT ~ aud_levels + vis_levels, data = d_bi)
    onlyaud_bi <- lmBF(RT ~ aud_levels, data = d_bi)
    onlyvis_bi <- lmBF(RT ~ vis_levels, data = d_bi)
  } else if (DV=="RF") {
    lm_modbi <- lm(formula = RF ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    print(summary(lm_modbi))
    
    full_bi <- lmBF(RF ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    noInteraction_bi <- lmBF(RF ~ aud_levels + vis_levels, data = d_bi)
    onlyaud_bi <- lmBF(RF ~ aud_levels, data = d_bi)
    onlyvis_bi <- lmBF(RF ~ vis_levels, data = d_bi)
  } else if (DV=="Pow") {
    lm_modbi <- lm(formula = Pow ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    print(summary(lm_modbi))
    
    full_bi <- lmBF(Pow ~ aud_levels + vis_levels + aud_levels:vis_levels, data = d_bi)
    noInteraction_bi <- lmBF(Pow ~ aud_levels + vis_levels, data = d_bi)
    onlyaud_bi <- lmBF(Pow ~ aud_levels, data = d_bi)
    onlyvis_bi <- lmBF(Pow ~ vis_levels, data = d_bi)
  } else {print("Error")}
  
  allBFs_bi <- c(full_bi, noInteraction_bi, onlyaud_bi, onlyvis_bi)
  print(allBFs_bi)
  
  print(head( allBFs_bi, n = 3))
  print(head( allBFs_bi/max(allBFs_bi), n = 3))
  
  print(allBFs_bi[4] / allBFs_bi[2])
  plot(allBFs_bi)
  
  detach("package:BayesFactor", unload=TRUE)
  
}


