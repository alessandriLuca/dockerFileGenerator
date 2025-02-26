#  File src/library/grDevices/R/unix/x11.R
#  Part of the R package, http://www.R-project.org
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

## An environment not exported from namespace:grDevices used to
## pass .X11.Fonts to the X11 device.
.X11env <- new.env()

assign(".X11.Options",
       list(display = "",
            width = NA_real_, height = NA_real_, pointsize = 12,
            bg = "transparent", canvas = "white",
            gamma = 1,
            colortype = "true", maxcubesize = 256,
            fonts = c("-adobe-helvetica-%s-%s-*-*-%d-*-*-*-*-*-*-*",
            "-adobe-symbol-medium-r-*-*-%d-*-*-*-*-*-*-*"),
            xpos = NA_integer_, ypos = NA_integer_,
	    title = "", type = "cairo", antialias = "default"),
       envir = .X11env)

assign(".X11.Options.default",
       get(".X11.Options", envir = .X11env),
       envir = .X11env)

assign("antialiases",
       c("default", "none", "gray", "subpixel"),
       envir = .X11env)

X11.options <- function(..., reset = FALSE)
{
    old <- get(".X11.Options", envir = .X11env)
    if(reset) {
        assign(".X11.Options",
               get(".X11.Options.default", envir = .X11env),
               envir = .X11env)
    }
    l... <- length(new <- list(...))
    check.options(new, name.opt = ".X11.Options", envir = .X11env,
                  assign.opt = l... > 0)
    if(reset || l... > 0) invisible(old) else old
}

X11 <- function(display = "", width, height, pointsize, gamma,
                bg, canvas, fonts, xpos, ypos, title, type, antialias)
{
    if(display == "" && .Platform$GUI == "AQUA" &&
       is.na(Sys.getenv("DISPLAY", NA))) Sys.setenv(DISPLAY = ":0")

    new <- list()
    if(!missing(display)) new$display <- display
    if(!missing(width)) new$width <- width
    if(!missing(height)) new$height <- height
    if(!missing(gamma)) new$gamma <- gamma
    if(!missing(pointsize)) new$pointsize <- pointsize
    if(!missing(bg)) new$bg <- bg
    if(!missing(canvas)) new$canvas <- canvas
    if(!missing(xpos)) new$xpos <- xpos
    if(!missing(ypos)) new$ypos <- ypos
    if(!missing(title)) new$title <- title
    if(!checkIntFormat(new$title)) stop("invalid 'title'")
    if(!missing(type))
        new$type <- match.arg(type, c("Xlib", "cairo", "nbcairo"))

    antialiases <- get("antialiases", envir = .X11env)
    if(!missing(antialias))
        new$antialias <- match.arg(antialias, antialiases)
    d <- check.options(new, name.opt = ".X11.Options", envir = .X11env)
    type <-
	if(capabilities("cairo"))
	    switch(d$type, "cairo" = 1, "nbcairo" = 2, # otherwise:
		   0)
	else 0
    ## Aargh -- trkplot has a trapdoor and does not set type.
    if (display == "XImage") type <- 0
    antialias <- match(d$antialias, antialiases)
    .Internal(X11(d$display, d$width, d$height, d$pointsize, d$gamma,
                  d$colortype, d$maxcubesize, d$bg, d$canvas, d$fonts,
                  NA_integer_, d$xpos, d$ypos, d$title, type, antialias))
}

x11 <- X11


