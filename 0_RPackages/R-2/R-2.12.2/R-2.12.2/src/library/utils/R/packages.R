#  File src/library/utils/R/packages.R
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

available.packages <-
function(contriburl = contrib.url(getOption("repos"), type), method,
         fields = NULL, type = getOption("pkgType"), filters = NULL)
{
    requiredFields <-
        c(tools:::.get_standard_repository_db_fields(), "File")
    if (is.null(fields))
	fields <- requiredFields
    else {
	stopifnot(is.character(fields))
	fields <- unique(c(requiredFields, fields))
    }

    res <- matrix(NA_character_, 0L, length(fields) + 1L,
		  dimnames = list(NULL, c(fields, "Repository")))

    for(repos in contriburl) {
        localcran <- length(grep("^file:", repos)) > 0L
        if(localcran) {
            ## see note in download.packages
            if(substring(repos, 1L, 8L) == "file:///") {
                tmpf <- paste(substring(repos, 8L), "PACKAGES", sep = "/")
                if(.Platform$OS.type == "windows") {
                    if(length(grep("^/[A-Za-z]:", tmpf)))
                        tmpf <- substring(tmpf, 2L)
                }
            } else {
                tmpf <- paste(substring(repos, 6L), "PACKAGES", sep = "/")
            }
            res0 <- read.dcf(file = tmpf)
            if(length(res0)) rownames(res0) <- res0[, "Package"]
        } else {
            dest <- file.path(tempdir(),
                              paste("repos_",
                                    URLencode(repos, TRUE),
                                    ".rds", sep=""))
            if(file.exists(dest)) {
                res0 <- .readRDS(dest)
            } else {
                tmpf <- tempfile()
                on.exit(unlink(tmpf))
                op <- options("warn")
                options(warn = -1)
                ## This is a binary file
                z <- tryCatch(download.file(url = paste(repos, "PACKAGES.gz", sep = "/"),
                                            destfile = tmpf, method = method,
                                            cacheOK = FALSE, quiet = TRUE, mode = "wb"),
                         error = identity)
                if(inherits(z, "error")) {
                    ## read.dcf is going to interpret CRLF as LF, so use
                    ## binary mode to avoid CRCRLF.
                    z <- tryCatch(download.file(url=paste(repos, "PACKAGES", sep = "/"),
                                                destfile = tmpf, method = method,
                                                cacheOK = FALSE, quiet = TRUE,
                                                mode = "wb"),
                             error = identity)
                }
                options(op)
                if(inherits(z, "error")) {
                    warning(gettextf("unable to access index for repository %s", repos),
                            call. = FALSE, immediate. = TRUE, domain = NA)
                    next
                }
                res0 <- read.dcf(file = tmpf)
                if(length(res0)) rownames(res0) <- res0[, "Package"]
                .saveRDS(res0, dest, compress = TRUE)
                unlink(tmpf)
                on.exit()
            } # end of download vs cached
        } # end of localcran vs online
        if (length(res0)) {
            missingFields <- fields[!(fields %in% colnames(res0))]
            if (length(missingFields)) {
                toadd <- matrix(NA_character_, nrow=nrow(res0),
                                ncol=length(missingFields),
                                dimnames=list(NULL, missingFields))
                res0 <- cbind(res0, toadd)
            }
            if ("Path" %in% colnames(res0)) {
                rp <- rep.int(repos, nrow(res0))
                path <- res0[, "Path"]
                rp[!is.na(path)] <- paste(repos, path[!is.na(path)], sep="/")
            } else rp <- repos
            res0 <- cbind(res0[, fields, drop = FALSE], Repository = rp)
            res <- rbind(res, res0)
        }
    }

    if(!length(res)) return(res)

    if(is.null(filters)) {
        filters <- getOption("available_packages_filters")
        if(is.null(filters))
            filters <- available_packages_filters_default
    }
    if(is.list(filters)) {
        ## If filters is a list with an add = TRUE element, add the
        ## given filters to the default ones.
        if(identical(filters$add, TRUE)) {
            filters$add <- NULL
            filters <- c(available_packages_filters_default, filters)
        }
    }
    for(f in filters) {
        if(!length(res)) break
        if(is.character(f)) {
            ## Look up the filters db.
            ## Could be nice and allow abbrevs or ignore case.
            f <- available_packages_filters_db[[f[1L]]]
        }
        if(!is.function(f))
            stop("Invalid 'filters' argument.")
        res <- f(res)
    }

    res
}

