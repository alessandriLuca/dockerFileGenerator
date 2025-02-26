#  File src/library/utils/R/Sweave.R
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

### The drivers are now in SweaveDrivers.R

### FIXMEs
### a) User-defined options are unclear: all options not already specified
### are required to be logical
### b) It would be nice to allow multiple 'grdevice' options

### Encodings (currently, different from 2.13.0)
###
### SweaveReadFile figures out an encoding, uses it (not currently for
### \SweaveInclude files) and returns it as an attribute.  This is
### then passed as an attribute of 'file' to the driver's setup
### routine.  Unless it is "" or "ASCII", the RweaveLatex driver
### re-encodes the output back to 'encoding': the Rtangle driver
### leaves it in the encoding of the current locale and records what
### that is in a comment.
###
### SweaveReadFile first looks for a call to one of the LaTeX packages
### inputen[cx] and deduces the vignette encoding from that, falling
### back to the package encoding, then Latin-1 (with a warning).  This
### should work OK provided the package encoding is Latin-1: it is
### UTF-8 then LaTeX needs to be told what to do.  It also assumes
### that R output is in the current locale: a package with a different
### encoding from the current one might have data in that package's
### encoding.

### Correspondence between input and output is maintained in two
### places: Each chunk has a srclines attribute, recording the input
### lines it corresponds to.  Each code chunk will have attached
### srcrefs that duplicate the srclines.  We don't need srclines for
### code, but we do need it for doc chunks, and it's easiest to just
### keep it for everything.



Stangle <- function(file, driver = Rtangle(),
                    syntax = getOption("SweaveSyntax"),
                    encoding = "", ...)
    Sweave(file = file, driver = driver, encoding = encoding, ...)

Sweave <- function(file, driver = RweaveLatex(),
                   syntax = getOption("SweaveSyntax"),
                   encoding = "", ...)
{
    if (is.character(driver)) driver <- get(driver, mode = "function")()
    else if (is.function(driver)) driver <- driver()

    if (is.null(syntax)) syntax <- SweaveGetSyntax(file) # from the extension
    if (is.character(syntax)) syntax <- get(syntax, mode = "list")

    if (.Platform$OS.type == "windows") file <- chartr("\\", "/", file)

    text <- SweaveReadFile(file, syntax, encoding = encoding)
    attr(file, "encoding") <- encoding <- attr(text, "encoding")

    ## drobj$options is the current set of options for this file.
    drobj <- driver$setup(file = file, syntax = syntax, ...)
    on.exit(driver$finish(drobj, error = TRUE))

    syntax <- attr(text, "syntax") # this is from the file commands.

    if (!is.na(envopts <- Sys.getenv("SWEAVE_OPTIONS", NA)))
        drobj$options <-
            SweaveParseOptions(envopts, drobj$options, driver$checkopts)

    drobj$filename <- file
    drobj$hasSweaveInput <- attr(text, "hasSweaveInput")

    mode <- "doc"
    chunknr <- 0L
    chunk <- NULL
    chunkopts <- NULL

    namedchunks <- list()
    for (linenum in seq_along(text)) {
    	line <- text[linenum]
        if (length(grep(syntax$doc, line))) { # start new documentation chunk
            if (mode == "doc") {
                if (!is.null(chunk)) drobj <- driver$writedoc(drobj, chunk)
            } else {
                if (!is.null(chunkopts$label))
                    namedchunks[[chunkopts$label]] <- chunk
                if (!is.null(chunk))
                    drobj <- driver$runcode(drobj, chunk, chunkopts)
                mode <- "doc"
            }
            chunk <- NULL
        } else if (length(grep(syntax$code, line))) { # start new code chunk
            if (mode == "doc") {
                if (!is.null(chunk)) drobj <- driver$writedoc(drobj, chunk)
            } else {
                if (!is.null(chunkopts$label))
                    namedchunks[[chunkopts$label]] <- chunk
                if (!is.null(chunk))
                    drobj <- driver$runcode(drobj, chunk, chunkopts)
            }
            mode <- "code"
            chunkopts <- sub(syntax$code, "\\1", line)
            chunkopts <- SweaveParseOptions(chunkopts,
                                            drobj$options,
                                            driver$checkopts)
            ## these #line directives are used for error messages when parsing
            chunk <- paste("#line ", linenum+1L, ' "',
                           basename(file), '"', sep="")
            attr(chunk, "srclines") <- linenum
            chunknr <- chunknr + 1L  # this is really 'code chunk number'
            chunkopts$chunknr <- chunknr
        } else {  # continuation of current chunk
            if (mode == "code" && length(grep(syntax$coderef, line))) {
                chunkref <- sub(syntax$coderef, "\\1", line)
                if (!(chunkref %in% names(namedchunks))) {
                    ## omit unknown references
                    warning(gettextf("reference to unknown chunk %s",
                                     sQuote(chunkref)),
                            call. = TRUE,domain = NA)
                    next
                } else {
                    ## these #line directives are used for error messages
                    ## when parsing
                    line <- c(namedchunks[[chunkref]],
                              paste("#line ", linenum+1L, ' "',
                                    basename(file), '"', sep=""))
                }
            }
            srclines <- c(attr(chunk, "srclines"), rep(linenum, length(line)))
	    chunk <- c(chunk, line)
            attr(chunk, "srclines") <- srclines
	}
    }
    if (!is.null(chunk)) { # write out final chunk
	drobj <-
	    if (mode == "doc") driver$writedoc(drobj, chunk)
	    else driver$runcode(drobj, chunk, chunkopts)
    }

    on.exit() # clear action to finish with error = TRUE
    driver$finish(drobj)
}

