setwd ("C:\\Users\\hs17922\\Dropbox\\Work\\Research\\Projects\\14 igm\\analysis\\survey\\data")
library("tidyverse")
library("readxl")
library("readstata13")
library(stringr)
rm(list=ls())
# load data
df<-read_delim("data_scraped//data_output_US_20200824.csv",delim="|")
# Confidence
df1<-df%>%select(Confidence,Name)%>%
  separate(Confidence,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Confidence")%>%
  mutate(Confidence=as.numeric(Confidence))
# Medianconf
df2<-df%>%select(Medianconf,Name)%>%
  separate(Medianconf,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Medianconf")%>%
  mutate(Medianconf=as.numeric(Medianconf))
# Vote
df3<-df%>%select(Votes,Name)%>%
  separate(Votes,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Vote")
# Median Vote
df4<-df%>%select(Median,Name)%>%
  separate(Median,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Median")
# Comment 
df5<-df%>%select(Comment,Name)%>%
  separate(Comment,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Comment")
# Question 
df6<-df%>%select(Questions,Name)%>%
  separate(Questions,into = paste("CONF", 1:1000, sep = "_"),sep="¦")%>%
  pivot_longer(1:1000, names_to="Question",values_to = "Qtext")

# Merge
df_m<-merge(df1,df2,by=c("Name","Question"))
df_m<-merge(df_m,df3,by=c("Name","Question"))
df_m<-merge(df_m,df4,by=c("Name","Question"))
df_m<-merge(df_m,df6,by=c("Name","Question"),all.x = TRUE)
df_m<-merge(df_m,df5,by=c("Name","Question"))%>%
  mutate(Question=as.numeric(str_remove(Question, "CONF_")))%>%
  arrange(Name,Question)%>%
  filter(!is.na(Medianconf))
# write to Stata
save.dta13(df_m,"data_scraped/cleaned_data_US.dta")