available_packages_filters_default <-
    c("R_version", "OS_type", "subarch", "duplicates")

available_packages_filters_db <- new.env()

available_packages_filters_db$R_version <-
function(db)
{
    ## Ignore packages which don't fit our version of R.
    depends <- db[, "Depends"]
    depends[is.na(depends)] <- ""
    ## Collect the (versioned) R depends entries.
    x <- lapply(strsplit(sub("^[[:space:]]*", "", depends),
                             "[[:space:]]*,[[:space:]]*"),
                function(s) s[grepl("^R[[:space:]]*\\(", s)])
    lens <- sapply(x, length)
    pos <- which(lens > 0L)
    if(!length(pos)) return(db)
    lens <- lens[pos]
    ## Unlist.
    x <- unlist(x)
    pat <- "^R[[:space:]]*\\(([[<>=!]+)[[:space:]]+(.*)\\)[[:space:]]*"
    ## Extract ops.
    ops <- sub(pat, "\\1", x)
    ## Split target versions accordings to ops.
    v_t <- split(sub(pat, "\\2", x), ops)
    ## Current R version.
    v_c <- getRversion()
    ## Compare current to target grouped by op.
    res <- logical(length(x))
    for(op in names(v_t))
        res[ops == op] <- do.call(op, list(v_c, v_t[[op]]))
    ## And assemble test results according to the rows of db.
    ind <- rep.int(TRUE, NROW(db))
    ind[pos] <- sapply(split(res, rep.int(seq_along(lens), lens)), all)
    db[ind, , drop = FALSE]
}

available_packages_filters_db$OS_type <-
function(db)
{
    ## Ignore packages that do not fit our OS.
    OS_type <- db[, "OS_type"]
    db[is.na(OS_type) | (OS_type == .Platform$OS.type), , drop = FALSE]
}

available_packages_filters_db$subarch <-
function(db)
{
    ## Ignore packages that do not fit our sub-architecture.
    ## Applies only to Mac and Windows binary repositories.
    current <- .Platform$r_arch
    if(!nzchar(current)) return(db)
    archs <- db[, "Archs"]
    if(all(is.na(archs))) return(db)
    OK <- unlist(lapply(archs, function(x) {
        if(is.na(x)) return(TRUE)
        this <- strsplit(x, "[[:space:]]*,[[:space:]]*")[[1L]]
        current %in% this
    }))
    db[OK, , drop = FALSE]
}

available_packages_filters_db$duplicates <-
function(db)
    tools:::.remove_stale_dups(db)

available_packages_filters_db$`license/FOSS` <-
function(db)
{
    ## What we need to do is find all non-FOSS-verifiable packages and
    ## all their recursive dependencies.  Somewhat tricky because there
    ## may be dependencies missing from the package db.
    ## Hence, for efficiency reasons, do the following.
    ## Create a data frame which already has Depends/Imports/LinkingTo
    ## info in package list form, and use this to compute the out of db
    ## packages.
    db1 <- data.frame(Package = db[, "Package"],
                      stringsAsFactors = FALSE)
    fields <- c("Depends", "Imports", "LinkingTo")
    for(f in fields)
        db1[[f]] <-
            lapply(db[, f], tools:::.extract_dependency_package_names)

    all_packages <- unique(unlist(db1[fields], use.names = FALSE))
    bad_packages <-
        all_packages[is.na(match(all_packages, db1$Package))]
    ## Dependency package names missing from the db can be
    ## A. base packages
    ## C. really missing.
    ## We can ignore type A as these are known to be FOSS.
    bad_packages <-
        bad_packages[is.na(match(bad_packages,
                                 unlist(tools:::.get_standard_package_names())))]


    ## Packages in the db not verifiable as FOSS.
    ind <- !tools:::analyze_licenses(db[, "License"])$is_verified
    ## Now find the recursive reverse dependencies of these and the
    ## packages missing from the db.
    depends <-
        tools:::.package_dependencies(db1$Package[ind], db = db1,
                                      reverse = TRUE, recursive = TRUE)
    depends <- unique(unlist(depends))
    ind[match(depends, db1$Package, nomatch = 0L)] <- TRUE

    ## And drop these from the db.
    db[!ind, , drop = FALSE]
}

