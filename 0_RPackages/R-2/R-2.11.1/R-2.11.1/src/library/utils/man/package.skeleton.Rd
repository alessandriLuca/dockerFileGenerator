% File src/library/utils/man/package.skeleton.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2008 R Core Development Team
% Distributed under GPL 2 or later

\name{package.skeleton}
\alias{package.skeleton}
\title{Create a Skeleton for a New Source Package}
\description{
  \code{package.skeleton} automates some of the setup for a new source
  package.  It creates directories, saves functions, data, and R code files to
  appropriate places, and creates skeleton help files and a
  \file{Read-and-delete-me} file describing further steps in packaging. 
}
\usage{
package.skeleton(name = "anRpackage", list,
                 environment = .GlobalEnv,
                 path = ".", force = FALSE, namespace = FALSE,
                 code_files = character())
}
\arguments{
  \item{name}{character string: the package name and directory name for
    your package.}
  \item{list}{character vector naming the \R objects to put in the
    package.  Usually, at most one of \code{list}, \code{environment},
    or \code{code_files} will be supplied.  See \sQuote{Details}.}
  \item{environment}{an environment where objects are looked for.  See
    \sQuote{Details}.}
  \item{path}{path to put the package directory in.}
  \item{force}{If \code{FALSE} will not overwrite an existing directory.}
  \item{namespace}{a logical indicating whether to add a name space for
    the package.  If \code{TRUE}, a \code{NAMESPACE} file is created
    to export all objects whose names begin with a letter, plus all S4
    methods and classes.}
  \item{code_files}{a character vector with the paths to R code files to
    build the package around.  See \sQuote{Details}.}
}
\value{
  Used for its side-effects.
}
\details{
  The arguments \code{list}, \code{environment}, and \code{code_files}
  provide alternative ways to initialize the package.  If
  \code{code_files} is supplied, the files so named will be sourced to
  form the environment, then used to generate the package skeleton.
  Otherwise \code{list} defaults to the non-hidden files in
  \code{environment} (those whose name does not start with \code{.}),
  but can be supplied to select a subset of the objects in that
  environment.

  Stubs of help files are generated for functions, data objects, and
  S4 classes and methods, using the \code{\link{prompt}},
  \code{\link{promptClass}},  and \code{\link{promptMethods}} functions.

  The package sources are placed in subdirectory \code{name} of
  \code{path}.  If \code{code_files} is supplied, these files are
  copied; otherwise, objects will be dumped into individual source
  files.
  The file names in \code{code_files} should  have suffix \code{".R"} and
  be in the current working directory.
  
  The filenames created for source and documentation try to be valid for
  all OSes known to run R.  Invalid characters are replaced by \samp{_},
  invalid names are preceded by \samp{zz}, names are converted to lower
  case (to avoid case collisions on case-insensitive file systems) and
  finally the converted names are made unique by
  \code{\link{make.unique}(sep = "_")}.  This can be done for code and
  help files but not data files (which are looked for by name). Also,
  the code and help files should have names starting with an ASCII
  letter or digit, and this is checked and if necessary \code{z}
  prepended.

  When you are done, delete the \file{Read-and-delete-me} file, as it
  should not be distributed.
}

\references{
  Read the \emph{Writing R Extensions} manual for more details.

  Once you have created a \emph{source} package you need to install it:
  see the \emph{R Installation and Administration} manual,
  \code{\link{INSTALL}} and \code{\link{install.packages}}.
}

\seealso{
  \code{\link{prompt}}, \code{\link{promptClass}}, and
  \code{\link{promptMethods}}.
}

\examples{
require(stats)
## two functions and two "data sets" :
f <- function(x,y) x+y
g <- function(x,y) x-y
d <- data.frame(a=1, b=2)
e <- rnorm(1000)
\dontshow{
  owd <- getwd()
  setwd(tempdir())
}
package.skeleton(list=c("f","g","d","e"), name="mypkg")
\dontshow{ setwd(owd) }
}
\keyword{file}
\keyword{utilities}
