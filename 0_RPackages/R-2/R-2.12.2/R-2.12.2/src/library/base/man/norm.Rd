% File src/library/base/man/norm.Rd
% Part of the R package, http://www.R-project.org
% Copyright 2010 R Core Development Team
% Copyright 2010 The R Foundation
% Distributed under GPL 2 or later
%
\name{norm}
\alias{norm}
\title{Compute the Norm of a Matrix}
\description{
  Computes a matrix norm of \code{x} using Lapack.  The norm can be
  the one norm, the infinity norm, the Frobenius norm, or the maximum
  modulus among elements of a matrix, as determined by the value of
  \code{type}.
}
\usage{
norm(x, type = c("O", "I", "F", "M"))
}
\arguments{
  \item{x}{numeric matrix; note that packages such as \pkg{Matrix}
    define more \code{norm()} methods.}
  \item{type}{character string, specifying the \emph{type} of matrix
    norm to be computed.
    A character indicating the type of norm desired.
    \describe{
      \item{\code{"O"}, \code{"o"} or \code{"1"}}{specifies the \bold{o}ne norm,
	(maximum absolute column sum);}
      \item{\code{"I"} or \code{"i"}}{specifies the \bold{i}nfinity norm (maximum
	absolute row sum);}
      \item{\code{"F"} or \code{"f"}}{specifies the \bold{F}robenius norm (the
	Euclidean norm of \code{x} treated as if it were a vector); and}
      \item{\code{"M"} or \code{"m"}}{specifies the \bold{m}aximum modulus of
	all the elements in \code{x}.}
    }
    The default is \code{"O"}.  Only the first character of
    \code{type[1]} is used.}
}
\details{
  The \pkg{base} method of \code{norm()} calls the Lapack function
  \code{dlange}.

  Note that the 1-, Inf- and \code{"M"} norm is faster to calculate than
  the Frobenius one.
}
\value{
  The matrix norm, a non-negative number.
}
\references{
  Anderson, E., et al. (1994).
  \emph{LAPACK User's Guide,}
  2nd edition, SIAM, Philadelphia.
}
\seealso{
  \code{\link{rcond}} for the (reciprocal) condition number.
}
\examples{
(x1 <- cbind(1,1:10))
norm(x1)
norm(x1, "I")
norm(x1, "M")
stopifnot(all.equal(norm(x1, "F"),
                    sqrt(sum(x1^2))))

hilbert <- function(n) { i <- 1:n; 1 / outer(i - 1, i, "+") }
h9 <- hilbert(9)
## all 4 types of norm:
(nTyp <- eval(formals(base::norm)$type))
sapply(nTyp, norm, x=h9)
}
\keyword{math}
