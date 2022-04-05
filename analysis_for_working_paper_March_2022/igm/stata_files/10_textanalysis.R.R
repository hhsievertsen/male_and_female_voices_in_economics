# text analysis for IGM
# Set working directory
setwd("C:/Users/hs17922/Dropbox/Work/Research/Projects/14 igm/analysis/igm")
# Libraries
library("readstata13")
library("tidyverse")
library("tm") # create corpus
library("wordcloud") #wordcloud
library("SentimentAnalysis")
library("syuzhet") 
# Load data
df<- read.dta13("data/data_temp/analysisdata.dta")
# Clean
df<-df%>%select(i_Name, i_female,j_Comment,j_didnotanswer,
                j_uncertain,j_extreme_judgement,j_anycomment, j_Confidence)%>%
                mutate(j_Confidence=ifelse(!is.na(j_Confidence),ifelse(j_Confidence>6,1,0),NA))
df_text<-df%>%filter(j_Comment!="")
# Sentiment analysis
sent2 <- get_nrc_sentiment(df$j_Comment)
# Prepare data
dfm<-cbind(sent2,df)
# Make longer
dfm<-pivot_longer(dfm,cols=1:10,names_to = "Type",values_to = "Count")
## collapse
d_all<-group_by(dfm,Type,i_female)%>%summarise(Count=sum(Count))%>%group_by(i_female)%>%
  mutate(share=Count/sum(Count))%>%mutate(dep="All")
d_uncertain<-group_by(dfm,Type,i_female)%>%filter(j_uncertain==1)%>%summarise(Count=sum(Count))%>%group_by(i_female)%>%
  mutate(share=Count/sum(Count))%>%mutate(dep="Uncertain answer")
d_extreme<-group_by(dfm,Type,i_female)%>%filter(j_extreme_judgement==1)%>%summarise(Count=sum(Count))%>%group_by(i_female)%>%
  mutate(share=Count/sum(Count))%>%mutate(dep="Strong answer")
d_confident<-group_by(dfm,Type,i_female)%>%filter(j_Confidence==1)%>%summarise(Count=sum(Count))%>%group_by(i_female)%>%
  mutate(share=Count/sum(Count))%>%mutate(dep="Confidence>p(50)")
d_notconfident<-group_by(dfm,Type,i_female)%>%filter(j_Confidence==0)%>%summarise(Count=sum(Count))%>%group_by(i_female)%>%
  mutate(share=Count/sum(Count))%>%mutate(dep="Confidence<=p(50)")
## Stack them
dff<-rbind(d_all,d_uncertain,d_extreme,d_confident,d_notconfident)
# Create chart

ggplot(dff,aes(x=Type,y=share,fill=i_female))+
  geom_bar(stat="identity",position = position_dodge2())+
  coord_flip()+
  facet_wrap(~dep) + 
  theme_bw()+
  theme(legend.position = "top", strip.background =element_blank(),
        panel.border=element_blank())+
  labs(y="Share",x=" ",fill=" ")+
  scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9"))
  

# Wordcount
counter<-function(x){
  return(str_count(x, "\\w+"))[1]
}
test<-  sapply(Comments<-df_text$j_Comment,counter)
rownames(test)<-NULL
df_text$count<-test
# Collapse and stack
d_all<-df_text%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="All")
d_uncertain<-df_text%>%filter(j_uncertain==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Uncertain answer")
d_extreme<-df_text%>%filter(j_extreme_judgement==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Strong answer")
d_confident<-df_text%>%filter(j_Confidence==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Confidence>p(50)")
d_notconfident<-df_text%>%filter(j_Confidence==0)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Confidence<=p(50)")
## Stack them
dff<-rbind(d_all,d_uncertain,d_extreme,d_confident,d_notconfident)%>%mutate(var="Word count")




# Any comment
df_any<-df%>%mutate(count=ifelse(j_Comment!="",1,0))
# Collapse and stack
d_all<-df_any%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="All")
d_uncertain<-df_any%>%filter(j_uncertain==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Uncertain answer")
d_extreme<-df_any%>%filter(j_extreme_judgement==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Strong answer")
d_confident<-df_any%>%filter(j_Confidence==1)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Confidence>p(50)")
d_notconfident<-df_any%>%filter(j_Confidence==0)%>%group_by(i_female)%>%summarise(Words=mean(count))%>%mutate(dep="Confidence<=p(50)")
## Stack them
dffany<-rbind(d_all,d_uncertain,d_extreme,d_confident,d_notconfident)%>%mutate(var="Any Comment")

# Stack all
dfs<-rbind(dff,dffany)
# Chart
ggplot(dfs,aes(x=dep,y=Words,fill=i_female))+
  geom_bar(stat="identity",position = position_dodge2())+
  coord_flip()+
  theme_bw()+
  facet_wrap(~var,scales="free_x")+
  theme(legend.position = "top", strip.background =element_blank(),         panel.border=element_blank())+
  labs(y="       Share                                           Average number of words",x=" ",fill=" ")+
  scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9"))
