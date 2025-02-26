#  File src/library/base/R/source.R
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

source <-
function(file, local = FALSE, echo = verbose, print.eval = echo,
	 verbose = getOption("verbose"),
	 prompt.echo = getOption("prompt"),
	 max.deparse.length = 150, chdir = FALSE,
         encoding = getOption("encoding"),
         continue.echo = getOption("continue"),
         skip.echo = 0, keep.source = getOption("keep.source"))
{
    ## eval.with.vis is retained for historical reasons, including
    ## not changing tracebacks.
    ## Use withVisible(eval(...)) for less critical applications.
    ## A one line change is marked around line 166 to use it here as well.
    eval.with.vis <-
	function (expr, envir = parent.frame(),
		  enclos = if (is.list(envir) || is.pairlist(envir))
		  parent.frame() else baseenv())
	.Internal(eval.with.vis(expr, envir, enclos))

    envir <- if (local) parent.frame() else .GlobalEnv
    have_encoding <- !missing(encoding) && encoding != "unknown"
    if (!missing(echo)) {
	if (!is.logical(echo))
	    stop("'echo' must be logical")
	if (!echo && verbose) {
	    warning("'verbose' is TRUE, 'echo' not; ... coercing 'echo <- TRUE'")
	    echo <- TRUE
	}
    }
    if (verbose) {
	cat("'envir' chosen:")
	print(envir)
    }
    ofile <- file # for use with chdir = TRUE
    from_file <- FALSE
    srcfile <- NULL
    if(is.character(file)) {
        if(identical(encoding, "unknown")) {
            enc <- utils::localeToCharset()
            encoding <- enc[length(enc)]
        } else enc <- encoding
        if(length(enc) > 1L) {
            encoding <- NA
            owarn <- options("warn"); options(warn = 2)
            for(e in enc) {
                if(is.na(e)) next
                zz <- file(file, encoding = e)
                res <- tryCatch(readLines(zz), error = identity)
                close(zz)
                if(!inherits(res, "error")) { encoding <- e; break }
            }
            options(owarn)
        }
        if(is.na(encoding))
            stop("unable to find a plausible encoding")
        if(verbose)
            cat(gettextf('encoding = "%s" chosen', encoding), "\n", sep = "")
        if(file == "") file <- stdin()
        else {
            if (isTRUE(keep.source))
            	srcfile <- srcfile(file, encoding = encoding)
	    file <- file(file, "r", encoding = encoding)
	    on.exit(close(file))
            from_file <- TRUE
            ## We translated the file (possibly via a guess),
            ## so don't want to mark the strings.as from that encoding
            ## but we might know what we have encoded to, so
            loc <- utils::localeToCharset()[1L]
            encoding <- if(have_encoding)
                switch(loc,
                       "UTF-8" = "UTF-8",
                       "ISO8859-1" = "latin1",
                       "unknown")
            else "unknown"
	}
    }
    exprs <- .Internal(parse(file, n = -1, NULL, "?", srcfile, encoding))
    Ne <- length(exprs)
    if (from_file) { # we are done with the file now
        close(file)
        on.exit()
    }
    if (verbose)
	cat("--> parsed", Ne, "expressions; now eval(.)ing them:\n")

    if (chdir){
        if(is.character(ofile)) {
            isURL <- length(grep("^(ftp|http|file)://", ofile)) > 0L
            if(isURL)
                warning("'chdir = TRUE' makes no sense for a URL")
            if(!isURL && (path <- dirname(ofile)) != ".") {
                owd <- getwd()
                if(is.null(owd))
                    stop("cannot 'chdir' as current directory is unknown")
                on.exit(setwd(owd), add=TRUE)
                setwd(path)
            }
        } else {
            warning("'chdir = TRUE' makes no sense for a connection")
        }
    }

    if (echo) {
	## Reg.exps for string delimiter/ NO-string-del /
	## odd-number-of-str.del needed, when truncating below
	sd <- "\""
	nos <- "[^\"]*"
	oddsd <- paste("^", nos, sd, "(", nos, sd, nos, sd, ")*",
		       nos, "$", sep = "")
        ## A helper function for echoing source.  This is simpler than the
        ## same-named one in Sweave
	trySrcLines <- function(srcfile, showfrom, showto) {
	    lines <- try(suppressWarnings(getSrcLines(srcfile, showfrom, showto)), silent=TRUE)
	    if (inherits(lines, "try-error")) 
    	    	lines <- character(0)
    	    lines
	}	       
    }
    yy <- NULL
    lastshown <- 0
    srcrefs <- attr(exprs, "srcref")
    for (i in seq_len(Ne+echo)) {
    	tail <- i > Ne
        if (!tail) {
	    if (verbose)
		cat("\n>>>> eval(expression_nr.", i, ")\n\t	 =================\n")
	    ei <- exprs[i]
	}
	if (echo) {
	    srcref <- NULL
	    nd <- 0
	    if (tail)
	    	srcref <- attr(exprs, "wholeSrcref")
	    else if (i <= length(srcrefs))
	    	srcref <- srcrefs[[i]]
 	    if (!is.null(srcref)) {
	    	if (i == 1) lastshown <- min(skip.echo, srcref[3L]-1)
	    	if (lastshown < srcref[3L]) {
	    	    srcfile <- attr(srcref, "srcfile")
	    	    dep <- trySrcLines(srcfile, lastshown+1, srcref[3L])
	    	    if (length(dep)) {
			if (tail)
			    leading <- length(dep)
			else
			    leading <- srcref[1L]-lastshown
			lastshown <- srcref[3L]
			while (length(dep) && length(grep("^[[:blank:]]*$", dep[1L]))) {
			    dep <- dep[-1L]
			    leading <- leading - 1L
			}
			dep <- paste(rep.int(c(prompt.echo, continue.echo), c(leading, length(dep)-leading)),
				    dep, sep="", collapse="\n")
			nd <- nchar(dep, "c")
		    } else
		    	srcref <- NULL  # Give up and deparse
	    	}
	    }
	    if (is.null(srcref)) {
	    	if (!tail) {
		    # Deparse.  Must drop "expression(...)"
		    dep <- substr(paste(deparse(ei, control = "showAttributes"),
			      collapse = "\n"), 12L, 1e+06L)
		    ## We really do want chars here as \n\t may be embedded.
		    dep <- paste(prompt.echo,
				 gsub("\n", paste("\n", continue.echo, sep=""), dep),
				 sep="")
		    nd <- nchar(dep, "c") - 1L
		}
	    }	    
	    if (nd) {
		do.trunc <- nd > max.deparse.length
		dep <- substr(dep, 1L, if (do.trunc) max.deparse.length else nd)
		cat("\n", dep, if (do.trunc)
		    paste(if (length(grep(sd, dep)) && length(grep(oddsd, dep)))
		      " ...\" ..."
		      else " ....", "[TRUNCATED] "), "\n", sep = "")
	    }
	}
	if (!tail) {
###  Switch comment below get rid of eval.with.vis
	    yy <- eval.with.vis(ei, envir)
###	    yy <- withVisible(eval(ei, envir))
	    i.symbol <- mode(ei[[1L]]) == "name"
	    if (!i.symbol) {
		## ei[[1L]] : the function "<-" or other
		curr.fun <- ei[[1L]][[1L]]
		if (verbose) {
		    cat("curr.fun:")
		    utils::str(curr.fun)
		}
	    }
	    if (verbose >= 2) {
		cat(".... mode(ei[[1L]])=", mode(ei[[1L]]), "; paste(curr.fun)=")
		utils::str(paste(curr.fun))
	    }
	    if (print.eval && yy$visible) {
		if(isS4(yy$value))
		    methods::show(yy$value)
		else
		    print(yy$value)
	    }
	    if (verbose)
		cat(" .. after ", sQuote(deparse(ei,
		    control = c("showAttributes","useSource"))), "\n", sep = "")
 	}
    }
    invisible(yy)
}

sys.source <-
function(file, envir = baseenv(), chdir = FALSE,
	 keep.source = getOption("keep.source.pkgs"))
{
    if(!(is.character(file) && file.exists(file)))
	stop(gettextf("'%s' is not an existing file", file))
    oop <- options(keep.source = as.logical(keep.source),
		   topLevelEnvironment = as.environment(envir))
    on.exit(options(oop))
    exprs <- parse(n = -1, file = file)
    if (length(exprs) == 0L)
	return(invisible())
    if (chdir && (path <- dirname(file)) != ".") {
	owd <- getwd()
        if(is.null(owd))
            stop("cannot 'chdir' as current directory is unknown")
	on.exit(setwd(owd), add = TRUE)
	setwd(path)
    }
    for (i in exprs) eval(i, envir)
    invisible()
}
