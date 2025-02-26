% File src/library/base/man/locales.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2012 R Core Team
% Distributed under GPL 2 or later

\name{locales}
\alias{locales}
\alias{Sys.getlocale}
\alias{Sys.setlocale}
\alias{LC_ALL}
\alias{LC_COLLATE}
\alias{LC_CTYPE}
\alias{LC_MONETARY}
\alias{LC_NUMERIC}
\alias{LC_TIME}

#ifdef unix
\alias{LC_MESSAGES}
\alias{LC_PAPER}
\alias{LC_MEASUREMENT}
#endif

\title{Query or Set Aspects of the Locale}
\description{
  Get details of or set aspects of the locale for the \R process.
}
\usage{
Sys.getlocale(category = "LC_ALL")
Sys.setlocale(category = "LC_ALL", locale = "")
}
\arguments{
  \item{category}{character string.  The following categories should
    always be supported: \code{"LC_ALL"}, \code{"LC_COLLATE"},
    \code{"LC_CTYPE"}, \code{"LC_MONETARY"}, \code{"LC_NUMERIC"} and
    \code{"LC_TIME"}.  Some systems (not Windows) will also support
    \code{"LC_MESSAGES"}, \code{"LC_PAPER"} and \code{"LC_MEASUREMENT"}.
  }
  \item{locale}{character string.  A valid locale name on the system in
    use.  Normally \code{""} (the default) will pick up the default
    locale for the system.}
}
\details{
  The locale describes aspects of the internationalization of a program.
  Initially most aspects of the locale of \R are set to \code{"C"} (which
  is the default for the C language and reflects North-American usage).
  \R sets \code{"LC_CTYPE"} and \code{"LC_COLLATE"}, which allow the
  use of a different character set and alphabetic
  comparisons in that character set (including the use of
  \code{\link{sort}}), \code{"LC_MONETARY"} (for use by
  \code{\link{Sys.localeconv}}) and \code{"LC_TIME"} may affect
  the behaviour of \code{\link{as.POSIXlt}} and \code{\link{strptime}}
  and functions which use them (but not \code{\link{date}}).

  The first seven categories described here are those specified by
  POSIX.  \code{"LC_MESSAGES"} will be \code{"C"} on systems that do not
  support message translation, and is not supported on Windows.  Trying
  to use an unsupported category is an error for \code{Sys.setlocale}.
  
  Note that setting category \code{"LC_ALL"} sets only
  \code{"LC_COLLATE"}, \code{"LC_CTYPE"}, \code{"LC_MONETARY"} and
  \code{"LC_TIME"}.

  Attempts to set an invalid locale are ignored.  There may or may not
  be a warning, depending on the OS.

  Attempts to change the character set (by
  \code{Sys.setlocale("LC_TYPE", )}, if that implies a different
  character set) during a session may not work and are likely to lead to
  some confusion.

  Note that the \env{\link{LANGUAGE}} environment variable has
  precedence over \code{"LC_MESSAGES"} in selecting the language of
  message translation on most \R platforms.
}
\value{
  A character string of length one describing the locale in use (after
  setting for \code{Sys.setlocale}), or an empty character string if the
  current locale settings are invalid or \code{NULL} if locale
  information is unavailable.

  For \code{category = "LC_ALL"} the details of the string are
  system-specific: it might be a single locale name or a set of locale
  names separated by \code{"/"} (Solaris, Mac OS X) or \code{";"}
  (Windows, Linux).  For portability, it is best to query categories
  individually: it is not necessarily the case that the result of
  \code{foo <- Sys.getlocale()} can be used in
  \code{Sys.setlocale("LC_ALL", locale = foo)}.
}
% assume this just affects strtod/atof, scanf/printf and friends,
% as seems to be the case in glibc.
\section{Warning}{
  Setting \code{"LC_NUMERIC"} may cause \R to function
  anomalously, so gives a warning.  Input conversions
  in \R itself are unaffected, but the reading and writing of ASCII
  \code{\link{save}} files will be, as may packages.
  
  Setting it temporarily on a Unix-alike to produce graphical or text
  output may work well enough, but \code{\link{options}(OutDec)} is
  often preferable.
  
  Almost all the output routines used by \R itself under Windows ignore
  the setting of \code{"LC_NUMERIC"} since they make use of the Trio
  library which is not internationalized.
}

\note{
  Changing the values of locale categories whilst \R is running ought
  to be noticed by the OS services, and usually is but exceptions have
  been seen (usually in collation services).
}

\seealso{
  \code{\link{strptime}} for uses of \code{category = "LC_TIME"}.
  \code{\link{Sys.localeconv}} for details of numerical and monetary
  representations.

  \code{\link{l10n_info}} gives some summary facts about the locale and
  its encoding.

  The \sQuote{R Installation and Administration} manual for background
  on locales and how to find out locale names on your system.
}
\examples{
Sys.getlocale()
Sys.getlocale("LC_TIME")
\dontrun{
Sys.setlocale("LC_TIME", "de")     # Solaris: details are OS-dependent
Sys.setlocale("LC_TIME", "de_DE.utf8")   # Modern Linux etc.
Sys.setlocale("LC_TIME", "de_DE.UTF-8")  # ditto
Sys.setlocale("LC_TIME", "de_DE")  # Mac OS X, in UTF-8
Sys.setlocale("LC_TIME", "German") # Windows
}
Sys.getlocale("LC_PAPER")          # may or may not be set

Sys.setlocale("LC_COLLATE", "C")   # turn off locale-specific sorting,
                                   #  usually
}
\keyword{utilities}