SweaveReadFile <- function(file, syntax, encoding = "")
{
    ## file can be a vector to keep track of recursive calls to
    ## SweaveReadFile.  In this case only the first element is
    ## tried to read in, the rest are forbidden names for further
    ## SweaveInput
    f <- file[1L]

    bf <- basename(f)
    df <- dirname(f)
    if (!file.exists(f)) {
        f <- list.files(df, full.names = TRUE,
                        pattern = paste(bf, syntax$extension, sep = ""))

        if (length(f) == 0L)
            stop(gettextf("no Sweave file with name '%s' found", file[1L]),
                 domain = NA)
        else if (length(f) > 1L)
            stop(paste(gettextf("%d Sweave files for basename '%s' found:",
                                length(f), file),
                       paste("\n         ", f, collapse="")),
                 domain = NA)
    }

    ## An incomplete last line is not a real problem.
    text <- readLines(f[1L], warn = FALSE)

    if (encoding != "bytes")  {
        ## now sort out an encoding, if needed.
        enc <- tools:::.getVignetteEncoding(text, convert = TRUE)
        if (enc == "non-ASCII") {
            enc <- if (nzchar(encoding)) {
                encoding
            } else {
                warning(sQuote(basename(file)),
                        " has unknown encoding: assuming Latin-1",
                        domain = NA, call. = FALSE)
                "latin1"
            }
        } else if (enc == "unknown") {
            stop(sQuote(basename(file)),
                 " declares an encoding that Sweave does not know about",
                 domain = NA, call. = FALSE)
        }
        if (nzchar(enc)) text <- iconv(text, enc, "") else enc <- "ASCII"
    } else enc <- "bytes"

    pos <- grep(syntax$syntaxname, text)

    if (length(pos) > 1L)
        warning(gettextf("more than one syntax specification found, using the first one"), domain = NA)

    if (length(pos) > 0L) {
        sname <- sub(syntax$syntaxname, "\\1", text[pos[1L]])
        syntax <- get(sname, mode = "list")
        if (class(syntax) != "SweaveSyntax")
            stop(gettextf("object '%s' does not have class \"SweaveSyntax\"",
                          sname), domain = NA)
        text <- text[-pos]
    }

    if (!is.null(syntax$input)) {
        while(length(pos <- grep(syntax$input, text))) {
            pos <- pos[1L]
            ifile <- file.path(df, sub(syntax$input, "\\1", text[pos]))
            if (any(ifile == file)) {
                stop(paste(gettextf("recursive Sweave input '%s' in stack", ifile),
                           paste("\n         ", seq_len(file), ": ",
                                 rev(file), collapse="")),
                 domain = NA)
            }
            itext <- SweaveReadFile(c(ifile, file), syntax, encoding = encoding)

	    text <-
		if (pos == 1L) c(itext, text[-pos])
		else if (pos == length(text)) c(text[-pos], itext)
		else
		    c(text[seq_len(pos-1L)], itext, text[(pos+1L):length(text)])
            attr(text, "hasSweaveInput") <- TRUE
        }
    }

    attr(text, "syntax") <- syntax
    attr(text, "file") <- f[1L]
    attr(text, "encoding") <- enc
    text
}