## unexported helper function
simplifyRepos <- function(repos, type)
{
    tail <- substring(contrib.url("---", type), 4L)
    ind <- regexpr(tail, repos, fixed=TRUE)
    ind <- ifelse(ind > 0L, ind-1L, nchar(repos, type="c"))
    substr(repos, 1L, ind)
}

update.packages <- function(lib.loc = NULL, repos = getOption("repos"),
                            contriburl = contrib.url(repos, type),
                            method, instlib = NULL, ask = TRUE,
                            available = NULL, oldPkgs = NULL, ...,
                            checkBuilt = FALSE, type = getOption("pkgType"))
{
    force(ask)  # just a check that it is valid before we start work
    text.select <- function(old)
    {
        update <- NULL
        for(k in seq_len(nrow(old))) {
            cat(old[k, "Package"], ":\n",
                "Version", old[k, "Installed"],
                "installed in", old[k, "LibPath"],
                if(checkBuilt) paste("built under R", old[k, "Built"]),
                "\n",
                "Version", old[k, "ReposVer"], "available at",
                simplifyRepos(old[k, "Repository"], type))
            cat("\n")
            answer <- substr(readline("Update (y/N/c)?  "), 1L, 1L)
            if(answer == "c" | answer == "C") {
                cat("cancelled by user\n")
                return(invisible())
            }
            if(answer == "y" | answer == "Y")
                update <- rbind(update, old[k,])
        }
        update
    }

    if(is.null(lib.loc))
        lib.loc <- .libPaths()

    if(is.null(available))
        available <- available.packages(contriburl = contriburl,
                                        method = method)
    if(is.null(oldPkgs)) {
        ## since 'available' is supplied, 'contriburl' and 'method' are unused
	oldPkgs <- old.packages(lib.loc = lib.loc,
				contriburl = contriburl, method = method,
				available = available, checkBuilt = checkBuilt)
	if(is.null(oldPkgs))
	    return(invisible())
    }
    else if(!(is.matrix(oldPkgs) && is.character(oldPkgs)))
	stop("invalid 'oldPkgs'; must be a result from old.packages()")

    update <- if(is.character(ask) && ask == "graphics") {
        if(.Platform$OS.type == "windows" || .Platform$GUI == "AQUA"
           || (capabilities("tcltk") && capabilities("X11"))) {
            k <- select.list(oldPkgs[,1L], oldPkgs[,1L], multiple = TRUE,
                             title = "Packages to be updated", graphics = TRUE)
            oldPkgs[match(k, oldPkgs[,1L]), , drop=FALSE]
        } else text.select(oldPkgs)
    } else if(isTRUE(ask)) text.select(oldPkgs)
    else oldPkgs


    if(length(update)) {
        if(is.null(instlib)) instlib <-  update[, "LibPath"]
        ## do this a library at a time, to handle dependencies correctly.
        libs <- unique(instlib)
        for(l in libs)
            install.packages(update[instlib == l , "Package"], l,
                             contriburl = contriburl, method = method,
                             available = available, ..., type = type)
    }
}

old.packages <- function(lib.loc = NULL, repos = getOption("repos"),
                         contriburl = contrib.url(repos, type),
                         instPkgs = installed.packages(lib.loc = lib.loc),
                         method, available = NULL, checkBuilt = FALSE,
                         type = getOption("pkgType"))
{
    if(is.null(lib.loc))
        lib.loc <- .libPaths()
    if(!missing(instPkgs)) {
        ## actually we need rather more than this
        if(!is.matrix(instPkgs) || !is.character(instPkgs[, "Package"]))
            stop("illformed 'instPkgs' matrix")
    }
    if(NROW(instPkgs) == 0L) return(NULL)

    available <- if(is.null(available))
        available.packages(contriburl = contriburl, method = method)
    else tools:::.remove_stale_dups(available)

    update <- NULL

    currentR <- minorR <- getRversion()
    minorR[[c(1L, 3L)]] <- 0L # set patchlevel to 0
    for(k in 1L:nrow(instPkgs)) {
        if (instPkgs[k, "Priority"] %in% "base") next
        z <- match(instPkgs[k, "Package"], available[, "Package"])
        if(is.na(z)) next
        onRepos <- available[z, ]
        ## works OK if Built: is missing (which it should not be)
	if((!checkBuilt || package_version(instPkgs[k, "Built"]) >= minorR) &&
           package_version(onRepos["Version"]) <=
           package_version(instPkgs[k, "Version"])) next
        deps <- onRepos["Depends"]
        if(!is.na(deps)) {
            Rdeps <- tools:::.split_dependencies(deps)[["R", exact=TRUE]]
            if(length(Rdeps) > 1L) {
                target <- Rdeps$version
                res <- eval(parse(text=paste("currentR", Rdeps$op, "target")))
                if(!res) next
            }
        }
        update <- rbind(update,
                        c(instPkgs[k, c("Package", "LibPath", "Version", "Built")],
                          onRepos["Version"], onRepos["Repository"]))
    }
    if(!is.null(update))
        colnames(update) <- c("Package", "LibPath", "Installed", "Built",
                              "ReposVer", "Repository")
    rownames(update) <- update[, "Package"]
    ## finally, remove any duplicate rows
    update[!duplicated(update), , drop = FALSE]
}

