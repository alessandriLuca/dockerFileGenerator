% File src/library/base/man/traceback.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2007 R Core Team
% Distributed under GPL 2 or later

\name{traceback}
\alias{traceback}
\alias{.Traceback}
\title{Print Call Stacks}
\description{
  By default \code{traceback()} prints the call stack of the last
  uncaught error, i.e., the sequence of calls that lead to the error.
  This is useful when an error occurs with an unidentifiable error
  message.  It can also be used to print the current stack or
  arbitrary lists of deparsed calls.  
}
\usage{
traceback(x = NULL, max.lines = getOption("deparse.max.lines"))
}
\arguments{
  \item{x}{\code{NULL} (default, meaning \code{.Traceback}), or an
    integer count of calls to skip in the current stack, or a list or
    pairlist of deparsed calls.  See the details.}    
  \item{max.lines}{The maximum number of lines to be printed
    \emph{per call}.  The default is unlimited.}
}
\details{
  The default display is of the stack of the last uncaught error as
  stored as a list of deparsed calls in \code{.Traceback}, which
  \code{traceback} prints in a user-friendly format.  The stack of
  deparsed calls always contains all function calls and all foreign
  function calls (such as \code{\link{.Call}}): if profiling is in
  progress it will include calls to some primitive functions.  (Calls
  to builtins are included, but not to specials.)
  
  Errors which are caught \emph{via} \code{\link{try}} or
  \code{\link{tryCatch}} do not generate a traceback, so what is printed
  is the call sequence for the last uncaught error, and not necessarily
  for the last error.
  
  If \code{x} is numeric, then the current stack is printed, skipping
  \code{x} entries at the top of the stack.  For example,
  \code{options(error = function() traceback(2))} will print the stack
  at the time of the error, skipping the call to \code{traceback()}
  and the error function that called it.
  
  Otherwise, \code{x} is assumed to be a list or pairlist of deparsed
  calls and will be displayed in the same way.
}
\value{
  \code{traceback()} prints the deparsed call stack deepest call
  first, and returns it invisibly.  The calls may print on more than
  one line, and the first line for each call is labelled by the frame
  number.  The number of lines printed per call can be limited via
  \code{max.lines}.
}
\section{Warning}{
  It is undocumented where \code{.Traceback} is stored nor that it is
  visible, and this is subject to change.
}
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.
}
\examples{
foo <- function(x) { print(1); bar(2) }
bar <- function(x) { x + a.variable.which.does.not.exist }
\dontrun{
foo(2) # gives a strange error
traceback()}
## 2: bar(2)
## 1: foo(2)
bar
## Ah, this is the culprit ...

## This will print the stack trace at the time of the error.
options(error = function() traceback(2))
}
\keyword{programming}