###**********************************************************

SweaveSyntaxNoweb <-
    list(doc = "^@",
         code = "^<<(.*)>>=.*",
         coderef = "^<<(.*)>>.*",
         docopt = "^[[:space:]]*\\\\SweaveOpts\\{([^\\}]*)\\}",
         docexpr = "\\\\Sexpr\\{([^\\}]*)\\}",
         extension = "\\.[rsRS]?nw$",
         syntaxname = "^[[:space:]]*\\\\SweaveSyntax\\{([^\\}]*)\\}",
         input = "^[[:space:]]*\\\\SweaveInput\\{([^\\}]*)\\}",
         trans = list(
             doc = "@",
             code = "<<\\1>>=",
             coderef = "<<\\1>>",
             docopt = "\\\\SweaveOpts{\\1}",
             docexpr = "\\\\Sexpr{\\1}",
             extension = ".Snw",
             syntaxname = "\\\\SweaveSyntax{SweaveSyntaxNoweb}",
             input = "\\\\SweaveInput{\\1}")
         )

class(SweaveSyntaxNoweb) <- "SweaveSyntax"

SweaveSyntaxLatex <- SweaveSyntaxNoweb
SweaveSyntaxLatex$doc <-  "^[[:space:]]*\\\\end\\{Scode\\}"
SweaveSyntaxLatex$code <- "^[[:space:]]*\\\\begin\\{Scode\\}\\{?([^\\}]*)\\}?.*"
SweaveSyntaxLatex$coderef <- "^[[:space:]]*\\\\Scoderef\\{([^\\}]*)\\}.*"
SweaveSyntaxLatex$extension <- "\\.[rsRS]tex$"

SweaveSyntaxLatex$trans$doc <-  "\\\\end{Scode}"
SweaveSyntaxLatex$trans$code <- "\\\\begin{Scode}{\\1}"
SweaveSyntaxLatex$trans$coderef <- "\\\\Scoderef{\\1}"
SweaveSyntaxLatex$trans$syntaxname <- "\\\\SweaveSyntax{SweaveSyntaxLatex}"
SweaveSyntaxLatex$trans$extension <- ".Stex"

SweaveGetSyntax <- function(file)
{
    synt <- apropos("SweaveSyntax", mode = "list")
    for (sname in synt) {
        s <- get(sname, mode = "list")
        if (class(s) != "SweaveSyntax") next
        if (length(grep(s$extension, file))) return(s)
    }
    SweaveSyntaxNoweb
}


SweaveSyntConv <- function(file, syntax, output=NULL)
{
    if (is.character(syntax)) syntax <- get(syntax)

    if (class(syntax) != "SweaveSyntax")
        stop("target syntax not of class \"SweaveSyntax\"")

    if (is.null(syntax$trans))
        stop("target syntax contains no translation table")

    insynt <- SweaveGetSyntax(file)
    text <- readLines(file)
    if (is.null(output))
        output <- sub(insynt$extension, syntax$trans$extension, basename(file))

    TN <- names(syntax$trans)

    for (n in TN)
        if (n != "extension") text <- gsub(insynt[[n]], syntax$trans[[n]], text)

    cat(text, file = output, sep = "\n")
    cat("Wrote file", output, "\n")
}


###**********************************************************

