% File src/library/graphics/man/polygon.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2007 R Core Development Team
% Distributed under GPL 2 or later

\name{polygon}
\alias{polygon}
\title{Polygon Drawing}
\description{
  \code{polygon} draws the polygons whose vertices are
  given in \code{x} and \code{y}.
}
\usage{
polygon(x, y = NULL, density = NULL, angle = 45,
        border = NULL, col = NA, lty = par("lty"),
        \dots, fillOddEven = FALSE)
}
\arguments{
  \item{x,y}{vectors containing the coordinates of the vertices
    of the polygon.}
  \item{density}{the density of shading lines, in lines per inch.  The
    default value of \code{NULL} means that no shading lines are drawn.
    A zero value of \code{density} means no shading nor filling whereas
    negative values (and \code{NA}) suppress shading (and so allow
    color filling).}
  \item{angle}{the slope of shading lines, given as an angle
     in degrees (counter-clockwise).}
   \item{col}{the color for filling the polygon. The default,
     \code{NA}, is to leave polygons unfilled, unless \code{density} is
     specified.  (For back-compatibility, \code{NULL} is equivalent to
     \code{NA}.)  If \code{density} is specified with a positive value
     this gives the color of the shading lines.}
  \item{border}{the color to draw the border.  The default, \code{NULL},
    means to use \code{\link{par}("fg")}.  Use \code{border = NA} to
    omit borders.
    
    For compatibility with S, \code{border} can also be logical, in
    which case \code{FALSE} is equivalent to \code{NA} (borders omitted)
    and \code{TRUE} is equivalent to \code{NULL} (use the foreground colour),
  }
  \item{lty}{the line type to be used, as in \code{\link{par}}.}
  \item{\dots}{graphical parameters such as \code{xpd}, \code{lend},
    \code{ljoin} and \code{lmitre} can be given as arguments.}
  \item{fillOddEven}{logical controlling the polygon fill mode:  see
      below for details.  Default \code{FALSE}.} 
}
\details{
  The coordinates can be passed in a plotting structure
  (a list with \code{x} and \code{y} components), a two-column matrix,
  \dots.  See \code{\link{xy.coords}}.

  It is assumed that the polygon is to be closed by joining the last point to
  the first point.
 
  The coordinates can contain missing values.  The behaviour is similar
  to that of \code{\link{lines}}, except
  that instead of breaking a line into several lines, \code{NA}
  values break the polygon into several complete polygons
  (including closing the last point to the first point).  See
  the examples below.

  When multiple polygons are produced,
  the values of \code{density}, \code{angle}, \code{col}, \code{border},
  and \code{lty} are recycled in the usual manner.
}
\section{Bugs}{
  Self-intersecting polygons may be filled using either the
  \dQuote{odd-even} or \dQuote{non-zero} rule.  These fill a region if
  the polygon border encircles it an odd or non-zero number of times,
  respectively. Shading lines are handled internally by \R{} according
  to the \code{fillOddEven} argument, but device-based solid fills
  depend on the graphics device.  The
#ifdef windows
  \code{\link{windows}},
#endif
  \code{\link{pdf}} and \code{\link{postscript}} devices
  have their own \code{fillOddEven} argument to control this.
}
\author{
  The code implementing polygon shading was donated by
  Kevin Buhr \email{buhr@stat.wisc.edu}.
}
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.

  Murrell, P. (2005) \emph{R Graphics}. Chapman & Hall/CRC Press.
}
\seealso{
  \code{\link{segments}} for even more flexibility, \code{\link{lines}},
  \code{\link{rect}}, \code{\link{box}}, \code{\link{abline}}.

  \code{\link{par}} for how to specify colors.
}
\examples{
x <- c(1:9,8:1)
y <- c(1,2*(5:3),2,-1,17,9,8,2:9)
op <- par(mfcol=c(3,1))
for(xpd in c(FALSE,TRUE,NA)) {
  plot(1:10, main = paste("xpd =", xpd))
  box("figure", col = "pink", lwd=3)
  polygon(x,y, xpd=xpd, col="orange", lty=2, lwd=2, border="red")
}
par(op)

n <- 100
xx <- c(0:n, n:0)
yy <- c(c(0,cumsum(stats::rnorm(n))), rev(c(0,cumsum(stats::rnorm(n)))))
plot   (xx, yy, type="n", xlab="Time", ylab="Distance")
polygon(xx, yy, col="gray", border = "red")
title("Distance Between Brownian Motions")

# Multiple polygons from NA values
# and recycling of col, border, and lty
op <- par(mfrow=c(2,1))
plot(c(1,9), 1:2, type="n")
polygon(1:9, c(2,1,2,1,1,2,1,2,1),
        col=c("red", "blue"),
        border=c("green", "yellow"),
        lwd=3, lty=c("dashed", "solid"))
plot(c(1,9), 1:2, type="n")
polygon(1:9, c(2,1,2,1,NA,2,1,2,1),
        col=c("red", "blue"),
        border=c("green", "yellow"),
        lwd=3, lty=c("dashed", "solid"))
par(op)

# Line-shaded polygons
plot(c(1,9), 1:2, type="n")
polygon(1:9, c(2,1,2,1,NA,2,1,2,1),
        density=c(10, 20), angle=c(-45, 45))
}
\keyword{aplot}