png <- function(filename = "Rplot%03d.png",
                width = 480, height = 480, units = "px",
                pointsize = 12, bg = "white", res = NA, ...,
                type = c("cairo", "Xlib", "quartz"), antialias)
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    units <- match.arg(units, c("in", "px", "cm", "mm"))
    if(units != "px" && is.na(res))
        stop("'res' must be specified unless 'units = \"px\"'")
    height <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * height
    width <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * width
    new <- list(...)
    if(missing(type)) type <- getOption("bitmapType")
    type <- match.arg(type)
    antialiases <- get("antialiases", envir = .X11env)
    if(!missing(antialias))
        new$antialias <- match.arg(antialias, antialiases)
    d <- check.options(new, name.opt = ".X11.Options", envir = .X11env)
    antialias <- match(d$antialias, antialiases)
    ## do these separately so can remove from X11 module in due course
    if(type == "quartz" && capabilities("aqua")) {
        width <- width/ifelse(is.na(res), 72, res);
        height <- height/ifelse(is.na(res), 72, res);
        invisible(.External(CQuartz, "png", path.expand(filename), width, height,
                            pointsize, "Helvetica", TRUE, TRUE, "", bg,
                            "white", if(is.na(res)) NULL else res))
    } else if (type == "cairo" && capabilities("cairo"))
        .Internal(cairo(filename, 2L, width, height, pointsize, bg,
			res, antialias, 100L))
    else
        .Internal(X11(paste("png::", filename, sep=""),
                      width, height, pointsize, d$gamma,
                      d$colortype, d$maxcubesize, bg, bg, d$fonts, res,
                      0L, 0L, "", 0, 0))
}

jpeg <- function(filename = "Rplot%03d.jpeg",
                 width = 480, height = 480, units = "px",
                 pointsize = 12, quality = 75,
                 bg = "white", res = NA, ...,
                 type = c("cairo", "Xlib", "quartz"), antialias)
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    units <- match.arg(units, c("in", "px", "cm", "mm"))
    if(units != "px" && is.na(res))
        stop("'res' must be specified unless 'units = \"px\"'")
    height <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * height
    width <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * width
    new <- list(...)
    if(!missing(type)) new$type <- match.arg(type)
    antialiases <- get("antialiases", envir = .X11env)
    if(!missing(antialias))
        new$antialias <- match.arg(antialias, antialiases)
    d <- check.options(new, name.opt = ".X11.Options", envir = .X11env)
    ## do this separately so can remove from X11 module in due course
    if(type == "quartz" && capabilities("aqua")) {
        width <- width/ifelse(is.na(res), 72, res);
        height <- height/ifelse(is.na(res), 72, res);
        invisible(.External(CQuartz, "jpeg", path.expand(filename), width, height,
                            pointsize, "Helvetica", TRUE, TRUE, "", bg,
                            "white", if(is.na(res)) NULL else res))
    } else if (type == "cairo" && capabilities("cairo"))
        .Internal(cairo(filename, 3L, width, height, pointsize, bg,
			res, match(d$antialias, antialiases), quality))
    else
        .Internal(X11(paste("jpeg::", quality, ":", filename, sep=""),
                      width, height, pointsize, d$gamma,
                      d$colortype, d$maxcubesize, bg, bg, d$fonts, res,
                      0L, 0L, "", 0, 0))
}

tiff <- function(filename = "Rplot%03d.tiff",
                 width = 480, height = 480, units = "px", pointsize = 12,
                 compression = c("none", "rle", "lzw", "jpeg", "zip"),
                 bg = "white", res = NA, ...,
                 type = c("cairo", "Xlib", "quartz"), antialias)
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    units <- match.arg(units, c("in", "px", "cm", "mm"))
    if(units != "px" && is.na(res))
        stop("'res' must be specified unless 'units = \"px\"'")
    height <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * height
    width <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * width
    new <- list(...)
    type <- if(!missing(type)) match.arg(type) else getOption("bitmapType")
    antialiases <- get("antialiases", envir = .X11env)
    if(!missing(antialias))
        new$antialias <- match.arg(antialias, antialiases)
    d <- check.options(new, name.opt = ".X11.Options", envir = .X11env)
    comp <- switch( match.arg(compression),
                   "none" = 1, "rle" = 2, "lzw" = 5, "jpeg" = 7, "zip" = 8)
    if(type == "quartz" && capabilities("aqua")) {
        width <- width/ifelse(is.na(res), 72, res);
        height <- height/ifelse(is.na(res), 72, res);
        invisible(.External(CQuartz, "tiff", path.expand(filename), width, height,
                            pointsize, "Helvetica", TRUE, TRUE, "", bg,
                            "white", if(is.na(res)) NULL else res))
    } else if (type == "cairo" && capabilities("cairo"))
        .Internal(cairo(filename, 8L, width, height, pointsize, bg,
			res, match(d$antialias, antialiases), comp))
    else
        .Internal(X11(paste("tiff::", comp, ":", filename, sep=""),
                      width, height, pointsize, d$gamma,
                      d$colortype, d$maxcubesize, bg, bg, d$fonts, res,
                      0L, 0L, "", 0, 0))
}

