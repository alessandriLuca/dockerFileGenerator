#  File src/library/base/R/octhex.R
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

format.octmode <- function(x, width = NULL, ...)
{
    isna <- is.na(x)
    y <- as.integer(x[!isna])
    fmt <- if(!is.null(width)) paste("%0", width, "o", sep = "") else "%o"
    ans <- rep.int(NA_character_, length(x))
    ans0 <- sprintf(fmt, y)
    if(is.null(width) && length(y) > 1L) {
        ## previous version padded with zeroes to a common field width
        nc <- max(nchar(ans0))
        ans0 <- sprintf(paste("%0", nc, "o", sep = ""), y)
    }
    ans[!isna] <- ans0
    dim(ans) <- dim(x)
    dimnames(ans) <- dimnames(x)
    names(ans) <- names(x)
    ans
}

as.character.octmode <- function(x, ...) format.octmode(x, ...)

print.octmode <- function(x, ...)
{
    print(format(x), ...)
    invisible(x)
}

"[.octmode" <- function (x, i)
{
    cl <- oldClass(x)
    y <- NextMethod("[")
    oldClass(y) <- cl
    y
}

as.octmode <- function(x)
{
    if(inherits(x, "octmode")) return(x)
    if(is.double(x) && x == as.integer(x)) x <- as.integer(x)
    if(is.integer(x)) return(structure(x, class="octmode"))
    if(is.character(x)) {
        z <- strtoi(x, 8L)
        if(!any(is.na(z) | z < 0)) return(structure(z, class="octmode"))
    }
    stop("'x' cannot be coerced to 'octmode'")
}

## BioC packages cellHTS2 and flowCore misuse this for doubles,
## hence the as.integer() call
format.hexmode <- function(x, width = NULL, upper.case = FALSE, ...)
{
    isna <- is.na(x)
    y <- as.integer(x[!isna])
    fmt0 <- if(upper.case) "X" else "x"
    fmt <- if(!is.null(width)) paste("%0", width, fmt0, sep = "") else paste("%", fmt0, sep = "")
    ans <- rep.int(NA_character_, length(x))
    ans0 <- sprintf(fmt, y)
    if(is.null(width) && length(y) > 1L) {
        ## previous version padded with zeroes to a common field width
        nc <- max(nchar(ans0))
        ans0 <- sprintf(paste("%0", nc, fmt0, sep = ""), y)
    }
    ans[!isna] <- ans0
    dim(ans) <- dim(x)
    dimnames(ans) <- dimnames(x)
    names(ans) <- names(x)
    ans
}

as.character.hexmode <- function(x, ...) format.hexmode(x, ...)

print.hexmode <- function(x, ...)
{
    print(format(x), ...)
    invisible(x)
}

"[.hexmode" <- function (x, i)
{
    cl <- oldClass(x)
    y <- NextMethod("[")
    oldClass(y) <- cl
    y
}

as.hexmode <- function(x)
{
    if(inherits(x, "hexmode")) return(x)
    if(is.double(x) && (x == as.integer(x))) x <- as.integer(x)
    if(is.integer(x)) return(structure(x, class = "hexmode"))
    if(is.character(x)) {
        z <- strtoi(x, 16L)
        if(!any(is.na(z) | z < 0)) return(structure(z, class = "hexmode"))
    }
    stop("'x' cannot be coerced to hexmode")
}
