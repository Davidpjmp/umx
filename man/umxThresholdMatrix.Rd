% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build_run_modify.R
\name{umxThresholdMatrix}
\alias{umxThresholdMatrix}
\title{Create the threshold matrix needed for modeling ordinal data.}
\usage{
umxThresholdMatrix(
  df,
  selDVs = NULL,
  sep = NULL,
  method = c("Mehta", "allFree"),
  threshMatName = "threshMat",
  l_u_bound = c(NA, NA),
  droplevels = FALSE,
  verbose = FALSE
)
}
\arguments{
\item{df}{The data being modeled (to allow access to the factor levels and quantiles within these for each variable)}

\item{selDVs}{The variable names. Note for twin data, just the base names, which sep will be used to fill out.}

\item{sep}{(e.g. "_T") Required for wide (twin) data. It is used to break the base names our from their numeric suffixes.}

\item{method}{How to implement the thresholds: Mehta, (1 free thresh for binary, first two fixed for ordinal) or "allFree"}

\item{threshMatName}{name of the matrix which is returned. Defaults to "threshMat" - best not to change it.}

\item{l_u_bound}{c(NA, NA) by default, you can use this to bound the first (base) threshold.}

\item{droplevels}{Whether to drop levels with no observed data (defaults to FALSE)}

\item{verbose}{How much to say about what was done. (defaults to FALSE)}
}
\value{
\itemize{
\item list of thresholds matrix, deviations, lowerOnes
}
}
\description{
High-level helper for ordinal modeling. Creates, labels, and sets smart-starts for this complex matrix. Big time saver!
}
\details{
We often need to model ordinal data: sex, low-med-hi, depressed/normal, etc.,
A useful conceptual strategy to handle these data is to build a standard model for normally-varying data
and then to threshold this normal distribution to generate the observed data. Thus an observation of "depressed"
is modeled as a high score on the latent normally distributed trait, with thresholds set so that only scores above
this threshold (1-minus the number of categories) reach the criteria for the diagnosis.

Making this work can require fixing the first 2 thresholds of ordinal data, or fixing both the mean and variance of
a latent variable driving binary data, in order to estimate its one-free parameter: where to place the single threshold
separating low from high cases.

The function returns a 3-item list consisting of:
\enumerate{
\item A thresholdsAlgebra (named \code{threshMatName})
\item A matrix of deviations for the thresholds (\code{deviations_for_thresh})
\item A lower matrix of ones (\code{lowerOnes_for_thresh})
}

\emph{Twin Data}

With twin data, make sure to provide the \strong{full names} for twin data... this is not standard I know...

For twins (the function currently handles only pairs), the thresholds are equated for both twins using labels:

$labels\preformatted{  obese_T1         obese_T2
}

dev_1 "obese_dev1"   "obese_dev1"
}
\examples{

# ============================
# = Simple non-twin examples =
# ============================

# data: 1 2-level ordered factor
x = data.frame(ordered(rbinom(100,1,.5))); names(x) = c("x")

tmp = umxThresholdMatrix(x, selDVs = "x")
# The lower ones matrix (all fixed)
tmp[[1]]$values
tmp[[1]]$free

# The deviations matrix
tmp[[2]]$values
tmp[[2]]$labels # note: for twins, labels will be equated across twins

# The algebra that adds the deviations to create thresholds:
tmp[[3]]$formula

# Example of a warning to not omit the variable names
# tmp = umxThresholdMatrix(x)
# Just a polite message, but for coding safety, I recommend calling
# umxThresholdMatrix with the names of the variables in the model.
#   Next time, please include selDVs (AND you MUST include sep if this is a twin model!!)

# One ordered factor with 5-levels
x = cut(rnorm(100), breaks = c(-Inf,.2,.5, .7, Inf)); levels(x) = 1:5
x = data.frame(ordered(x)); names(x) <- c("x")
tmp = umxThresholdMatrix(x, selDVs = "x")
tmp[[2]]$name
tmp[[2]]$free # last one is free.. (method = Mehta)

tmp = umxThresholdMatrix(x, selDVs = "x", l_u_bound= c(-1,1))
tmp[[2]]$lbound # bounds applied to base threshold

# =================================
# = Binary example with twin data =
# =================================
# ===============================================================
# = Create a series of binary and ordinal columns to work with =
# ===============================================================
data(twinData)

# Make "obese" variable with ~20\% subjects categorised as obese
obesityLevels   = c('normal', 'obese')
cutPoints       = quantile(twinData[, "bmi1"], probs = .2, na.rm = TRUE)
twinData$obese1 = cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData$obese2 = cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
# Step 2: Make the ordinal variables into umxFactors (ordered, with the levels found in the data)
selVars = c("obese1", "obese2")
twinData[, selVars] = umxFactor(twinData[, selVars])

# Example 1
# use verbose = TRUE to see informative messages
tmp = umxThresholdMatrix(twinData, selDVs = selVars, sep = "", verbose = TRUE) 


# ======================================
# = Ordinal (n categories > 2) example =
# ======================================
# Repeat for three-level weight variable
obesityLevels = c('normal', 'overweight', 'obese')
cutPoints = quantile(twinData[, "bmi1"], probs = c(.4, .7), na.rm = TRUE)
twinData$obeseTri1 = cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData$obeseTri2 = cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
selDVs = "obeseTri"; selVars = tvars(selDVs, sep = "", suffixes = 1:2)
twinData[, selVars] = umxFactor(twinData[, selVars])
tmp = umxThresholdMatrix(twinData, selDVs = selVars, sep = "", verbose = TRUE)


# ========================================================
# = Mix of all three kinds example (and a 4-level trait) =
# ========================================================
obesityLevels = c('underWeight', 'normal', 'overweight', 'obese')
cutPoints = quantile(twinData[, "bmi1"], probs = c(.25, .4, .7), na.rm = TRUE)
twinData$obeseQuad1 = cut(twinData$bmi1, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
twinData$obeseQuad2 = cut(twinData$bmi2, breaks = c(-Inf, cutPoints, Inf), labels = obesityLevels) 
selVars = c("obeseQuad1", "obeseQuad2")
twinData[, selVars] = mxFactor(twinData[, selVars], levels = obesityLevels)

selDVs =c("bmi", "obese", "obeseTri", "obeseQuad")
tmp = umxThresholdMatrix(twinData, selDVs = tvars(selDVs, sep= ""), sep = "", verbose = TRUE)
# The lower ones matrix (all fixed)
tmp[[1]]$values
# The deviations matrix
tmp[[2]]$values
tmp[[2]]$labels # note labels are equated across twins
# Check to be sure twin-1 column labels same as twin-2
tmp[[2]]$labels[,2]==tmp[[2]]$labels[,4]

# The algebra that assembles these into thresholds:
tmp[[3]]$formula
# =================================
# = Example with method = allFree =
# =================================

tmp = umxThresholdMatrix(twinData, selDVs = tvars(selDVs, sep= ""), sep = "", method = "allFree")
all(tmp[[2]]$free)

}
\references{
\itemize{
\item \url{https://tbates.github.io},  \url{https://github.com/tbates/umx}
}
}
\seealso{
Other Advanced Model Building Functions: 
\code{\link{umxJiggle}()},
\code{\link{umx}},
\code{\link{xmuLabel}()},
\code{\link{xmuValues}()}
}
\concept{Advanced Model Building Functions}
