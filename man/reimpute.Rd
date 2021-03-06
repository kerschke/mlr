% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Impute.R
\name{reimpute}
\alias{reimpute}
\title{Re-impute a data set}
\usage{
reimpute(x, desc)
}
\arguments{
\item{x}{[\code{data.frame}]\cr
Object to reimpute. Currently only data frames are supported.}

\item{desc}{[\code{ImputationDesc}]\cr
Imputation description as returned by \code{\link{impute}}.}
}
\value{
Imputated \code{x}.
}
\description{
This function accepts a data frame and a imputation description
as returned by \code{\link{impute}} to perform the following actions:
\enumerate{
  \item Restore dropped columns, setting them to \code{NA}
  \item Add dummy variables for columns as specified in \code{impute}
  \item Optionally check factors for new levels to treat them as \code{NA}s
  \item Reorder factor levels to ensure identical integer representation as
    before
  \item Impute missing values using previously collected data
}
}
\seealso{
Other impute: \code{\link{imputations}},
  \code{\link{impute}}, \code{\link{makeImputeMethod}},
  \code{\link{makeImputeWrapper}}
}