new.packages <- function(lib.loc = NULL, repos = getOption("repos"),
                         contriburl = contrib.url(repos, type),
                         instPkgs = installed.packages(lib.loc = lib.loc),
                         method, available = NULL, ask = FALSE,
                         ..., type = getOption("pkgType"))
{
    ask  # just a check that it is valid before we start work
    if(is.null(lib.loc)) lib.loc <- .libPaths()
    if(!is.matrix(instPkgs))
        stop(gettextf("no installed packages for (invalid?) 'lib.loc=%s'",
                      lib.loc), domain = NA)
    if(is.null(available))
        available <- available.packages(contriburl = contriburl,
                                        method = method)

    installed <- unique(instPkgs[, "Package"])

    poss <- sort(unique(available[ ,"Package"])) # sort in local locale
    res <- setdiff(poss, installed)

    update <- character(0L)
    graphics <- FALSE
    if(is.character(ask) && ask == "graphics") {
        ask <- TRUE
        if(.Platform$OS.type == "windows" || .Platform$GUI == "AQUA"
           || (capabilities("tcltk") && capabilities("X11")))
            graphics <- TRUE
    }
    if(isTRUE(ask))
        update <- res[match(select.list(res, multiple = TRUE,
                                        title = "New packages to be installed",
                                        graphics = graphics)
                            , res)]
    if(length(update)) {
        install.packages(update, lib = lib.loc[1L], contriburl = contriburl,
                         method = method, available = available,
                         type = type, ...)
        # Now check if they were installed and update 'res'
        dirs <- list.files(lib.loc[1L])
        updated <- update[update %in% dirs]
        res <- res[!res %in% updated]
    }
    res
}

.instPkgFields <- function(fields) {
    ## to be used in installed.packages() and similar
    requiredFields <-
        c(tools:::.get_standard_repository_db_fields(), "Built")
    if (is.null(fields))
	fields <- requiredFields
    else {
	stopifnot(is.character(fields))
	fields <- unique(c(requiredFields, fields))
    }
    ## Don't retain 'Package' and 'LibPath' fields as these are used to
    ## record name and path of installed packages.
    fields[! fields %in% c("Package", "LibPath")]
}


## Read packages' Description and aggregate 'fields' into a character matrix
## NB: this does not handle encodings, so only suitable for
## ASCII-only fields.
.readPkgDesc <- function(lib, fields, pkgs = list.files(lib))
{
    ## to be used in installed.packages() and similar
    ## FIXME: this is vulnerable to installs going on in parallel
    ret <- matrix(NA_character_, length(pkgs), 2L+length(fields))
    for(i in seq_along(pkgs)) {
        pkgpath <- file.path(lib, pkgs[i])
        if(file.access(pkgpath, 5L)) next
        pkgpath <- file.path(pkgpath, "DESCRIPTION")
        if(file.access(pkgpath, 4L)) next
        desc <- tryCatch(read.dcf(pkgpath, fields = fields), error = identity)
        if(inherits(desc, "error") || NROW(desc) < 1L) {
            warning(gettextf("read.dcf() error on file '%s'", pkgpath),
                    domain = NA, call. = FALSE)
            next
        }
        desc <- desc[1L,]
        Rver <- strsplit(strsplit(desc["Built"], ";")[[1L]][1L],
                         "[ \t]+")[[1L]][2L]
        desc["Built"] <- Rver
        ret[i, ] <- c(sub("_.*", "", pkgs[i]), lib, desc)
    }
    ret[!is.na(ret[, 1L]), ]
}

