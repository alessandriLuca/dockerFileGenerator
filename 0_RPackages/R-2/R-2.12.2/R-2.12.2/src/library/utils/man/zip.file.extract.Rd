% File src/library/utils/man/zip.file.extract.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2009 R Core Development Team
% Distributed under GPL 2 or later

\name{zip.file.extract}
\alias{zip.file.extract}
\title{Extract File from a Zip Archive}
\usage{
zip.file.extract(file, zipname = "R.zip",
                 unzip = getOption("unzip"), dir = tempdir())
}
\arguments{
 \item{file}{file name. (If a path is given, see \sQuote{Note}.)}
 \item{zipname}{The file name (not path) of a \code{zip} archive,
   including the \code{".zip"} extension if required.}
 \item{unzip}{character string: the method to be used, an empty string
   indicates \code{"internal"}.}
 \item{dir}{directory (\dQuote{folder}) name into which the extraction
   happens.  Must be writable to the caller.}
}
\description{
  This will extract the file named \code{file} from the zip archive,
  if possible, and write it in a temporary location.
}
\details{
  All platforms support an \code{"internal"} unzip: this is the default
  under Windows and the fall-back under Unix if no \code{unzip} program
  was found during configuration and \env{R_UNZIPCMD} is not set.

  The file will be extracted if it is in the archive and any required
  \code{unzip} utility is available.  It will be extracted to the
  directory given by \code{dir}, overwriting any existing file of
  that name.
}
\note{
  The \code{"internal"} method is very simple, and will not set file dates.

  This is a helper function for \code{\link{help}},
  \code{\link{example}} and \code{\link{data}}.  As such, it handles
  file paths in an unusual way.  Any path component of \code{zipname} is
  ignored, and the path to \code{file} is used only to determine the
  directory within which to find \code{zipname}.
}
\source{
  The C code uses \code{zlib} and is in particular based on the
  contributed \samp{minizip} application in the \code{zlib} sources by
  Gilles Vollant.
}
\value{
  The name of the original or extracted file.  Success is indicated by
  returning a different name.
}
\seealso{
  \code{\link{unzip}}
}

\keyword{file}
