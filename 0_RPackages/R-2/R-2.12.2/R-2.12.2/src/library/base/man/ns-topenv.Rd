% File src/library/base/man/ns-topenv.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2011 R Core Development Team
% Distributed under GPL 2 or later

\name{ns-topenv}
\title{Top Level Environment}
\alias{topenv}
\description{
  Finding the top level environment.
}
\usage{
topenv(envir = parent.frame(),
       matchThisEnv = getOption("topLevelEnvironment"))
}
\arguments{
  \item{envir}{environment.}

  \item{matchThisEnv}{return this environment, if it matches before
      any other criterion is satisfied.  The default, the option
      \samp{topLevelEnvironment}, is set by \code{\link{sys.source}},
      which treats a specific environment as the top level environment.
      Supplying the argument as \code{NULL} means it will never match.}
}
\details{
  \code{topenv} returns the first top level environment found when
  searching \code{envir} and its enclosing environments.  An environment is
  considered top level if it is the internal environment of a name space,
  a package environment in the search path, or \code{.GlobalEnv}.
}
\examples{
topenv(.GlobalEnv)
topenv(new.env())
}
\keyword{programming}
