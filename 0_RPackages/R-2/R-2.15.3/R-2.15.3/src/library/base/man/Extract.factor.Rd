% File src/library/base/man/Extract.factor.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Team
% Distributed under GPL 2 or later

\name{Extract.factor}
\title{Extract or Replace Parts of a Factor}
\alias{[.factor}
\alias{[<-.factor}
\alias{[[.factor}
\alias{[[<-.factor}
\description{
  Extract or replace subsets of factors.
}
\usage{
\method{[}{factor}(x, \dots, drop = FALSE)
\method{[[}{factor}(x, \dots)
\method{[}{factor}(x, \dots) <- value
\method{[[}{factor}(x, \dots) <- value
}
\arguments{
  \item{x}{a factor}
  \item{\dots}{a specification of indices -- see \code{\link{Extract}}.}
  \item{drop}{logical.  If true, unused levels are dropped.}
  \item{value}{character: a set of levels.  Factor values are coerced to
    character.}
}
\value{
  A factor with the same set of levels as \code{x} unless \code{drop = TRUE}.
}
\details{
  When unused levels are dropped the ordering of the remaining levels is
  preserved.
  
  If \code{value} is not in \code{levels(x)}, a missing value is
  assigned with a warning.
  
  Any \code{\link{contrasts}} assigned to the factor are preserved
  unless \code{drop = TRUE}.

  The \code{[[} method supports argument \code{exact}.
}
\seealso{
  \code{\link{factor}}, \code{\link{Extract}}.
}
\examples{
## following example(factor)
(ff <- factor(substring("statistics", 1:10, 1:10), levels = letters))
ff[, drop = TRUE]
factor(letters[7:10])[2:3, drop = TRUE]
}
\keyword{category}
