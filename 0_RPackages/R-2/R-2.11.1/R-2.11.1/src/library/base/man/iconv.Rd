% File src/library/base/man/iconv.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2010 R Core Development Team
% Distributed under GPL 2 or later

\name{iconv}
\alias{iconv}
\alias{iconvlist}
\concept{encoding}
\title{Convert Character Vector between Encodings}
\description{
  This uses system facilities to convert a character vector between
  encodings: the \sQuote{i} stands for \sQuote{internationalization}.
}
\usage{
iconv(x, from ="", to = "", sub = NA, mark = TRUE)

iconvlist()
}

\arguments{
  \item{x}{A character vector, or an object to be converted to a character
    vector by \code{\link{as.character}}.}
  \item{from}{A character string describing the current encoding.}
  \item{to}{A character string describing the target encoding.}
  \item{sub}{character string.  If not \code{NA} it is used to replace
    any non-convertible bytes in the input.  (This would normally be a
    single character, but can be more.)  If \code{"byte"}, the indication is
    \code{"<xx>"} with the hex code of the byte.}
  \item{mark}{logical, for expert use.  Should encodings be marked?}
}

\details{
  The names of encodings and which ones are available are
  platform-dependent.  All \R platforms support \code{""} (for the
  encoding of the current locale), \code{"latin1"} and \code{"UTF-8"}.
  Generally case is ignored when specifying an encoding.

  On many platforms, including Windows, \code{iconvlist} provides an
  alphabetical list of the supported encodings.  On others, the
  information is on the man page for \code{iconv(5)} or elsewhere in the
  man pages (but beware that the system command \code{iconv} may not
  support the same set of encodings as the C functions \R calls).
  Unfortunately, the names are rarely common across platforms.

  Elements of \code{x} which cannot be converted (perhaps because they
  are invalid or because they cannot be represented in the target
  encoding) will be returned as \code{NA} unless \code{sub} is specified.

  Most versions of \code{iconv} will allow transliteration by appending
  \samp{//TRANSLIT} to the \code{to} encoding: see the examples.

  
  Encoding \code{"ASCII"} is also accepted, but prior to \R 2.10.0
  conversion to \code{"ASCII"} on Windows might have involved dropping
  accents.
  
  Any encoding bits (see \code{\link{Encoding}}) on elements of \code{x}
  are ignored: they will always be translated as if from \code{from}
  even if declared otherwise.

  \code{"UTF8"} will be accepted as meaning the (more correct) \code{"UTF-8"}.
}

\section{Implementation Details}{
  \code{iconv} was optional before \R 2.10.0, but its absence was
  deprecated in \R 2.5.0.

  There are three main implementations of \code{iconv} in use.
  \samp{glibc} (as used on Linux) contains one.  Several platforms
  supply GNU \samp{libiconv}, including Mac OS X and Cygwin.  On Windows
  we use a version of Yukihiro Nakadaira's \samp{win_iconv}, which is
  based on Windows' codepages (but \samp{libiconv} can be used by
  swapping a DLL).  All three have \code{iconvlist}, ignore case in
  encoding names and support \samp{//TRANSLIT} (but with different
  results, and for \samp{win_iconv} currently a \sQuote{best fit}
  strategy is used except for \code{to = "ASCII"}).

  Most commercial Unixes contain an implemetation of \code{iconv} but
  none we have encountered have supported the encoding names we need:
  the \dQuote{R Installation and Administration Manual} recommends
  installing \samp{libiconv} on Solaris and AIX, for example.

  There are other implementations, e.g. NetBSD uses one from the Citrus
  project (which does not support \samp{//TRANSLIT}) and there is an
  older FreeBSD port (\samp{libiconv} is usually used there): it has not
  been reported whether or not these work with \R.
}

\value{
  A character vector of the same length and the same attributes as
  \code{x} (after conversion).

  If \code{mark = TRUE} (the default) the elements of the result have a
  declared encoding if \code{from} is \code{"latin1"} or \code{"UTF-8"},
  or if \code{from = ""} and the current locale's encoding is detected
  as Latin-1 or UTF-8.
}
\seealso{
  \code{\link{localeToCharset}}, \code{\link{file}}. 
}
\examples{
## not all systems have iconvlist
try(utils::head(iconvlist(), n = 50))

\dontrun{
## convert from Latin-2 to UTF-8: two of the glibc iconv variants.
iconv(x, "ISO_8859-2", "UTF-8")
iconv(x, "LATIN2", "UTF-8")
}

## Both x below are in latin1 and will only display correctly in a
## locale that can represent and display latin1.
x <- "fa\xE7ile"
Encoding(x) <- "latin1"
x
charToRaw(xx <- iconv(x, "latin1", "UTF-8"))
xx

iconv(x, "latin1", "ASCII")          #   NA
iconv(x, "latin1", "ASCII", "?")     # "fa?ile"
iconv(x, "latin1", "ASCII", "")      # "faile"
iconv(x, "latin1", "ASCII", "byte")  # "fa<e7>ile"

# Extracts from R help files
x <- c("Ekstr\xf8m", "J\xf6reskog", "bi\xdfchen Z\xfcrcher")
Encoding(x) <- "latin1"
x
try(iconv(x, "latin1", "ASCII//TRANSLIT"))  # platform-dependent
iconv(x, "latin1", "ASCII", sub="byte")
}
\keyword{ character }
\keyword{ utilities }
