#  File src/library/utils/R/frametools.R
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

stack <- function(x, ...) UseMethod("stack")

stack.data.frame <- function(x, select, ...)
{
    if (!missing(select)) {
	nl <- as.list(1L:ncol(x))
	names(nl) <- names(x)
	vars <- eval(substitute(select),nl, parent.frame())
        x <- x[, vars, drop=FALSE]
    }
    x <- x[, unlist(lapply(x, is.vector)), drop = FALSE]
    data.frame(values = unlist(unname(x)),
               ind = factor(rep.int(names(x), lapply(x, length))))
}

stack.default <- function(x, ...)
{
    x <- as.list(x)
    x <- x[unlist(lapply(x, is.vector))]
    data.frame(values = unlist(unname(x)),
               ind = factor(rep.int(names(x), lapply(x, length))))
}

unstack <- function(x, ...) UseMethod("unstack")

unstack.data.frame <- function(x, form, ...)
{
    form <- if(missing(form)) stats::formula(x) else stats::as.formula(form)
    if (length(form) < 3)
        stop("'form' must be a two-sided formula")
    res <- c(tapply(eval(form[[2L]], x), eval(form[[3L]], x), as.vector))
    if (length(res) < 2L || any(diff(unlist(lapply(res, length))) != 0L))
        return(res)
    data.frame(res)
}

unstack.default <- function(x, form, ...)
{
    x <- as.list(x)
    form <- stats::as.formula(form)
    if ((length(form) < 3) || (length(all.vars(form))>2))
        stop("'form' must be a two-sided formula with one term on each side")
    res <- c(tapply(eval(form[[2L]], x), eval(form[[3L]], x), as.vector))
    if (length(res) < 2L || any(diff(unlist(lapply(res, length))) != 0L))
        return(res)
    data.frame(res)
}
