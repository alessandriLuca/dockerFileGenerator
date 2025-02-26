% File src/library/base/man/Memory.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2011 R Core Development Team
% Distributed under GPL 2 or later

\name{Memory}
\alias{Memory}
\alias{mem.limits}
\title{Memory Available for Data Storage}
\description{
  Use command line options to control the memory available for \R.
}
\usage{
#ifdef unix
\special{R --min-vsize=vl --max-vsize=vu --min-nsize=nl --max-nsize=nu \\
  --max-ppsize=N}
#endif
#ifdef windows
\special{Rgui --min-vsize=vl --max-vsize=vu --min-nsize=nl --max-nsize=nu \\
  --max-ppsize=N}
\special{Rterm --min-vsize=vl --max-vsize=vu --min-nsize=nl --max-nsize=nu \\
  --max-ppsize=N}
#endif

mem.limits(nsize = NA, vsize = NA)
}
\arguments{
  \item{vl, vu, vsize}{Heap memory in bytes.}
  \item{nl, nu, nsize}{Number of cons cells.}
  \item{N}{Number of nested \code{PROTECT} calls.}
}
\details{
  \R has a variable-sized workspace.  These limits are mainly
  historical, and now used only exceptionally.  They were provided both
  as a way to control the overall memory usage (which can be done better
  by operating-system facilities such as \code{ulimit} or \code{limit}
  in a Unix-alike shell or by using the command-line option
  \option{--max-mem-size} on Windows), and since setting larger values
  of the minimum sizes will make \R slightly more efficient on large
  tasks.

#ifdef windows
  (On Windows the \option{--max-mem-size} option sets the maximum memory
  allocation: it has a minimum allowed value of 32M.  This is intended
  to catch attempts to allocate excessive amounts of memory which may
  cause other processes to run out of resources.  See also
  \code{\link{memory.limit}}.)
#endif

  To understand the options, one needs to know that \R maintains
  separate areas for fixed and variable sized objects.  The first of these
  is allocated as an array of \emph{cons cells} (Lisp programmers will
  know what they are, others may think of them as the building blocks of
  the language itself, parse trees, etc.), and the second are thrown on a
  \emph{heap} of \sQuote{Vcells} of 8 bytes each.  Effectively,
  the inputs \code{vl} and \code{vu} are rounded up to the next
  multiple of 8.

  Each cons cell occupies 28 bytes on a 32-bit build of \R, (usually) 56
  bytes on a 64-bit build.

  The \option{--*-nsize} options can be used to specify the number of
  cons cells and the \option{--*-vsize} options specify the size of the
  vector heap in bytes.  Both options must be integers or integers
  followed by \code{G}, \code{M}, \code{K}, or \code{k} meaning
  \emph{Giga} (\eqn{2^{30} = 1073741824}) \emph{Mega} (\eqn{2^{20} =
    1048576}), (computer) \emph{Kilo} (\eqn{2^{10} = 1024}), or regular
  \emph{kilo} (1000).

  The \option{--min-*} options set the \sQuote{minimal} sizes for the
  number of cons cells and for the vector heap.  These values are also
  the initial values, but thereafter \R will grow or shrink the areas
  depending on usage, but never exceeding the limits set by the
  \option{--max-*} options nor decreasing below the initial values.
  Note that the areas are not actually allocated initially: rather these
  values are the sizes for triggering garbage collection.

  The default values are currently minima of 350k cons cells, 6Mb of
  vector heap and no maxima (other than machine resources).  The maxima
  can be increased during an \R session by calling
  \code{\link{mem.limits}}. (If this is called with the default values,
  it reports the current settings.)  Setting values larger than the
  maximum allowed value (e.g. \code{Inf}) removes the corresponding limit.

  You can find out the current memory consumption (the heap and cons
  cells used as numbers and megabytes) by typing \code{\link{gc}()} at the
  \R prompt.  Note that following \code{\link{gcinfo}(TRUE)}, automatic
  garbage collection always prints memory use statistics.  Maxima will
  never be reduced below the current values for triggering garbage
  collection, and attempts to do so will be silently ignored.
  
  The command-line option \option{--max-ppsize} controls the maximum
  size of the pointer protection stack.  This defaults to 50000, but can
  be increased to allow deep recursion or large and complicated
  calculations to be done.  \emph{Note} that parts of the garbage
  collection process goes through the full reserved pointer protection
  stack and hence becomes slower when the size is increased.  Currently
  the maximum value accepted is 500000.
}

\value{
  \code{mem.limits()} returns a numeric vector giving the current
  settings of the maxima, possibly \code{NA} (for unlimited).
}

\seealso{
  \emph{An Introduction to R} for more command-line options.

  \code{\link{Memory-limits}} for the design limitations.

  \code{\link{gc}} for information on the garbage collector and total
  memory usage,  \code{\link{object.size}(a)} for the (approximate)
  size of \R object \code{a}.  \code{\link{memory.profile}} for
  profiling the usage of cons cells.
#ifdef windows

  \code{\link{memory.size}} to monitor total memory usage,
  \code{\link{memory.limit}} for the current limit.
#endif
}

\keyword{environment}
