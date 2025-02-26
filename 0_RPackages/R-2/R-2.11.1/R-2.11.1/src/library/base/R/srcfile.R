#  File src/library/base/R/srcfile.R
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

# a srcfile is a file with a timestamp

srcfile <- function(filename, encoding = getOption("encoding"), Enc = "unknown")
{
    stopifnot(is.character(filename), length(filename) == 1L)

    e <- new.env(parent=emptyenv())

    e$wd <- getwd()
    e$filename <- filename

    # If filename is a URL, this will return NA
    e$timestamp <- file.info(filename)[1,"mtime"]

    if (identical(encoding, "unknown")) encoding <- "native.enc"
    e$encoding <- encoding
    e$Enc <- Enc

    class(e) <- "srcfile"
    return(e)
}

print.srcfile <- function(x, ...) {
    cat(x$filename, "\n")
    invisible(x)
}

summary.srcfile <- function(object, ...) {
    cat(utils:::.normalizePath(object$filename, object$wd), "\n")
    
    if (inherits(object$timestamp, "POSIXt"))
    	cat("Timestamp: ", format(object$timestamp, usetz=TRUE), "\n", sep="")
    
    cat('Encoding: "', object$encoding, '"', sep="")
    if (!is.null(object$Enc) && object$Enc != object$encoding && object$Enc != "unknown")
    	cat(', re-encoded to "', object$Enc, '"', sep="")
    cat("\n")
    
    invisible(object)
}

open.srcfile <- function(con, line, ...) {

    srcfile <- con

    oldline <- srcfile$line
    if (!is.null(oldline) && oldline > line) close(srcfile)

    conn <- srcfile$conn
    if (is.null(conn)) {
        if (!is.null(srcfile$wd)) {
	    olddir <- setwd(srcfile$wd)
	    on.exit(setwd(olddir))
	}
	timestamp <- file.info(srcfile$filename)[1,"mtime"]
	if (!is.null(srcfile$timestamp)
	    && !is.na(srcfile$timestamp)
	    && ( is.na(timestamp) || timestamp != srcfile$timestamp) )
	    warning("Timestamp of '",srcfile$filename,"' has changed", call.=FALSE)
	if (is.null(srcfile$encoding)) encoding <- getOption("encoding")
	else encoding <- srcfile$encoding
	# Specifying encoding below means that reads will convert to the native encoding
	srcfile$conn <- conn <- file(srcfile$filename, open="rt", encoding=encoding)
	srcfile$line <- 1L
	oldline <- 1L
    } else if (!isOpen(conn)) {
	open(conn, open="rt")
	srcfile$line <- 1
	oldline <- 1L
    }
    if (oldline < line) {
	readLines(conn, line - oldline, warn = FALSE)
	srcfile$line <- line
    }
    invisible(conn)
}

close.srcfile <- function(con, ...) {
    srcfile <- con
    conn <- srcfile$conn
    if (is.null(conn)) return()
    else {
	close(conn)
	rm(list=c("conn", "line"), envir=srcfile)
    }
}

# srcfilecopy saves a copy of lines from a file

srcfilecopy <- function(filename, lines) {
    stopifnot(is.character(filename), length(filename) == 1L)

    e <- new.env(parent=emptyenv())

    e$filename <- filename
    e$lines <- as.character(lines)
    e$timestamp <- Sys.time()
    e$Enc <- "unknown"

    class(e) <- c("srcfilecopy", "srcfile")
    return(e)
}

open.srcfilecopy <- function(con, line, ...) {

    srcfile <- con

    oldline <- srcfile$line
    if (!is.null(oldline) && oldline > line) close(srcfile)

    conn <- srcfile$conn
    if (is.null(conn)) {
	srcfile$conn <- conn <- textConnection(srcfile$lines, open="r")
	srcfile$line <- 1L
	oldline <- 1L
    } else if (!isOpen(conn)) {
	open(conn, open="r")
	srcfile$line <- 1L
	oldline <- 1L
    }
    if (oldline < line) {
	readLines(conn, line - oldline, warn = FALSE)
	srcfile$line <- line
    }
    invisible(conn)
}

.isOpen <- function(srcfile) {
    conn <- srcfile$conn
    return( !is.null(conn) && isOpen(conn) )
}

getSrcLines <- function(srcfile, first, last) {
    if (first > last) return(character())
    if (!.isOpen(srcfile)) on.exit(close(srcfile))
    conn <- open(srcfile, first)
    lines <- readLines(conn, n = last - first + 1L, warn = FALSE)
    # Re-encode from native encoding to specified one
    if (!is.null(Enc <- srcfile$Enc) && !(Enc %in% c("unknown", "native.enc")))
    	lines <- iconv(lines, "", Enc)
    srcfile$line <- first + length(lines)
    return(lines)
}

# a srcref gives start and stop positions of text
# lloc entries are first_line, first_byte, last_line, last_byte, first_column, last_column
# all are inclusive

srcref <- function(srcfile, lloc) {
    stopifnot(inherits(srcfile, "srcfile"), length(lloc) %in% c(4L,6L))
    if (length(lloc) == 4) lloc <- c(lloc, lloc[2], lloc[4])
    structure(as.integer(lloc), srcfile=srcfile, class="srcref")
}

as.character.srcref <- function(x, useSource = TRUE, ...)
{
    srcfile <- attr(x, "srcfile")
    if (!is.null(srcfile) && !inherits(srcfile, "srcfile")) class(srcfile) <- "srcfile"
    if (useSource) lines <- try(getSrcLines(srcfile, x[1L], x[3L]), TRUE)
    if (!useSource || inherits(lines, "try-error"))
    	lines <- paste("<srcref: file \"", srcfile$filename, "\" chars ",
                       x[1L],":",x[5L], " to ",x[3L],":",x[6L], ">", sep="")
    else {
    	enc <- Encoding(lines)
    	Encoding(lines) <- "latin1"  # so byte counting works
        if (length(lines) < x[3L] - x[1L] + 1L)
            x[4L] <- .Machine$integer.max
    	lines[length(lines)] <- substring(lines[length(lines)], 1L, x[4L])
    	lines[1L] <- substring(lines[1L], x[2L])
    	Encoding(lines) <- enc
    }
    lines
}

print.srcref <- function(x, useSource = TRUE, ...) {
    cat(as.character(x, useSource = useSource), sep="\n")
    invisible(x)
}

summary.srcref <- function(object, useSource = FALSE, ...) {
    cat(as.character(object, useSource = useSource), sep="\n")
    invisible(object)
}