installed.packages <-
    function(lib.loc = NULL, priority = NULL, noCache = FALSE,
             fields = NULL, subarch = .Platform$r_arch)
{
    if(is.null(lib.loc))
        lib.loc <- .libPaths()
    if(!is.null(priority)) {
        if(!is.character(priority))
            stop("'priority' must be character or NULL")
        if(any(b <- priority %in% "high"))
            priority <- c(priority[!b], "recommended","base")
    }

    fields <- .instPkgFields(fields)
    retval <- matrix(character(0), 0L, 2L + length(fields))
    for(lib in lib.loc) {
	dest <- file.path(tempdir(),
			  paste("libloc_", URLencode(lib, TRUE),
				paste(fields, collapse=","), ".rds",
				sep=""))
	if(!noCache && file.exists(dest) &&
	    file.info(dest)$mtime > file.info(lib)$mtime) {
	    ## use the cache file
	    retval <- rbind(retval, .readRDS(dest))
	} else {
	    ret0 <- .readPkgDesc(lib, fields)
	    if(length(ret0)) {
		retval <- rbind(retval, ret0)
		## save the cache file
		.saveRDS(ret0, dest, compress = TRUE)
	    }
	}
    }

    .fixupPkgMat(retval, fields, priority, subarch)
}

.fixupPkgMat <- function(mat, fields, priority, subarch=NULL)
{
    ## to be used in installed.packages() and similar
    colnames(mat) <- c("Package", "LibPath", fields)
    if (length(mat) && !is.null(priority)) {
	keep <- !is.na(pmatch(mat[,"Priority"], priority,
			      duplicates.ok = TRUE))
	mat <- mat[keep, , drop = FALSE]
    }
    if (length(mat) && !is.null(subarch) && nzchar(subarch)) {
        archs <- strsplit(mat[, "Archs"], ", ", fixed = TRUE)
        keep <- unlist(lapply(archs,
                              function(x) is.na(x[1L]) || subarch %in% x))
	mat <- mat[keep, , drop = FALSE]
    }
    if (length(mat)) mat <- mat[, colnames(mat) != "Archs", drop = FALSE]
    if (length(mat)) rownames(mat) <- mat[, "Package"]
    mat
}


remove.packages <- function(pkgs, lib)
{
    updateIndices <- function(lib) {
        ## This should eventually be made public, as it could also be
        ## used by install.packages() && friends.
        if(lib == .Library) {
            if(exists("link.html.help", mode = "function"))
                link.html.help()
        }
    }

    if(!length(pkgs)) return(invisible())

    if(missing(lib) || is.null(lib)) {
        lib <- .libPaths()[1L]
	message(gettextf("Removing package(s) from %s\n(as %s is unspecified)",
			 sQuote(lib), sQuote("lib")), domain = NA)
    }

    paths <- .find.package(pkgs, lib)
    if(length(paths)) {
        unlink(paths, TRUE)
        for(lib in unique(dirname(paths))) updateIndices(lib)
    }
    invisible()
}

