% File src/library/base/man/switch.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{switch}
\alias{switch}
\title{Select One of a List of Alternatives}
\description{
  \code{switch} evaluates \code{EXPR} and accordingly chooses one of the
  further arguments (in \code{\dots}).
}
\usage{
switch(EXPR, \dots)
}
\arguments{
  \item{EXPR}{an expression evaluating to a number or a character
    string.}
  \item{\dots}{the list of alternatives.  If it is intended that
    \code{EXPR} has a character-string value these will be
    named, perhaps except for one alternative to be used as a
    \sQuote{default} value.}
}
\details{
  \code{switch} works in two distinct ways depending whether the first
  argument evaluates to a character string or a number.
  
  If the value of \code{EXPR} is not a character string it is coerced to
  integer.  If this is between 1 and \code{nargs()-1} then the
  corresponding element of \code{\dots} is evaluated and the result
  returned: thus if the first argument is \code{3} then the fourth
  argument is evaluated and returned.

  If \code{EXPR} evaluates to a character string then that string is
  matched (exactly)to the names of the elements in \code{\dots}.  If
  there is a match then that element is evaluated unless it is missing,
  in which case the next non-missing element is evaluated, so for
  example \code{switch("cc", a=1, cc=, cd=, d=2)} evaluates to \code{2}.
  If there is more than one match, the first matching element is used.
  In the case of no match, if there is a unnamed element of \code{\dots}
  its value is returned.  (If there is more than one such argument the
  first one will be used.)
  
  The first argument is always taken to be \code{EXPR}: if it is named
  its name must (partially) match.
  
  This is implemented as a \link{primitive} function that only evaluates
  its first argument and one other if one is selected.
}
\section{Warning}{
  Before \R 2.11.0 it was necessary to avoid partial matching: an
  alternative \code{E = foo} matched the first argument \code{EXPR}
  unless that was named.

  It is possible to write calls to \code{switch} that can be confusing
  and may not work in the same way in earlier versions of \R.  For
  compatibility (and clarity), always have \code{EXPR} as the first
  argument, naming it if partial matching is a possibility.  For the
  character-string form, have a single unnamed argument as the default
  after the named values.
}
\value{
  The value of one of the elements of \code{\dots}, or \code{NULL},
  invisibly (whenever no element is selected).

  The result has the visibility (see \code{\link{invisible}}) of the
  element evaluated.
}
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.
}
\examples{
require(stats)
centre <- function(x, type) {
  switch(type,
         mean = mean(x),
         median = median(x),
         trimmed = mean(x, trim = .1))
}
x <- rcauchy(10)
centre(x, "mean")
centre(x, "median")
centre(x, "trimmed")

ccc <- c("b","QQ","a","A","bb")
# note: cat() produces no output for NULL
for(ch in ccc)
    cat(ch,":", switch(EXPR = ch, a=1,     b=2:3), "\n")
for(ch in ccc)
    cat(ch,":", switch(EXPR = ch, a=, A=1, b=2:3, "Otherwise: last"),"\n")

## Numeric EXPR does not allow a default value to be specified
## -- it is always NULL
for(i in c(-1:3,9))  print(switch(i, 1,2,3,4))

## visibility
switch(1, invisible(pi), pi)
switch(2, invisible(pi), pi)
}
\keyword{programming}
