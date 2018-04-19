## ----setup, echo = FALSE, warning=FALSE, message=FALSE-------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(dplyr)
library(ggplot2)
library(productplots)
theme_set(theme_bw()) # set theme to my personal preference
PlotXTabs <- function(dataframe, xwhich, ywhich, plottype = "side"){
  if (length(match.call()) <= 3) {
    stop("Not enough arguments passed... requires a dataframe, plus at least two variables")
  }
  argList <-  as.list(match.call()[-1])
  if (!exists(deparse(substitute(dataframe)))) {
    stop("The first object in your list does not exist. It should be a dataframe")
  }
  if (!is(dataframe, "data.frame")) {
    stop("The first name you passed does not appear to be a data frame")
  }
# process plottype logic -- default is side anything mispelled or not listed is also side
  switch(plottype,
         side =  list(geom_bar(position="dodge", stat="identity"),
                      ylab("Count")) -> whichbar,
         stack = list(geom_bar(stat="identity"),
                      ylab("Count")) -> whichbar,
         percent = list(geom_bar(stat="identity", position="fill"),
                        ylab("Percent")) -> whichbar,
         list(geom_bar(position="dodge", stat="identity"),
              ylab("Count")) -> whichbar
  )

  PlotMagic <-  function(dataframe,aaa,bbb,whichbar,dfname,xname,yname) {
     dataframe %>%
        filter(!is.na(!! aaa), !is.na(!! bbb))  %>%
        mutate(!!quo_name(aaa) := factor(!!aaa), !!quo_name(bbb) := factor(!!bbb)) %>%
        group_by(!! aaa,!! bbb) %>%
        count() -> tempdf
     tempdf %>%
        ggplot(aes_(fill=aaa, y=~n, x=bbb)) +
        whichbar +
        ggtitle(bquote("Crosstabs dataset = "*.(dfname)*" and variables = "*.(xname)~"by "*.(yname))) -> p
     print(p)
  }

# If both are bare variables and found in the dataframe immediately print the plot
  if (deparse(substitute(xwhich)) %in% names(dataframe) & deparse(substitute(ywhich)) %in% names(dataframe)) { # both are names in the dataframe
    aaa <- enquo(xwhich)
    bbb <- enquo(ywhich)
    xname <- deparse(substitute(xwhich))
    yname <- deparse(substitute(ywhich))
    dfname <- deparse(substitute(dataframe))
    PlotMagic(dataframe,aaa,bbb,whichbar,dfname,xname,yname)
    return(message(paste("Plotted dataset", argList$dataframe, "variables", argList$xwhich, "by", argList$ywhich)))
  } else { # is at least one in the dataframe?
# Is at least one of them a bare variable in the dataframe
    if (deparse(substitute(xwhich)) %in% names(dataframe)) { # xwhich is in the dataframe
      aaa <- enquo(xwhich)
      if (class(try(eval(ywhich))) %in% c("integer","numeric")) { # ywhich is column numbers
        indvars <- vector("list", length = length(ywhich))
        totalcombos <- 1 # keep track of where we are
        xname <- deparse(substitute(xwhich))
        dfname <- deparse(substitute(dataframe))
        message("Creating the variable pairings from dataframe ", dfname)
        for (k in seq_along(ywhich)) { #for loop
          indvarsbare <- as.name(colnames(dataframe[ywhich[[k]]]))
          cat("Plot #", totalcombos, " ", xname,
              " with ", as.name(colnames(dataframe[ywhich[[k]]])), "\n", sep = "")
          bbb <- enquo(indvarsbare)
          yname <- deparse(substitute(indvarsbare))
          PlotMagic(dataframe,aaa,bbb,whichbar,dfname,xname,yname)
          totalcombos <- totalcombos +1
        } # end of for loop
          return(message("Plotting complete"))
        } else { # ywhich is NOT suitable
        stop("Sorry I don't understand your ywhich variable(s)")
        } #

      } else { # xwhich wasn't try ywhich
        if (deparse(substitute(ywhich)) %in% names(dataframe)) { # yes ywhich is
          bbb <- enquo(ywhich)
          if (class(try(eval(xwhich))) %in% c("integer","numeric")) { # then xwhich a suitable number
            # Build one list two ways
            depvars <- vector("list", length = length(xwhich))
            totalcombos <- 1 # keep track of where we are
            yname <- deparse(substitute(ywhich))
            dfname <- deparse(substitute(dataframe))
            message("Creating the variable pairings from dataframe ", dfname)
            for (j in seq_along(xwhich)) {
              depvarsbare <- as.name(colnames(dataframe[xwhich[[j]]]))
              cat("Plot #", totalcombos, " ", as.name(colnames(dataframe[xwhich[[j]]])),
                  " with ", yname, "\n", sep = "")
              aaa <- enquo(depvarsbare)
              xname <- deparse(substitute(depvarsbare))
              PlotMagic(dataframe,aaa,bbb,whichbar,dfname,xname,yname)
              totalcombos <- totalcombos +1
            } #end of for loop
              return(message("Plotting complete"))
          } else { # xwhich is NOT suitable
            stop("Sorry I don't understand your xwhich variable(s)")
          } #end of else because xwhich not suitable
        } #end of if
     }
  }

# If both variables are numeric print the plot(s)
  if (class(try(eval(xwhich))) %in% c("integer","numeric") & class(try(eval(ywhich))) %in% c("integer","numeric")) {
     indvars <- vector("list", length = length(ywhich))
     depvars <- vector("list", length = length(xwhich))
     dfname <- deparse(substitute(dataframe))
     totalcombos <- 1 # keep track of where we are
     message("Creating the variable pairings from dataframe ", dfname)
     for (j in seq_along(xwhich)) {
        for (k in seq_along(ywhich)) {
           depvarsbare <- as.name(colnames(dataframe[xwhich[[j]]]))
           indvarsbare <- as.name(colnames(dataframe[ywhich[[k]]]))
           cat("Plot #", totalcombos, " ", as.name(colnames(dataframe[xwhich[[j]]])),
               " with ", as.name(colnames(dataframe[ywhich[[k]]])), "\n", sep = "")
           aaa <- enquo(depvarsbare)
           bbb <- enquo(indvarsbare)
           xname <- deparse(substitute(depvarsbare))
           yname <- deparse(substitute(indvarsbare))
                      PlotMagic(dataframe,aaa,bbb,whichbar,dfname,xname,yname)
           totalcombos <- totalcombos +1
        } # end of inner for loop
     }  # end of outer for loop
        return(message("Plotting complete"))
  } # end of if case where all are numeric
} # end of function

## ----vignette1, fig.width=6.0, fig.height=2------------------------------
# who's happier by gender
PlotXTabs(happy,happy,sex)
# same thing using column numbers and a stacked bar
PlotXTabs(happy,2,5,"stack")
# happiness by a variety of possible factors as a percent
PlotXTabs(happy, 2, c(5:9), plottype = "percent")
# turn the numbers around and change them up basically just showing all
# the permutations
PlotXTabs(happy, c(2,5), 9, plottype = "side")
PlotXTabs(happy, c(2,5), c(6:9), plottype = "percent")
PlotXTabs(happy, happy, c(6,7,9), plottype = "percent")
PlotXTabs(happy, c(6,7,9), happy, plottype = "percent")