download.packages <- function(pkgs, destdir, available = NULL,
                              repos = getOption("repos"),
                              contriburl = contrib.url(repos, type),
                              method, type = getOption("pkgType"), ...)
{
    dirTest <- function(x) !is.na(isdir <- file.info(x)$isdir) & isdir

    nonlocalcran <- length(grep("^file:", contriburl)) < length(contriburl)
    if(nonlocalcran && !dirTest(destdir))
        stop("'destdir' is not a directory")
    if(is.null(available))
        available <- available.packages(contriburl=contriburl, method=method)

    retval <- matrix(character(0L), 0L, 2L)
    for(p in unique(pkgs))
    {
        ok <- (available[,"Package"] == p)
        ok <- ok & !is.na(ok)
        if(!any(ok))
            warning(gettextf("no package '%s' at the repositories", p),
                    domain = NA, immediate. = TRUE)
        else {
            if(sum(ok) > 1L) { # have multiple copies
                vers <- package_version(available[ok, "Version"])
                keep <- vers == max(vers)
                keep[duplicated(keep)] <- FALSE
                ok[ok][!keep] <- FALSE
            }
            if (substr(type, 1L, 10L) == "mac.binary") type <- "mac.binary"
            ## in Oct 2009 we introduced file names in PACKAGES files
            File <- available[ok, "File"]
            fn <- paste(p, "_", available[ok, "Version"],
                        switch(type,
                               "source" = ".tar.gz",
                               "mac.binary" = ".tgz",
                               "win.binary" = ".zip",
                               "win64.binary" = ".zip"),
                        sep = "")
            have_fn <- !is.na(File)
            fn[have_fn] <- File[have_fn]
            repos <- available[ok, "Repository"]
            if(length(grep("^file:", repos)) > 0L) { # local repository
                ## This could be file: + file path or a file:/// URL.
                if(substring(repos, 1L, 8L) == "file:///") {
                    ## We need to derive the file name from the URL
                    ## This is tricky as so many forms have been allowed,
                    ## and indeed external methods may do even more.
                    fn <- paste(substring(repos, 8L), fn, sep = "/")
                    ## This leaves a path beginning with /
                    if(.Platform$OS.type == "windows") {
                        if(length(grep("^/[A-Za-z]:", fn)))
                            fn <- substring(fn, 2L)
                    }
                } else {
                    fn <- paste(substring(repos, 6L), fn, sep = "/")
                }
                if(file.exists(fn))
                    retval <- rbind(retval, c(p, fn))
                else
                    warning(gettextf("package '%s' does not exist on the local repository", p),
                            domain = NA, immediate. = TRUE)
            } else {
                url <- paste(repos, fn, sep="/")
                destfile <- file.path(destdir, fn)

                res <- try(download.file(url, destfile, method, mode="wb", ...))
                if(!inherits(res, "try-error") && res == 0L)
                    retval <- rbind(retval, c(p, destfile))
                else
                    warning(gettextf("download of package '%s' failed", p),
                            domain = NA, immediate. = TRUE)
            }
        }
    }

    retval
}

contrib.url <- function(repos, type = getOption("pkgType"))
{
    if(is.null(repos)) return(NULL)
    if("@CRAN@" %in% repos && interactive()) {
        cat(gettext("--- Please select a CRAN mirror for use in this session ---"),
            "\n", sep = "")
        flush.console()
        chooseCRANmirror()
        m <- match("@CRAN@", repos)
        nm <- names(repos)
        repos[m] <- getOption("repos")["CRAN"]
        if(is.null(nm)) nm <- rep("", length(repos))
        nm[m] <- "CRAN"
        names(repos) <- nm
    }
    if("@CRAN@" %in% repos) stop("trying to use CRAN without setting a mirror")

    ver <- paste(R.version$major,
                 strsplit(R.version$minor, ".", fixed=TRUE)[[1L]][1L], sep = ".")
    mac.subtype <- "universal"
    if (substr(type, 1L, 11L) == "mac.binary.") {
        mac.subtype <- substring(type, 12L)
        type <- "mac.binary"
    }
    res <- switch(type,
		"source" = paste(gsub("/$", "", repos), "src", "contrib", sep="/"),
                "mac.binary" = paste(gsub("/$", "", repos), "bin", "macosx", mac.subtype, "contrib", ver, sep = "/"),
                "win.binary" = paste(gsub("/$", "", repos), "bin", "windows", "contrib", ver, sep="/"),
                "win64.binary" = paste(gsub("/$", "", repos), "bin", "windows64", "contrib", ver, sep="/")
               )
    res
}


getCRANmirrors <- function(all=FALSE, local.only=FALSE)
{
    m <- NULL
    if(!local.only) {
        ## try to handle explicitly failure to connect to CRAN.
        con <- url("http://cran.r-project.org/CRAN_mirrors.csv")
        m <- try(open(con, "r"), silent = TRUE)
        if(!inherits(m, "try-error")) m <- try(read.csv(con, as.is=TRUE))
        close(con)
    }
    if(is.null(m) || inherits(m, "try-error"))
        m <- read.csv(file.path(R.home("doc"), "CRAN_mirrors.csv"), as.is=TRUE)
    if(!all) m <- m[as.logical(m$OK), ]
    m
}


chooseCRANmirror <- function(graphics = getOption("menu.graphics"))
{
    if(!interactive()) stop("cannot choose a CRAN mirror non-interactively")
    m <- getCRANmirrors(all=FALSE, local.only=FALSE)
    res <- menu(m[, 1L], graphics, "CRAN mirror")
    if(res > 0L) {
        URL <- m[res, "URL"]
        repos <- getOption("repos")
        repos["CRAN"] <- gsub("/$", "", URL[1L])
        options(repos = repos)
    }
    invisible()
}

