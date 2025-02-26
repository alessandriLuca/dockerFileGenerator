% File src/library/base/man/merge.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2008 R Core Development Team
% Distributed under GPL 2 or later

\name{merge}
\alias{merge}
\alias{merge.default}
\alias{merge.data.frame}
\concept{join}
\title{Merge Two Data Frames}
\description{
  Merge two data frames by common columns or row names, or do other
  versions of database \emph{join} operations.
}
\usage{
merge(x, y, \dots)

\method{merge}{default}(x, y, \dots)

\method{merge}{data.frame}(x, y, by = intersect(names(x), names(y)),
      by.x = by, by.y = by, all = FALSE, all.x = all, all.y = all,
      sort = TRUE, suffixes = c(".x",".y"),
      incomparables = NULL, \dots)
}
\arguments{
  \item{x, y}{data frames, or objects to be coerced to one.}
  \item{by, by.x, by.y}{specifications of the common columns.  See
    \sQuote{Details}.}
  \item{all}{logical; \code{all = L} is shorthand for \code{all.x = L} and
    \code{all.y = L}.}
  \item{all.x}{logical; if \code{TRUE}, then extra rows will be added to
    the output, one for each row in \code{x} that has no matching row in
    \code{y}.  These rows will have \code{NA}s in those columns that are
    usually filled with values from \code{y}.  The default is
    \code{FALSE}, so that only rows with data from both \code{x} and
    \code{y} are included in the output.}
  \item{all.y}{logical; analogous to \code{all.x} above.}
  \item{sort}{logical.  Should the results be sorted on the \code{by}
    columns?}
  \item{suffixes}{character(2) specifying the suffixes to be used for
    making non-\code{by} \code{names()} unique.}
  \item{incomparables}{values which cannot be matched.  See
    \code{\link{match}}.}
  \item{\dots}{arguments to be passed to or from methods.}
}
\details{
  By default the data frames are merged on the columns with names they
  both have, but separate specifications of the columns can be given by
  \code{by.x} and \code{by.y}.  Columns can be specified by name, number
  or by a logical vector: the name \code{"row.names"} or the number
  \code{0} specifies the row names.  The rows in the two data frames
  that match on the specified columns are extracted, and joined
  together.  If there is more than one match, all possible matches
  contribute one row each.  For the precise meaning of \sQuote{match},
  see \code{\link{match}}.

  If \code{by} or both \code{by.x} and \code{by.y} are of length 0 (a
  length zero vector or \code{NULL}), the result, \code{r}, is the
  \emph{Cartesian product} of \code{x} and \code{y}, i.e.,
  \code{dim(r) = c(nrow(x)*nrow(y), ncol(x) + ncol(y))}.

  If \code{all.x} is true, all the non matching cases of \code{x} are
  appended to the result as well, with \code{NA} filled in the
  corresponding columns of \code{y};  analogously for \code{all.y}.

  If the remaining columns in the data frames have any common names,
  these have \code{suffixes} (\code{".x"} and \code{".y"} by default)
  appended to make the names of the result unique.

  The complexity of the algorithm used is proportional to the length of
  the answer.

  % Terminology follows http://en.wikipedia.org/wiki/Join_(SQL)
  In SQL database terminology, the default value of \code{all = FALSE}
  gives a \emph{natural join}, a special case of an \emph{inner
  join}. Specifying \code{all.x = TRUE} gives a \emph{left (outer)
  join}, \code{all.y = TRUE} a \emph{right (outer) join}, and both
  (\code{all=TRUE} a \emph{(full) outer join}.  DBMSes do not match
  \code{NULL} records, equivalent to \code{incomparables = NA} in \R.
}
\value{
  A data frame.  The rows are by default lexicographically sorted on the
  common columns, but for \code{sort = FALSE} are in an unspecified order.
  The columns are the common columns followed by the
  remaining columns in \code{x} and then those in \code{y}.  If the
  matching involved row names, an extra character column called
  \code{Row.names} is added at the left, and in all cases the result has
  \sQuote{automatic} row names.
}
\seealso{
  \code{\link{data.frame}},
  \code{\link{by}},
  \code{\link{cbind}}
}

\examples{
## use character columns of names to get sensible sort order
authors <- data.frame(
    surname = I(c("Tukey", "Venables", "Tierney", "Ripley", "McNeil")),
    nationality = c("US", "Australia", "US", "UK", "Australia"),
    deceased = c("yes", rep("no", 4)))
books <- data.frame(
    name = I(c("Tukey", "Venables", "Tierney",
             "Ripley", "Ripley", "McNeil", "R Core")),
    title = c("Exploratory Data Analysis",
              "Modern Applied Statistics ...",
              "LISP-STAT",
              "Spatial Statistics", "Stochastic Simulation",
              "Interactive Data Analysis",
              "An Introduction to R"),
    other.author = c(NA, "Ripley", NA, NA, NA, NA,
                     "Venables & Smith"))

(m1 <- merge(authors, books, by.x = "surname", by.y = "name"))
(m2 <- merge(books, authors, by.x = "name", by.y = "surname"))
stopifnot(as.character(m1[,1]) == as.character(m2[,1]),
          all.equal(m1[, -1], m2[, -1][ names(m1)[-1] ]),
          dim(merge(m1, m2, by = integer(0))) == c(36, 10))

## "R core" is missing from authors and appears only here :
merge(authors, books, by.x = "surname", by.y = "name", all = TRUE)

## example of using 'incomparables'
x <- data.frame(k1=c(NA,NA,3,4,5), k2=c(1,NA,NA,4,5), data=1:5)
y <- data.frame(k1=c(NA,2,NA,4,5), k2=c(NA,NA,3,4,5), data=1:5)
merge(x, y, by=c("k1","k2")) # NA's match
merge(x, y, by=c("k1","k2"), incomparables=NA)
merge(x, y, by="k1") # NA's match, so 6 rows
merge(x, y, by="k2", incomparables=NA) # 2 rows
}
\keyword{array}
\keyword{manip}
