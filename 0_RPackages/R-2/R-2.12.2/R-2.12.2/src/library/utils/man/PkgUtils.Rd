% File src/library/utils/man/PkgUtils.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{PkgUtils}
\alias{build}
\alias{check}
\title{Utilities for Building and Checking Add-on Packages}
\description{
  Utilities for checking whether the sources of an \R add-on package
  work correctly, and for building a source or binary package from
  them.
}
\usage{
\special{R CMD check [options] pkgdirs}
\special{R CMD build [options] pkgdirs}
}
\arguments{
  \item{pkgdirs}{a list of names of directories with sources of \R
    add-on packages.  For \code{check} these can also be the filenames of
    compressed \command{tar} archives with extension \file{.tar.gz} or
    \file{.tgz} or \file{.tar.bz2}.}
  \item{options}{further options to control the processing, or for
    obtaining information about usage and version of the utility.}
}
\details{
  \command{R CMD check}
  checks \R add-on packages from their sources, performing a wide
  variety of diagnostic checks.

  \command{R CMD build}
  builds \R source or binary packages from their sources.  The name(s)
  of the packages are taken from the \file{DESCRIPTION} files and not
  from the directory names.

  Use \command{R CMD \var{foo} --help}
  to obtain usage information on utility \code{\var{foo}}.

  Several of the options to \code{build --binary} are passed to
  \code{\link{INSTALL}} so consult its help for the details.
}
#ifdef windows
\note{
  They make use of a temporary directory specified by the environment
  variable \code{TMPDIR} and defaulting to \samp{c:/TEMP}.  Do ensure
  that if set forward slashes are used.
}
#endif
\seealso{
  The sections on \dQuote{Checking and building packages} and
  \dQuote{Processing Rd format} in \dQuote{Writing \R Extensions}
#ifdef unix
  (see the \file{doc/manual} subdirectory of the \R source tree).
#endif
#ifdef windows
  (see the Manuals sub-menu of the Help menu on the console).
#endif

  \code{\link{INSTALL}} is called by \code{build --binary}.
}
\keyword{utilities}
