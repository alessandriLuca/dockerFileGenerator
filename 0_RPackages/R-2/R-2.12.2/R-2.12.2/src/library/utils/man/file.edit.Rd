% File src/library/utils/man/file.edit.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2011 R Core Development Team
% Distributed under GPL 2 or later

\name{file.edit}
\alias{file.edit}
\title{Edit One or More Files}
\description{Edit one or more files in a text editor.}
\usage{
file.edit(\dots, title = file, editor = getOption("editor"))
}
\arguments{
  \item{\dots}{one or more character vectors containing the names of the
    files to be displayed.  These will be tilde-expanded: see
    \code{\link{path.expand}}.}
  \item{title}{the title to use in the editor; defaults to the filename.}  
  \item{editor}{the text editor to be used.  See \sQuote{Details}.}
}
\details{
  The behaviour of this function is very system dependent.  Currently
  files can be opened only one at a time on Unix; on Windows, the
  internal editor allows multiple files to be opened, but has a limit of
  50 simultaneous edit windows.
    
  The \code{title} argument is used for the window caption in Windows,
  and is currently ignored on other platforms.

  The \code{fileEncoding} argument was added in \R 2.13.0: any error in
  re-encoding the files to the native encoding will cause the function
  to fail.

  The default for \code{editor} is system-dependent.   On
  Windows it defaults to \code{"internal"}, the script editor, and in
  the Mac OS X GUI the document editor is used whatever the value of
  \code{editor}.  On Unix the default is set from the environment
  variables \env{EDITOR} or \env{VISUAL} if either is set, otherwise
  \code{vi} is used.
}
\seealso{
  \code{\link{files}},
  \code{\link{file.show}},
  \code{\link{edit}},
  \code{\link{fix}},
}
\examples{
\dontrun{
# open two R scripts for editing
file.edit("script1.R", "script2.R")
}
}
\keyword{utilities}
