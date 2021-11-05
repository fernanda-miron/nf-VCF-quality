## This script takes a preprocesed VCF file and
## analyse the VCF quality

## Uploading libraries
library("plyr")
library("dplyr")
library("ggplot2")
library("cowplot")
library("scales")

## Read args from command line
args <- commandArgs(trailingOnly = T)

# Uncomment for debbuging
# Comment for production mode only
#args[1] <- "."
#args[2] <- "./SNP.png"
#args[3] <- "./ID.png"
#args[4] <- "./ID.tsv"
#args[5] <- "./input.4"
#args[6] <- "./input.5"
#args[7] <- "./SNP.tsv"

## Place args into named object
dfpath <- args[1]
snp_file <- args[2]
ID_file <- args[3]
tsv_file <- args[4]
snp_cut <- args[5]
id_cut <- args[6]
SNP_file <- args[7]

## Transforming Parameters
## Getting parameters
snp <- read.table(file = snp_cut)
numeric_snp <- as.numeric(snp[1,1])

id <- read.table(file = id_cut)
numeric_id <- as.numeric(id[1,1])

## Getting regular expression
df1 <- list.files(path = dfpath, pattern = "*.df1", full.names = T)
df2 <- list.files(path = dfpath, pattern = "*.df2", full.names = T)

## Quality by AN: total of number of alleles in called genotypes
df1 <- read.table(file = df1,
                  header = F,
                  sep = "\t", 
                  stringsAsFactors = F)

## Changing colnames df1
colnames(df1) <- c("AN", "SNP", "ID")

## Dividing AN to work with total individuals
addedc.df <- df1 %>% 
  mutate(Total_individuals = SNP/2) 

## Calculating missingness percentage
addedc.df <- addedc.df %>% 
  mutate(missingness = (100 - (Total_individuals*100)/max(addedc.df$Total_individuals)))

## Geom density
dplot1 <- ggplot( data = addedc.df,
                  mapping = aes( x = missingness) ) +     
  geom_histogram(color="#A7D49B",fill = "#A7D49B") +
  scale_x_continuous(breaks = seq(0,100,5))+
  theme_bw(base_size = 12)
dplot1

## Geom density
dplot2 <- dplot1 +
  theme(text = element_text(size=10, margin = margin(10, 0, 10, 0)),
        plot.title = element_text(size=15),
        axis.title.x = element_text(size = 13, vjust = 0.2),
        axis.title.y = element_text(size = 13, vjust = 3),
        panel.border = element_blank(),
        axis.line.y.left   = element_line(color = 'black'),
        axis.line.x.bottom = element_line(color = 'black'),
        axis.text.x = element_text(size = 10),
        axis.text.y = element_text(size = 10),
        plot.margin = margin(r = 0.5,l = 0.5, b = 0.5, t= 0.5, unit = "cm")) + 
  labs(title = "Frequency of SNP´s with missingness",
       y = "Number of SNP's",
       x = "Percentage of missingness")
dplot2

## Saving plot
ggsave(filename = snp_file, plot = dplot2,
       height = 8, width = 18, units = "in", dpi = 300)

## Filtrating by PARAMETER
filter_file <- addedc.df %>% 
  filter(missingness > numeric_snp) %>% 
  select("ID")

## Saving file 
write.table(filter_file, SNP_file, sep='\t', 
            col.names = FALSE, quote=FALSE, row.names = F)

## Quality by missing data in genotype info (.|.)
## Quality by SNP: reading df2
df2 <- read.table(file = df2, 
                  header = T, 
                  sep = "\t", 
                  stringsAsFactors = F)

## Selecting ID columns
selected.df <- df2 %>% select(10:ncol(df2))

## Counting missing data (.|.) per column

count.chosens.per.column <- ldply(selected.df, function(c) sum(c==".|."))

## Changing column names
colnames(count.chosens.per.column) <- c("Sample_ID", "Missing_data")

## Calculate % of missingness
arranged.df <- count.chosens.per.column %>% 
  mutate(missingness = (Missing_data * 100)/nrow(df2))

## Plotting a lollipop plot
lolliplot_1 <- ggplot(data = arranged.df, aes(x = Sample_ID, y = missingness)) +
  geom_segment(color="grey", aes(x=Sample_ID, xend=Sample_ID, y=0, yend=missingness)) +
  geom_point(color = "orange") +
  scale_y_continuous(limits = c(0,(max(arranged.df$missingness + 5))),expand = c(0, 0),
                     labels = function(x) paste0(x, "%")) +
  theme_bw(base_size = 12) +
  theme(panel.grid.major.y = element_blank())
lolliplot_1

## Changing axis
lolliplot_2 <- lolliplot_1 +
  theme(text = element_text(size=10),
        plot.title = element_text(size=14, margin = margin(10, 0, 10, 0)),
        axis.text.x = element_text(angle=90, size = 5.5, vjust = 0.4), ##checa si puede mejorar posición
        axis.text.y = element_text(size = 10),
        axis.title.x = element_text(size = 10, vjust = 0.2),
        axis.title.y = element_text(size = 10, vjust = 3),
        panel.grid = element_blank(),
        panel.border = element_blank(),
        axis.line.y.left   = element_line(color = 'black'),
        axis.line.x.bottom = element_line(color = 'black'),
        axis.ticks.x = element_blank(),
        plot.margin = margin(r = 0.5,l = 1, unit = "cm")) +
  labs(title = "Missing data per sample",
       y = "Percentage of missingness",
       x = "Sample ID")
lolliplot_2

## Saving plot
ggsave(filename = ID_file, plot = lolliplot_2,
       height = 10, width = 20, units = "in", dpi = 300)

## Saving tsv for ID
## Filtrating
filter_file.p <- arranged.df %>% 
  filter(missingness < numeric_id) %>% 
  select(Sample_ID)

## Saving table
write.table(filter_file.p, file=tsv_file, sep='\t', 
            col.names = FALSE, quote=FALSE, row.names = F)


