% File src/library/base/man/Foreign.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{Foreign}
\alias{Foreign}
\alias{.C}
\alias{.Fortran}
\alias{.External}
\alias{.Call}
\title{Foreign Function Interface}
\description{
  Functions to make calls to compiled code that has been loaded into \R.
}
\usage{
       .C(name, \dots, NAOK = FALSE, DUP = TRUE, PACKAGE, ENCODING)
 .Fortran(name, \dots, NAOK = FALSE, DUP = TRUE, PACKAGE, ENCODING)
.External(name, \dots, PACKAGE)
    .Call(name, \dots, PACKAGE)
}
\arguments{
  \item{name}{a character string giving the name of a C function or
    Fortran subroutine, or an object of class
    \code{"\link{NativeSymbolInfo}"}, \code{"\link{RegisteredNativeSymbol}"}
    or \code{"\link{NativeSymbol}"} referring to such a name.}
  \item{\dots}{arguments to be passed to the foreign function.}
  \item{NAOK}{if \code{TRUE} then any \code{\link{NA}} or
    \code{\link{NaN}} or \code{\link{Inf}} values in the arguments are
    passed on to the foreign function.  If \code{FALSE}, the presence of
    \code{NA} or \code{NaN} or \code{Inf} values is regarded as an error.}
  \item{DUP}{if \code{TRUE} then arguments are duplicated before
    their address is passed to C or Fortran.}
  \item{PACKAGE}{if supplied, confine the search for the \code{name} to
    the DLL given by this argument (plus the conventional extension,
    \file{.so}, \file{.sl}, \file{.dll}, \dots).  This is intended to
    add safety for packages, which can ensure by using this argument
    that no other package can override their external symbols.  Use
    \code{PACKAGE="base"} for symbols linked in to \R.}
  \item{ENCODING}{optional name for an encoding to be assumed for
    character vectors.  See \sQuote{Details}.}
}
\value{
  The functions \code{.C} and \code{.Fortran} return a list similar to
  the \code{\dots} list of arguments passed in, but reflecting any
  changes made by the C or Fortran code.

  \code{.External} and \code{.Call} return an (arbitrary) \R object.

  These calls are typically made in conjunction with
  \code{\link{dyn.load}} which links DLLs to \R.
}
\details{
  The functions \code{.C} and \code{.Fortran} can be used to make calls
  to compiled C and Fortran code.

  \code{.Call} can be used to call compiled code
  which makes use of internal \R objects, passing the arguments to
  the C code as a sequence of \R objects.

  \code{.External} can be used to call compiled code that uses \R
  objects in the same way as internal \R functions: this allows for a
  variable number of arguments.

  Specifying \code{ENCODING} overrides any declared encodings (see
  \code{\link{Encoding}}) which are otherwise used to translate to the
  current locale before passing the strings to the compiled code.
  
  These functions are all \link{primitive}, and \code{name} is always
  matched to the first argument supplied (which if named must partially
  match \code{name}).  The other named arguments follow \code{\dots} and
  so cannot be abbreviated.
  
  For details about how to write code to use with \code{.Call} and
  \code{.External}, see the chapter on \dQuote{System and foreign language
    interfaces} in the \dQuote{Writing \R Extensions} manual.
#ifdef windows

  For Windows-specific details on producing the external code, see the
  \dQuote{R Installation and Administration} manual.
#endif
}
\section{Argument types}{
  The mapping of the types of \R arguments to C or Fortran arguments
  in \code{.C} or \code{.Fortran} is

  \tabular{lll}{
    \R \tab     C \tab     Fortran\cr
    integer \tab int * \tab integer\cr
    numeric \tab double * \tab double precision\cr
    -- or -- \tab float * \tab real\cr
    complex \tab Rcomplex * \tab double complex\cr
    logical \tab int * \tab integer \cr
    character \tab char ** \tab [see below]\cr
    raw \tab unsigned char * \tab not allowed\cr
    list \tab SEXP *\tab not allowed\cr
    other \tab SEXP\tab not allowed\cr
  }

  Numeric vectors in \R will be passed as type \code{double *} to C (and
  as \code{double precision} to Fortran) unless (i) \code{.C} or
  \code{.Fortran} is used, (ii) \code{DUP} is true and (iii) the
  argument has attribute \code{Csingle} set to \code{TRUE} (use
  \code{\link{as.single}} or \code{\link{single}}).  This mechanism is
  only intended to be used to facilitate the interfacing of existing C
  and Fortran code.

  The C type \code{Rcomplex} is defined in \file{Complex.h} as a
  \code{typedef struct {double r; double i;}}.  Fortran type
  \code{double complex} is an extension to the Fortran standard, and the
  availability of a mapping of \code{complex} to Fortran may be compiler
  dependent.

  Logical values are sent as \code{0} (\code{FALSE}), \code{1}
  (\code{TRUE}) or \code{INT_MIN = -2147483648} (\code{NA}, but only if
  \code{NAOK = TRUE}), and the compiled code should return one of these
  three values.

  \emph{Note:} The C types corresponding to \code{integer} and
  \code{logical} are \code{int}, not \code{long} as in S.  This
  difference matters on most 64-bit platforms, where \code{int} is
  32-bit and \code{long} is 64-bit (but not on 64-bit Windows).
  
  \emph{Note:} The Fortran type corresponding to \code{logical} is
  \code{integer}, not \code{logical}: the difference matters on some
  older Fortran compilers.
  
  The first character string of a character vector is passed as a C
  character array to Fortran: that string may be usable as
  \code{character*255} if its true length is passed separately.  Only up
  to 255 characters of the string are passed back.  (How well this works,
  or even if it works at all, depends on the C and Fortran compilers
  and the platform.)

  Missing (\code{NA}) string values are passed to \code{.C} as the string
  "NA". As the C \code{char} type can represent all possible bit patterns
  there appears to be no way to distinguish missing strings from the
  string \code{"NA"}.  If this distinction is important use \code{.Call}.

  Functions, expressions, environments and other language elements are
  passed as the internal \R pointer type \code{SEXP}.  This type is
  defined in \file{Rinternals.h} or the arguments can be declared as
  generic pointers, \code{void *}. Lists are passed as C arrays of
  \code{SEXP} and can be declared as \code{void *} or \code{SEXP *}.
  Note that you cannot assign values to the elements of the list within
  the C routine. Assigning values to elements of the array corresponding
  to the list bypasses R's memory management/garbage collection and will
  cause problems.  Essentially, the array corresponding to the list is
  read-only. If you need to return S objects created within the C
  routine,  use the \code{.Call} interface.


  \R functions can be invoked using \code{call_S} or \code{call_R} and
  can be passed lists or the simple types as arguments.
}
%%-- This note by Thomas Lumley, (minimally edited by MM,
%%      edited by BDR for 1.2.0's non-moving garbage collector):
\section{Warning}{
  \emph{\code{DUP=FALSE} is dangerous.}

  There are two dangers with using \code{DUP=FALSE}.

  The first is that if you pass a local variable to
  \code{.C}/\code{.Fortran} with \code{DUP=FALSE}, your compiled code
  can alter the local variable and not just the copy in the return list.
  Worse, if you pass a local variable that is a formal parameter of
  the calling function, you may be able to change not only the local
  variable but the variable one level up.  This will be very hard to trace.

  The second is that lists are passed as a single \R \code{SEXP} with
  \code{DUP=FALSE}, not as an array of \code{SEXP}. This means the
  accessor macros in \file{Rinternals.h} are needed to get at the list
  elements and the lists cannot be passed to
  \code{call_S}/\code{call_R}.  New code using \R objects should be
  written using \code{.Call} or \code{.External}, so this is now only a
  minor issue.

  In addition, character vectors and lists cannot be used with
  \code{DUP=FALSE}.

  It is safe and useful to set \code{DUP=FALSE} if you do not change any
  of the variables that might be affected, e.g.,

  \code{.C("Cfunction", input=x, output=numeric(10))}.

  In this case the output variable did not exist before the call so it
  cannot cause trouble. If the input variable is not changed in the C
  code of \code{Cfunction} you are safe.

  Neither \code{.Call} nor \code{.External} copy their arguments.  You
  should treat arguments you receive through these interfaces as
  read-only.
}

\section{Fortran symbol names}{
  All Fortran compilers that can be used to compile \R map symbol names
  to lower case, and so does \code{.Fortran}.

  Symbol names containing underscores are not valid Fortran 77 (although
  they are valid in Fortran 9x).  Many Fortran 77 compilers will allow
  them but may translate them in a different way to names not containing
  underscores.  Such names will often work with \code{.Fortran} (since
  how they are translated is detected when \R is built and the
  information used by \code{.Fortran}), but portable code should not use
  Fortran names containing underscores.

  Use \code{.Fortran} with care for compiled Fortran 9x code: it may not
  work if the Fortran 9x compiler used differs from the Fortran compiler
  used when configuring \R, especially if the subroutine name is not
  lower-case or includes an underscore.  It is also possible to use
  \code{.C} and do any necessary symbol-name translation yourself.
}

\section{Header files for external code}{
  Writing code for use with \code{.External} and \code{.Call} will need to
  use internal \R structures.  If possible use just those defined in
  \file{Rinternals.h} and/or the macros in \file{Rdefines.h},
  as other header files are not installed and are even more
  likely to be changed.
}

\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole. (\code{.C} and \code{.Fortran}.)

  Chambers, J. M. (1998)
  \emph{Programming with Data. A Guide to the S Language}.
  Springer. (\code{.Call}.)
}
\seealso{\code{\link{dyn.load}}.}
\keyword{programming}