bmp <- function(filename = "Rplot%03d.bmp",
                width = 480, height = 480, units = "px", pointsize = 12,
                bg = "white", res = NA, ...,
                type = c("cairo", "Xlib", "quartz"), antialias)
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    units <- match.arg(units, c("in", "px", "cm", "mm"))
    if(units != "px" && is.na(res))
        stop("'res' must be specified unless 'units = \"px\"'")
    height <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * height
    width <-
        switch(units, "in"=res, "cm"=res/2.54, "mm"=res/25.4, "px"=1) * width
    new <- list(...)
    type <- if(!missing(type)) match.arg(type) else getOption("bitmapType")
    antialiases <- get("antialiases", envir = .X11env)
    if(!missing(antialias))
        new$antialias <- match.arg(antialias, antialiases)
    d <- check.options(new, name.opt = ".X11.Options", envir = .X11env)
    if(type == "quartz" && capabilities("aqua")) {
        width <- width/ifelse(is.na(res), 72, res);
        height <- height/ifelse(is.na(res), 72, res);
        invisible(.External(CQuartz, "bmp", path.expand(filename), width, height,
                            pointsize, "Helvetica", TRUE, TRUE, "", bg,
                            "white", if(is.na(res)) NULL else res))
    } else if (type == "cairo" && capabilities("cairo"))
        .Internal(cairo(filename, 9L, width, height, pointsize, bg,
			res, match(d$antialias, antialiases), 100L))
    else
        .Internal(X11(paste("bmp::", filename, sep=""),
                      width, height, pointsize, d$gamma,
                      d$colortype, d$maxcubesize, bg, bg, d$fonts, res,
                      0L, 0L, "", 0, 0))
}

svg <- function(filename = if(onefile) "Rplots.svg" else "Rplot%03d.svg",
                width = 7, height = 7, pointsize = 12,
                onefile = FALSE, bg = "white",
                antialias = c("default", "none", "gray", "subpixel"))
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    new <- list()
    antialiases <- eval(formals()$antialias)
    antialias <- match(match.arg(antialias, antialiases), antialiases)
    .Internal(cairo(filename, 4L, 72*width, 72*height, pointsize, bg,
                    NA_integer_, antialias, onefile))
}

cairo_pdf <- function(filename = if(onefile) "Rplots.pdf" else "Rplot%03d.pdf",
                      width = 7, height = 7, pointsize = 12,
                      onefile = FALSE, bg = "white",
                      antialias = c("default", "none", "gray", "subpixel"))
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    antialiases <- eval(formals()$antialias)
    antialias <- match(match.arg(antialias, antialiases), antialiases)
    .Internal(cairo(filename, 6L, 72*width, 72*height, pointsize, bg,
                    NA_integer_, antialias, onefile))
}

cairo_ps <- function(filename = if(onefile) "Rplots.ps" else "Rplot%03d.ps",
                     width = 7, height = 7, pointsize = 12,
                     onefile = FALSE, bg = "white",
                     antialias = c("default", "none", "gray", "subpixel"))
{
    if(!checkIntFormat(filename)) stop("invalid 'filename'")
    antialiases <- eval(formals()$antialias)
    antialias <- match(match.arg(antialias, antialiases), antialiases)
    .Internal(cairo(filename, 7L, 72*width, 72*height, pointsize, bg,
                    NA_integer_, antialias, onefile))
}