chooseBioCmirror <- function(graphics = getOption("menu.graphics"))
{
    if(!interactive()) stop("cannot choose a BioC mirror non-interactively")
    m <- c("Seattle (USA)"="http://www.bioconductor.org",
           "Bethesda (USA)"="http://watson.nci.nih.gov/bioc_mirror",
           "Dortmund (Germany)"="http://bioconductor.statistik.tu-dortmund.de")
    res <- menu(names(m), graphics, "BioC mirror")
    if(res > 0L) options("BioC_mirror" = m[res])
    invisible()
}

setRepositories <-
    function(graphics = getOption("menu.graphics"), ind = NULL)
{
    if(is.null(ind) && !interactive())
        stop("cannot set repositories non-interactively")
    p <- file.path(Sys.getenv("HOME"), ".R", "repositories")
    if(!file.exists(p))
        p <- file.path(R.home("etc"), "repositories")
    a <- tools:::.read_repositories(p)
    pkgType <- getOption("pkgType")
    if(length(grep("^mac\\.binary", pkgType))) pkgType <- "mac.binary"
    thisType <- a[[pkgType]]
    a <- a[thisType, 1L:3L]
    repos <- getOption("repos")
    ## Now look for CRAN and any others in getOptions("repos")
    if("CRAN" %in% row.names(a) && !is.na(CRAN <- repos["CRAN"]))
        a["CRAN", "URL"] <- CRAN
    ## Set as default any already in the option.
    a[(a[["URL"]] %in% repos), "default"] <- TRUE
    new <- !(repos %in% a[["URL"]])
    if(any(new)) {
        aa <- names(repos[new])
        if(is.null(aa)) aa <- rep("", length(repos[new]))
        aa[aa == ""] <- repos[new][aa == ""]
        newa <- data.frame(menu_name=aa, URL=repos[new], default=TRUE)
        row.names(newa) <- aa
        a <- rbind(a, newa)
    }

    default <- a[["default"]]

    res <- if(length(ind)) as.integer(ind)
    else {
        title <- if(graphics) "Repositories" else gettext("--- Please select repositories for use in this session ---\n")
        match(select.list(a[, 1L], a[default, 1L], multiple = TRUE, title,
                           graphics = graphics), a[, 1L])
    }
    if(length(res)) {
        repos <- a[["URL"]]
        names(repos) <- row.names(a)
        options(repos = repos[res])
    }
}

normalizePath <- function(path) .Internal(normalizePath(path))


## used in some BioC packages and their support in tools.
compareVersion <- function(a, b)
{
    if(is.na(a)) return(-1L)
    if(is.na(b)) return(1L)
    a <- as.integer(strsplit(a, "[\\.-]")[[1L]])
    b <- as.integer(strsplit(b, "[\\.-]")[[1L]])
    for(k in seq_along(a))
        if(k <= length(b)) {
            if(a[k] > b[k]) return(1) else if(a[k] < b[k]) return(-1L)
        } else return(1L)
    if(length(b) > length(a)) return(-1L) else return(0L)
}

## ------------- private functions --------------------
.clean_up_dependencies <- function(x, available = NULL)
{
    ## x is a character vector of Depends / Suggests / Imports entries
    ## returns a character vector of all the package dependencies mentioned
    x <- x[!is.na(x)]
    if(!length(x)) return(x)
    x <- unlist(strsplit(x, ","))
    unique(sub("^[[:space:]]*([[:alnum:].]+).*$", "\\1" , x))
}

