% File src/library/stats/man/vcov.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2007 R Core Development Team
% Distributed under GPL 2 or later

\name{vcov}
\alias{vcov}
\alias{vcov.lm}
\alias{vcov.glm}
\alias{vcov.lme}
\alias{vcov.gls}
\title{
  Calculate Variance-Covariance Matrix for a Fitted Model Object
}
\description{
  Returns the variance-covariance matrix of the main parameters of
  a fitted model object.
}
\usage{
vcov(object, \dots)
}
\arguments{
  \item{object}{
    a fitted model object.
  }
  \item{\dots}{
    additional arguments for method functions.  For the
    \code{\link{glm}} method this can be used to pass a
    \code{dispersion} parameter.
  }
}
\value{
  A matrix of the estimated covariances between the parameter estimates
  in the linear or non-linear predictor of the model.
}
\details{
  This is a generic function.
  Functions with names beginning in \code{vcov.} will be
  methods for this function.
  Classes with methods for this function include:
  \code{lm}, \code{mlm}, \code{glm}, \code{nls},
  \code{negbin}, \code{polr}, \code{rlm} (in package \pkg{MASS}),
  \code{multinom} (in package \pkg{nnet})
  \code{gls}, \code{lme} (in package \pkg{nlme},
  \code{coxph} and \code{survreg} (in package \pkg{survival}).
}
\keyword{models}
\keyword{nonlinear}
