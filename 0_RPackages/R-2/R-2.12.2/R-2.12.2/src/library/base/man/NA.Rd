% File src/library/base/man/NA.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{NA}
\alias{NA}
\alias{NA_integer_}
\alias{NA_real_}
\alias{NA_complex_}
\alias{NA_character_}
\alias{is.na}
\alias{is.na.data.frame}
\alias{is.na<-}
\alias{is.na<-.default}
\title{Not Available / ``Missing'' Values}
\description{
  \code{NA} is a logical constant of length 1 which contains a missing
  value indicator.  \code{NA} can be freely coerced to any other vector
  type except raw.  There are also constants \code{NA_integer_},
  \code{NA_real_}, \code{NA_complex_} and \code{NA_character_} of the
  other atomic vector types which support missing values: all of these
  are \link{reserved} words in the \R language.

  The generic function \code{is.na} indicates which elements are missing.

  The generic function \code{is.na<-} sets elements to \code{NA}.
}
\usage{
NA
is.na(x)
\method{is.na}{data.frame}(x)

is.na(x) <- value
}
\arguments{
  \item{x}{an \R object to be tested: the default method handles atomic
    vectors, lists and pairlists.}
  \item{value}{a suitable index vector for use with \code{x}.}
}
%% Next par on character NAs taken from R-lang.texi:
\details{
  The \code{NA} of character type is distinct from the
  string \code{"NA"}.  Programmers who need to specify an explicit
  string \code{NA} should use \code{NA_character_} rather than
  \code{"NA"}, or set elements to \code{NA} using \code{is.na<-}.

  \code{is.na(x)} works elementwise when \code{x} is a
  \code{\link{list}}.  It is generic: you can write methods to handle
  specific classes of objects, see \link{InternalMethods}.  A complex
  value is regarded as \code{NA} if either its real or imaginary part is
  \code{NA} or \code{NaN}.

  Function \code{is.na<-} may provide a safer way to set missingness.
  It behaves differently for factors, for example.
}
\value{
  The default method for \code{is.na} applied to an atomic vector
  returns a logical vector of the same length as its argument \code{x},
  containing \code{TRUE} for those elements marked \code{NA} or, for
  numeric or complex vectors, \code{\link{NaN}} (!) and \code{FALSE}
  otherwise.  \code{dim}, \code{dimnames} and \code{names} attributes
  are preserved.

  The default method also works for lists and pairlists: the result for an
  element is false unless that element is a length-one atomic vector and
  the single element of that vector is regarded as \code{NA} or \code{NaN}.

  The method \code{is.na.data.frame} returns a logical matrix with the
  same dimensions as the data frame, and with dimnames taken from the
  row and column names of the data frame.
}
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.

  Chambers, J. M. (1998)
  \emph{Programming with Data. A Guide to the S Language}.
  Springer.
}
\seealso{
  \code{\link{NaN}}, \code{\link{is.nan}}, etc.,
  and the utility function \code{\link{complete.cases}}.

  \code{\link{na.action}}, \code{\link{na.omit}}, \code{\link{na.fail}}
  on how methods can be tuned to deal with missing values.
}
\examples{
is.na(c(1, NA))        #> FALSE  TRUE
is.na(paste(c(1, NA))) #> FALSE FALSE

(xx <- c(0:4))
is.na(xx) <- c(2, 4)
xx                     #> 0 NA  2 NA  4
}
\keyword{NA}
\keyword{logic}
\keyword{manip}