####################
# X11 font database
####################

# Each font family has a name, plus a vector of 4 or 5 directories
# for font metric afm files
assign(".X11.Fonts", list(), envir = .X11env)

X11FontError <- function(errDesc)
    stop("invalid X11 font specification: ", errDesc)


# Check that the font has the correct structure and information
# Already checked that it had a name
checkX11Font <- function(font)
{
    if (!is.character(font))
        X11FontError("must be a string")
    ## Check it has the right format
    if (length(grep("(-[^-]+){14}", font)) > 0) {
        ## Force the %s and %d substitution formats into the right spots
        font <- sub("((-[^-]+){2})(-[^-]+){2}((-[^-]+){2})(-[^-]+)((-[^-]+){7})",
                    "\\1-%s-%s\\4-%d\\7", font)
    } else {
        X11FontError("incorrect format")
    }
    font
}

setX11Fonts <- function(fonts, fontNames)
{
    fonts <- lapply(fonts, checkX11Font)
    fontDB <- get(".X11.Fonts", envir=.X11env)
    existingFonts <- fontNames %in% names(fontDB)
    if (sum(existingFonts) > 0)
        fontDB[fontNames[existingFonts]] <- fonts[existingFonts]
    if (sum(existingFonts) < length(fontNames))
        fontDB <- c(fontDB, fonts[!existingFonts])
    assign(".X11.Fonts", fontDB, envir=.X11env)
}

printFont <- function(font) paste(font, "\n", sep="")


printFonts <- function(fonts)
    cat(paste(names(fonts), ": ", unlist(lapply(fonts, printFont)),
              sep="", collapse=""))

# If no arguments spec'ed, return entire font database
# If no named arguments spec'ed, all args should be font names
# to get info on from the database
# Else, must specify new fonts to enter into database (all
# of which must be valid X11 font descriptions and
# all of which must be named args)
X11Fonts <- function(...)
{
    ndots <- length(fonts <- list(...))
    if (ndots == 0)
        get(".X11.Fonts", envir=.X11env)
    else {
        fontNames <- names(fonts)
        nnames <- length(fontNames)
        if (nnames == 0) {
            if (!all(sapply(fonts, is.character)))
                stop(gettextf("invalid arguments in '%s' (must be font names)",
                              "X11Fonts"), domain = NA)
            else
                get(".X11.Fonts", envir=.X11env)[unlist(fonts)]
        } else {
            if (ndots != nnames)
                stop(gettextf("invalid arguments in '%s' (need named args)",
                              "X11Fonts"), domain = NA)
            setX11Fonts(fonts, fontNames)
        }
    }
}

# Create a valid X11 font description
X11Font <- function(font) checkX11Font(font)

X11Fonts(# Default Serif font is Times
         serif=X11Font("-*-times-%s-%s-*-*-%d-*-*-*-*-*-*-*"),
         # Default Sans Serif font is Helvetica
         sans=X11Font("-*-helvetica-%s-%s-*-*-%d-*-*-*-*-*-*-*"),
         # Default Monospace font is Courier
         mono=X11Font("-*-courier-%s-%s-*-*-%d-*-*-*-*-*-*-*"))

savePlot <- function(filename = paste("Rplot", type, sep="."),
                     type = c("png", "jpeg", "tiff", "bmp"),
                     device = dev.cur())
{
    type <- match.arg(type)
    devlist <- dev.list()
    devcur <- match(device, devlist, NA)
    if(is.na(devcur)) stop("no such device")
    devname <- names(devlist)[devcur]
    if(devname != "X11cairo")
        stop("can only copy from 'X11(type=\"*cairo\")' devices")
    .Internal(savePlot(filename, type, device))
}
