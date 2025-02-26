% File src/library/utils/man/browseURL.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2009 R Core Development Team
% Distributed under GPL 2 or later

\name{browseURL}
\alias{browseURL}
\title{Load URL into a WWW Browser}
\description{
  Load a given URL into a WWW browser.
}
\usage{
browseURL(url, browser = getOption("browser"), encodeIfNeeded = FALSE)
}
\arguments{
  \item{url}{a non-empty character string giving the URL to be loaded.}
  \item{browser}{a non-empty character string giving the name of the
    program to be used as hypertext browser.  It should be in the PATH,
    or a full path specified.  Alternatively, an \R function to be
    called to invoke the browser.
    
    Under Windows \code{NULL} is also allowed (and is the default), and
    implies that the file association mechanism will be used.
  }
  \item{encodeIfNeeded}{Should the URL be encoded by
    \code{\link{URLencode}} before passing to the browser?  This is not
    needed (and might be harmful) if the \code{browser} program/function
    itself does encoding, and can be harmful for \samp{file://} URLs on some
    systems and for \samp{http://} URLs passed to some CGI applications.
    Fortunately, most URLs do not need encoding.}
}
#ifdef unix
\details{
  The default browser is set by option \code{"browser"}, in turn set by
  the environment variable \env{R_BROWSER} which is by default set in
  file \file{\var{\link{R_HOME}}/etc/Renviron} to a choice
  made manually or automatically when \R was configured.  (See
  \code{\link{Startup}} for where to override that default value.)
  
  If \code{browser} supports remote control and \R knows how to perform
  it, the URL is opened in any already running browser or a new one if
  necessary.  This mechanism currently is available for browsers which
  support the \code{"-remote openURL(...)"} interface (which includes
  Mozilla >= 0.9.5 and Mozilla Firefox), Galeon, KDE konqueror
  (\emph{via} kfmclient) and the GNOME interface to Mozilla.  Note that
  the type of browser is determined from its name, so this mechanism
  will only be used if the browser is installed under its canonical
  name.

  Because \code{"-remote"} will use any browser displaying on the X
  server (whatever machine it is running on), the remote control
  mechanism is only used if \code{DISPLAY} points to the local host.
  This may not allow displaying more than one URL at a time from a
  remote host.

  It is the caller's responsibility to encode \code{url} if necessary
  (see \code{\link{URLencode}}).  This can be tricky for file URLs,
  where the format accepted can depend on the browser and OS.
}
\examples{
\dontrun{## for KDE users who want to open files in a new tab
options(browser="kfmclient newTab") 
browseURL("http://www.r-project.org")
}}
#endif
#ifdef windows
\details{
  Some browsers have required \code{:} be replaced by \code{|} in file
  paths: others do not accept that.  All seem to accept \code{\\} as a
  path separator even though the RFC1738 standard requires \code{/}.
}
\examples{
\dontrun{browseURL("http://www.r-project.org")
browseURL("file://d:/R/R-2.5.1/doc/html/index.html",
          browser="C:/Program Files/Mozilla Firefox/firefox.exe")
}}
#endif
\keyword{file}
