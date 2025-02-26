% File src/library/base/man/gc.time.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2011 R Core Development Team
% Distributed under GPL 2 or later

\name{gc.time}
\alias{gc.time}
\title{Report Time Spent in Garbage Collection}
\description{
  This function reports the time spent in garbage collection so far in
  the \R session while GC timing was enabled.
}
\usage{
gc.time(on = TRUE)
}
\arguments{
  \item{on}{logical; if \code{TRUE}, GC timing is enabled.}
}
\value{
  A numerical vector of length 5 giving the user CPU time, the system
  CPU time, the elapsed time and children's user and system CPU times
  (normally both zero), of time spent doing garbage collection whilst
  GC timing was enabled.
  
  Times of child processes are not available on Windows and will always
  be given as \code{NA}.
}
\details{
  The timings are rounded up by the sampling interval for timing
  processes, and so are likely to be over-estimates.
  
  It is a \link{primitive}.
}
\seealso{\code{\link{gc}},
  \code{\link{proc.time}} for the timings for the session.}

\examples{
gc.time()
}
\keyword{utilities}