.clean_up_dependencies2 <- function(x, installed, available)
{
    ## x is a character vector of Depends / Suggests / Imports entries.
    ## Returns a list of length 2, a character vector of the names of
    ## all the package dependencies mentioned that are not already
    ## satisfied and one of those which cannot be satisfied (possibly
    ## of the form "pkg (>= ver)')

    .split_dependencies <- function(x) {
        .split2 <- function(x) {
            ## some have had space before ,
            x <- sub('[[:space:]]+$', '', x)
            x <- unique(sub("^[[:space:]]*(.*)", "\\1" , x))
            names(x) <- sub("^([[:alnum:].]+).*$", "\\1" , x)
            x <- x[names(x) != "R"]
	    x <- x[nzchar(x)]
            ## FIXME: a better way to handle duplicates.
            ## However, there should not be any, and if there are
            ## Depends: should be the first.
            x <- x[!duplicated(names(x))]
            lapply(x, tools:::.split_op_version)
        }
        ## given one of more concatenations of Depends/Imports/Suggests fields,
        ## return a named list of list(name, [op, version])
        if(!any(nzchar(x))) return(list())
        unlist(lapply(strsplit(x, ","), .split2), FALSE, FALSE)
    }
    x <- x[!is.na(x)]
    if(!length(x)) return(list(character(0L), character(0L)))
    xx <- .split_dependencies(x)
    if(!length(xx)) return(list(character(0L), character(0L)))
    ## Then check for those we already have installed
    pkgs <- installed[, "Package"]
    have <- sapply(xx, function(x) {
        if(length(x) == 3L) {
            if (! x[[1L]] %in% pkgs ) return(FALSE)
            if(x[[2L]] != ">=") return(TRUE)
            ## We may have the package installed more than once
            ## which we get will depend on the .libPaths() order,
            ## so for now just see if any installed version will do.
            current <- as.package_version(installed[pkgs == x[[1L]], "Version"])
            target <- as.package_version(x[[3L]])
            eval(parse(text = paste("any(current", x$op, "target)")))
        } else x[[1L]] %in% pkgs
    })
    xx <- xx[!have]
    if(!length(xx)) return(list(character(0L), character(0L)))
    ## now check if we can satisfy the missing dependencies
    pkgs <- row.names(available)
    canget <- miss <- character(0L)
    for (i in seq_along(xx)) {
        x <- xx[[i]]
        if(length(x) == 3L) {
            if (! x[[1L]] %in% pkgs ) { miss <- c(miss, x[[1L]]); next }
            if(x[[2L]] != ">=") { canget <- c(canget, x[[1L]]); next }
            ## we may have the package available more than once
            ## install.packages() will find the highest version.
            current <- as.package_version(available[pkgs == x[[1L]], "Version"])
            target <- as.package_version(x[[3L]])
            res <- eval(parse(text = paste("any(current", x$op, "target)")))
            if(res) canget <- c(canget, x[[1L]])
            else  miss <- c(miss, paste(x[[1L]], " (>= ", x[[3L]], ")", sep=""))
        } else if(x[[1L]] %in% pkgs) canget <- c(canget, x[[1L]])
        else miss <- c(miss, x[[1L]])
    }
    list(canget, miss)
}

.make_dependency_list <-
function(pkgs, available, dependencies = c("Depends", "Imports", "LinkingTo"))
{
    ## given a character vector of packages,
    ## return a named list of character vectors of their dependencies
    if(!length(pkgs)) return(NULL)
    if(is.null(available))
        stop(gettextf("'%s' must be supplied", available), domain = NA)
    info <- available[pkgs, dependencies, drop = FALSE]
    ## we always want a list here, but apply can simplify to a matrix.
    ## x <- apply(info, 1L, .clean_up_dependencies)
    ## if(length(pkgs) == 1) {x <- list(as.vector(x)); names(x) <- pkgs}
    x <- vector("list", length(pkgs)); names(x) <- pkgs
    for (i in seq_along(pkgs))
        x[[i]] <- .clean_up_dependencies(info[i, ])
    x
}

.find_install_order <- function(pkgs, dependencyList)
{
    ## given a character vector of packages, find an install order
    ## which reflects their dependencies.
    DL <- dependencyList[pkgs]
    ## some of the packages may be already installed, but the
    ## dependencies apply to those being got from CRAN.
    DL <- lapply(DL, function(x) x[x %in% pkgs])
    lens <- sapply(DL, length)
    if(all(lens > 0L)) {
        warning("every package depends on at least one other")
        return(pkgs)
    }
    done <- names(DL[lens == 0L]); DL <- DL[lens > 0L]
    while(length(DL)) {
        OK <- sapply(DL, function(x) all(x %in% done))
        if(!any(OK)) {
            warning(gettextf("packages %s are mutually dependent",
                             paste(sQuote(names(DL)), collapse = ", ")),
                    domain = NA)
            return(c(done,  names(DL)))
        }
        done <- c(done, names(DL[OK]))
        DL <- DL[!OK]
    }
    done
}