## parses an option string, from
## - the header of a code chunk
## - an \SweaveOpts{} statement (strangely, left to the drivers)
## - the value of environment variable SWEAVE_OPTIONS
##
## The format is name=value pairs with whitespace being discarded
## (and could have been done all at once).
SweaveParseOptions <- function(text, defaults = list(), check = NULL)
{
    x <- sub("^[[:space:]]*(.*)", "\\1", text)
    x <- sub("(.*[^[:space:]])[[:space:]]*$", "\\1", x)
    x <- unlist(strsplit(x, "[[:space:]]*,[[:space:]]*"))
    x <- strsplit(x, "[[:space:]]*=[[:space:]]*")

    ## only the first option may have no name: the chunk label
    if (length(x)) {
        if (length(x[[1L]]) == 1L) x[[1L]] <- c("label", x[[1L]])
    } else return(defaults)

    if (any(sapply(x, length) != 2L))
        stop(gettextf("parse error or empty option in\n%s", text), domain = NA)

    options <- defaults
    for (k in seq_along(x)) options[[ x[[k]][1L] ]] <- x[[k]][2L]

    ## This is undocumented
    if (!is.null(options[["label"]]) && !is.null(options[["engine"]]))
        options[["label"]] <-
            sub(paste("\\.", options[["engine"]], "$", sep=""),
                "", options[["label"]])

    if (!is.null(check)) check(options) else options
}

## really part of the RweaveLatex and Rtangle drivers
SweaveHooks <- function(options, run = FALSE, envir = .GlobalEnv)
{
    if (is.null(SweaveHooks <- getOption("SweaveHooks"))) return(NULL)

    z <- character()
    for (k in names(SweaveHooks))
        if (nzchar(k) && is.logical(options[[k]]) && options[[k]])
            if (is.function(SweaveHooks[[k]])) {
                z <- c(z, k)
                if (run) eval(SweaveHooks[[k]](), envir=envir)
            }
    z # a character vector.
}


## For R CMD xxxx
.Sweave <- function(arg = NULL)
{
    options(warn = 1)
    if (is.null(arg)) {
        arg <- commandArgs(TRUE)
        arg <- paste(arg, collapse=" ")
        arg <- strsplit(arg,'nextArg', fixed = TRUE)[[1L]][-1L]
    }

    Usage <- function() {
        cat("Usage: R CMD Sweave file",
            "",
            "A simple front-end for Sweave",
            "",
            "Options:",
            "  -h, --help     print this help message and exit",
            "  -v, --version  print version info and exit",
            "",
            "Report bugs to <r-bugs@r-project.org>.",
            sep = "\n")
    }
    do_exit <- function(status = 0L)
        q("no", status = status, runLast = FALSE)

    if (length(arg) != 1L) { Usage(); do_exit(1L) }
    if (arg %in% c("-h", "--help")) { Usage(); do_exit() }
    if (arg %in% c("-v", "--version")) {
        cat("Sweave front-end: ",
            R.version[["major"]], ".",  R.version[["minor"]],
            " (r", R.version[["svn rev"]], ")\n", sep = "")
        cat("",
            "Copyright (C) 2006-2011 The R Core Development Team.",
            "This is free software; see the GNU General Public License version 2",
            "or later for copying conditions.  There is NO warranty.",
            sep = "\n")
        do_exit()
    }
    Sweave(arg)
    do_exit()
}

.Stangle <- function(arg = NULL)
{
    options(warn = 1)
    if (is.null(arg)) {
        arg <- commandArgs(TRUE)
        arg <- paste(arg, collapse=" ")
        arg <- strsplit(arg,'nextArg', fixed = TRUE)[[1L]][-1L]
    }

    Usage <- function() {
        cat("Usage: R CMD Stangle file",
            "",
            "A simple front-end for Stangle",
            "",
            "Options:",
            "  -h, --help     print this help message and exit",
            "  -v, --version  print version info and exit",
            "",
            "Report bugs to <r-bugs@r-project.org>.",
            sep = "\n")
    }
    do_exit <- function(status = 0L)
        q("no", status = status, runLast = FALSE)

    if (length(arg) != 1L) { Usage(); do_exit(1L) }
    if (arg %in% c("-h", "--help")) { Usage(); do_exit() }
    if (arg %in% c("-v", "--version")) {
        cat("Stangle front-end: ",
            R.version[["major"]], ".",  R.version[["minor"]],
            " (r", R.version[["svn rev"]], ")\n", sep = "")
        cat("",
            "Copyright (C) 2006-2011 The R Core Development Team.",
            "This is free software; see the GNU General Public License version 2",
            "or later for copying conditions.  There is NO warranty.",
            sep = "\n")
        do_exit()
    }
    Stangle(arg)
    do_exit()
}
