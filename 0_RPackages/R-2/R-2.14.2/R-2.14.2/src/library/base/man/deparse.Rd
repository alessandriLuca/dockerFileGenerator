% File src/library/base/man/deparse.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{deparse}
\alias{deparse}
\title{Expression Deparsing}
\description{
  Turn unevaluated expressions into character strings.
}
\usage{
deparse(expr, width.cutoff = 60L,
        backtick = mode(expr) \%in\%
            c("call", "expression", "(", "function"),
        control = c("keepInteger", "showAttributes", "keepNA"),
        nlines = -1L)
}
\arguments{
  \item{expr}{any \R expression.}
  \item{width.cutoff}{integer in \eqn{[20, 500]} determining the cutoff
    (in bytes) at which line-breaking is tried.}
  \item{backtick}{logical indicating whether symbolic names should be
    enclosed in backticks if they do not follow the standard syntax.}
  \item{control}{character vector of deparsing options.  See
    \code{\link{.deparseOpts}}.}
  \item{nlines}{integer: the maximum number of lines to produce.
    Negative values indicate no limit.}
}
\details{
  This function turns unevaluated expressions (where \sQuote{expression}
  is taken in a wider sense than the strict concept of a vector of mode
  \code{"expression"} used in \code{\link{expression}}) into character
  strings (a kind of inverse to \code{\link{parse}}).

  A typical use of this is to create informative labels for data sets
  and plots.  The example shows a simple use of this facility.  It uses
  the functions \code{deparse} and \code{substitute} to create labels
  for a plot which are character string versions of the actual arguments
  to the function \code{myplot}.

  The default for the \code{backtick} option is not to quote single
  symbols but only composite expressions.  This is a compromise to
  avoid breaking existing code.

  Using \code{control = "all"} comes closest to making \code{deparse()}
  an inverse of \code{parse()}.  However, not all objects are
  deparse-able even with this option and a warning will be issued if the
  function recognizes that it is being asked to do the impossible.

  Numeric and complex vectors are converted using 15 significant digits:
  see \code{\link{as.character}} for more details.

  \code{width.cutoff} is a lower bound for the line lengths: deparsing a
  line proceeds until at least \code{width.cutoff} \emph{bytes} have
  been output and e.g. \code{arg = value} expressions will not be split
  across lines.
}
\note{
  To avoid the risk of a source attribute out of sync with the actual
  function definition, the source attribute of a function will never 
  be deparsed as an attribute.
}   
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.
}
\seealso{
  \code{\link{substitute}},
  \code{\link{parse}},
  \code{\link{expression}}.

  \code{Quotes} for quoting conventions, including backticks.
}
\examples{
require(stats); require(graphics)

deparse(args(lm))
deparse(args(lm), width = 500)
myplot <-
function(x, y) {
    plot(x, y, xlab=deparse(substitute(x)),
        ylab=deparse(substitute(y)))
}
e <- quote(`foo bar`)
deparse(e)
deparse(e, backtick=TRUE)
e <- quote(`foo bar`+1)
deparse(e)
deparse(e, control = "all")
}
\keyword{programming}
\keyword{manip}
\keyword{data}
