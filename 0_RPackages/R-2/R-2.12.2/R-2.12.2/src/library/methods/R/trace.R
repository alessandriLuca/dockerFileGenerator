#  File src/library/methods/R/trace.R
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

## some temporary (!) hooks to trace the tracing code
.doTraceTrace <- function(on) {
 .assignOverBinding(".traceTraceState", on,
                    environment(.doTraceTrace), FALSE)
  on
}

.traceTraceState <- FALSE

## the internal functions in the evaluator.  These are all prohibited,
## although some of them could just barely be accomodated, with some
## specially designed new definitions (not using ..., for example).
## The gain does not seem worth the inconsistencies; and "if" can
## never be traced, since it has to be used to determine if tracing is
## on.  (see .doTrace())
## The remaining invalid functions create miscellaneous bugs, maybe
## related to the use of "..." as the introduced arguments.  Aside from
## .Call, tracing them seems of marginal value.

.InvalidTracedFunctions <- c("if", "where", "for", "repeat", "(", "{",
                            "next", "break", ".Call", ".Internal", ".Primitive")

.TraceWithMethods <- function(what, tracer = NULL, exit = NULL, at =
                              numeric(), print = TRUE, signature =
                              NULL, where = .GlobalEnv, edit = FALSE,
                              from = NULL, untrace = FALSE) {
    if(is.function(where)) {
        ## start from the function's environment:  important for
        ## tracing from a namespace
        if(is(where, "genericFunction"))
            where <- parent.env(environment(where))
        else
            where <- environment(where)
        fromPackage <- getPackageName(where)
    }
    else fromPackage <- ""
    doEdit <- !identical(edit, FALSE)
    whereF <- NULL
    pname <- character()
    def <- NULL
    if(is.function(what)) {
        def <- what
        if(is(def, "genericFunction")) {
            what <- def@generic
            whereF <- .genEnv(what, where)
            pname <- def@package
        }
        else {
            fname <- substitute(what)
            if(is.name(fname)) {
                what <- as.character(fname)
                temp <- .findFunEnvAndName(what, where)
                whereF <- temp$whereF
                pname <- temp$pname
            }
            else if(is.call(fname) && identical(fname[[1L]], as.name("::"))) {
                whereF <-as.character(fname[[2L]])
                require(whereF, character.only = TRUE)
                whereF <- as.environment(paste("package", whereF, sep=":"))
                pname <-  fname[[2L]]
                what <- as.character(fname[[3L]])
            }
            else if(is.call(fname) && identical(fname[[1L]], as.name(":::"))) {
                pname <- paste(fname[[2L]], "(not-exported)")
                whereF <- loadNamespace(as.character(fname[[2L]]))
                what <- as.character(fname[[3L]])
            }
            else
                stop("argument 'what' should be the name of a function")
        }
    }
    else {
        what <- as(what, "character")
        if(length(what) != 1) {
            for(f in what) {
                if(nargs() == 1)
                    trace(f)
                else
                    Recall(f, tracer, exit, at, print, signature, where, edit, from, untrace)
            }
            return(what)
        }
        temp <- .findFunEnvAndName(what, where, signature)
        whereF <- temp$whereF
        pname <- temp$pname
    }
    if(what %in% .InvalidTracedFunctions)
        stop(gettextf("Tracing the internal function \"%s\" is not allowed",
                      what))
    if(.traceTraceState) {
        message(".TraceWithMethods: after computing what, whereF")
        browser()
    }
    if(nargs() == 1)
        return(.primTrace(what)) # for back compatibility
    if(is.null(whereF)) {
        allWhere <- findFunction(what, where = where)
        if(length(allWhere)==0)
            stop(gettextf("no function definition for \"%s\" found", what),
                 domain = NA)
        whereF <- as.environment(allWhere[[1L]])
    }
    ## detect use with no action specified (old-style R trace())
    if(is.null(tracer) && is.null(exit) && identical(edit, FALSE))
        tracer <- quote({})
    if(is.null(def))
        def <- getFunction(what, where = whereF)
    if(is(def, "traceable") && identical(edit, FALSE) && !untrace)
        def <- .untracedFunction(def)
    if(!is.null(signature)) {
        fdef <- if(is.primitive(def))  getGeneric(what, TRUE, where) else def
        def <- selectMethod(what, signature, fdef = fdef, optional = TRUE)
        if(is.null(def)) {
            warning(gettextf("Can't untrace method for \"%s\"; no method defined for this signature: %s",
                             what, paste(signature, collapse = ", ")))
            return(def)
        }
    }
    if(untrace) {
        if(.traceTraceState) {
            message(".TraceWithMethods: untrace case")
            browser()
        }

        if(is.null(signature)) {
            ## ensure that the version to assign is untraced
            if(is(def, "traceable")) {
                newFun <- .untracedFunction(def)
            }
            else {
                .primUntrace(what) # to be safe--no way to know if it's traced or not
                return(what)
            }
        }
        else {
            if(is(def, "traceable"))
                newFun <- .untracedFunction(def)
            else {
                warning(gettextf("the method for \"%s\" for this signature was not being traced", what), domain = NA)
                return(what)
            }
        }
    }
    else {
        if(!is.null(exit)) {
            if(is.function(exit)) {
                tname <- substitute(exit)
                if(is.name(tname))
                    exit <- tname
                exit <- substitute(TRACE(), list(TRACE=exit))
            }
        }
        if(!is.null(tracer)) {
            if(is.function(tracer)) {
                tname <- substitute(tracer)
                if(is.name(tname))
                    tracer <- tname
                tracer <- substitute(TRACE(), list(TRACE=tracer))
            }
        }
        original <- .untracedFunction(def)
        traceClass <- .traceClassName(class(original))
        if(is.null(getClassDef(traceClass)))
            traceClass <- .makeTraceClass(traceClass, class(original))
        if(doEdit && is.environment(edit)) {
            ## trace with the version found in the edit environment
            def <- .findNewDefForTrace(what, signature, edit, fromPackage)
            environment(def) <- environment(original)
            if(is.null(c(tracer, exit))) {
                newFun <- new(traceClass, original)
                newFun@.Data <- def
            }
            else {
                newFun <- new(traceClass, def = def, tracer = tracer, exit = exit, at = at, print = print, doEdit = FALSE)
                newFun@original <- original # left as def by initialize method
            }
            newFun@source <- edit
        }
        else
            newFun <- new(traceClass,
                      def = if(doEdit) def else original, tracer = tracer, exit = exit, at = at,
                      print = print, doEdit = edit)
    }
    global <- identical(whereF, .GlobalEnv)
    if(.traceTraceState) {
        message(".TraceWithMethods: about to assign or setMethod")
        browser()
    }
    if(is.null(signature)) {
        if(bindingIsLocked(what, whereF))
            .assignOverBinding(what, newFun, whereF, global)
        else
            assign(what, newFun, whereF)
        if(length(grep("[^.]+[.][^.]+", what)) > 0) { #possible S3 method
            ## check for a registered version of the object
            S3MTableName <- ".__S3MethodsTable__."
            tracedFun <- get(what, envir = whereF, inherits = TRUE)
            if(exists(S3MTableName, envir = whereF, inherits = FALSE)) {
                tbl <- get(S3MTableName, envir = whereF, inherits = FALSE)
                if(exists(what, envir = tbl, inherits = FALSE))
                    assign(what, tracedFun, envir = tbl)
            }
        }
    }
    else {
        if(untrace && is(newFun, "MethodDefinition") &&
           !identical(newFun@target, newFun@defined))
            ## we promoted an inherited method for tracing, now we have
            ## to remove that method.  Assertion is that there was no directly
            ## specified method, or else defined, target would be identical
            newFun <- NULL
        ## arrange for setMethod to put the new method in the generic
        ## but NOT to assign the methods list object (binding is ignored)
        setMethod(fdef, signature, newFun, where = baseenv())
    }
    if(!global) {
        action <- if(untrace)"Untracing" else "Tracing"
        nameSpaceCase <- FALSE
        location <- if(.identC(fromPackage, "")) {
            if(length(pname)==0  && !is.null(whereF))
                pname <- getPackageName(whereF)
            nameSpaceCase <- isNamespace(whereF) &&
            !is.na(match(pname, loadedNamespaces())) &&
            identical(whereF, getNamespace(pname))
            if(length(pname)==0)  # but not possible from getPackagename ?
                "\""
            else {
                if(nameSpaceCase)
                    paste("\" in environment <namespace:",  pname, ">", sep="")
                else
                    paste("\" in package \"",  pname, "\"", sep="")
            }
        }
        else paste("\" as seen from package \"", fromPackage, "\"", sep="")
        object <- if(is.null(signature)) " function \"" else " specified method for function \""
        .message(action, object, what, location)
        if(nameSpaceCase && !untrace && exists(what, envir = .GlobalEnv)) {
            untcall<- paste("untrace(\"", what, "\", where = getNamespace(\"",
                            pname, "\"))", sep="")
            .message("Warning: Tracing only in the namespace; to untrace you will need:\n    ",untcall, "\n")
        }
    }
    what
}

.makeTracedFunction <- function(def, tracer, exit, at, print, doEdit) {
    switch(typeof(def),
           builtin = , special = {
               fBody <- substitute({.prim <- DEF; .prim(...)},
                                   list(DEF = def))
               def <- eval(function(...)NULL)
               body(def, envir = .GlobalEnv) <- fBody
               warning("making a traced version of a primitive; arguments will be treated as '...'")
           }
           )
    if(!identical(doEdit, FALSE)) {
        if(is.character(doEdit) || is.function(doEdit)) {
            editor <- doEdit
            doEdit <- TRUE
        }
        else
            editor <- getOption("editor")
    }
    ## look for a request to edit the definition
    if(doEdit) {
        if(is(def, "traceable"))
            def <- as(def, "function") # retain previous tracing if editing
        if(is(editor, "character") && !is.na(match(editor, c("emacs","xemacs")))) {
            ## cater to the usual emacs modes for editing R functions
            file <- tempfile("emacs")
            file <- sub('..$', ".R", file)
        }
        else
            file <- ""
        ## insert any requested automatic tracing expressions before editing
        if(!(is.null(tracer) && is.null(exit) && length(at)==0))
            def <- Recall(def, tracer, exit, at, print, FALSE)
        def2 <- utils::edit(def, editor = editor, file = file)
        if(!is.function(def2))
            stop(gettextf("the editing in trace() can only change the body of the function; got an object of class \"%s\"", class(def2)), domain = NA)
        if(!identical(args(def), args(def2)))
            stop("the editing in trace() can only change the body of the function, not the arguments or defaults")
        fBody <- body(def2)
    }
    else {
        def <- .untracedFunction(def) # throw away earlier tracing
        fBody <- body(def)
        if(length(at) > 0) {
            if(is.null(tracer))
                stop("cannot use 'at' argument without a trace expression")
            else if(class(fBody) != "{")
                stop("cannot use 'at' argument unless the function body has the form '{ ... }'")
            for(i in at) {
                if(print)
                    expri <- substitute({.doTrace(TRACE, MSG); EXPR},
                                        list(TRACE = tracer,
                                        MSG = paste("step",paste(i, collapse=",")),
                                        EXPR = fBody[[i]]))
                else
                    expri <- substitute({.doTrace(TRACE); EXPR},
                                        list(TRACE=tracer, EXPR = fBody[[i]]))
                fBody[[i]] <- expri
            }
        }
        else if(!is.null(tracer)){
            if(print)
                fBody <- substitute({.doTrace(TRACE, MSG); EXPR},
                                    list(TRACE = tracer, MSG = paste("on entry"), EXPR = fBody))
            else
                fBody <- substitute({.doTrace(TRACE); EXPR},
                                    list(TRACE=tracer, EXPR = fBody))
        }
        if(!is.null(exit)) {
            if(print)
                exit <- substitute(.doTrace(EXPR, MSG),
                                   list(EXPR = exit, MSG = paste("on exit")))
            else
                exit <- substitute(.doTrace(EXPR),
                                   list(EXPR = exit))
            fBody <- substitute({on.exit(TRACE); BODY},
                                list(TRACE=exit, BODY=fBody))
        }
    }
    body(def, envir = environment(def)) <- fBody
    def
}

## return the untraced version of f
.untracedFunction <- function(f) {
    while(is(f, "traceable"))
        f <- f@original
    f
}


.InitTraceFunctions <- function(envir)  {
    setClass("traceable", representation(original = "PossibleMethod", source = "environment"), contains = "VIRTUAL",
             where = envir); clList <- "traceable"
    ## create the traceable classes
    for(cl in c("function", "MethodDefinition", "MethodWithNext", "genericFunction",
                "standardGeneric", "nonstandardGeneric", "groupGenericFunction",
                "derivedDefaultMethod")) {
        .makeTraceClass(.traceClassName(cl), cl, FALSE)
        clList <- c(clList, .traceClassName(cl))
    }
    setClass("sourceEnvironment", contains = "environment",
             representation(packageName = "character", dateCreated = "POSIXt", sourceFile = "character"),
             prototype = prototype( packageName = "", dateCreated = Sys.time(), sourceFile = ""))
    clList <- c(clList, "sourceEnvironment")
    assign(".SealedClasses", c(get(".SealedClasses", envir), clList), envir)
    setMethod("initialize", "traceable",
              function(.Object, ...) .initTraceable(.Object, ...),
              where = envir)
    if(!isGeneric("show", envir))
        setGeneric("show", where = envir, simpleInheritanceOnly = TRUE)
    setMethod("show", "traceable", .showTraceable, where = envir)
    setMethod("show", "sourceEnvironment", .showSource, where = envir)
}

## allow control over whether methods & classes are cached when assigned
## to a particular environment. defaults to TRUE
cacheOnAssign <- function(env) is.null(env$.cacheOnAssign) || env$.cacheOnAssign
setCacheOnAssign <- function(env, onOff = cacheOnAssign(env))
    env$.cacheOnAssign <- if(onOff) TRUE else FALSE

.showTraceable <- function(object) {
    if(identical(object@source, emptyenv())) {
        cat("Object with tracing code, class \"", class(object),
        "\"\nOriginal definition: \n", sep="")
        callGeneric(object@original)
        cat("\n## (to see the tracing code, look at body(object))\n")
    }
    else {
        cat("Object of class \"", class(object),
            "\", from source\n", sep = "")
        callGeneric(object@.Data)
        cat("\n## (to see original from package, look at object@original)\n")
    }
}

.initTraceable <- function(.Object, def, tracer, exit, at, print, doEdit) {
    .Object@source <- emptyenv()
    if(missing(def))
        return(.Object)
    oldClass <- class(def)
    oldClassDef <- getClass(oldClass)
    if(!is.null(oldClassDef) && length(oldClassDef@slots) > 0)
        as(.Object, oldClass) <- def # to get other slots in def
    .Object@original <- def
    if(nargs() > 2) {
        if(!is.null(elNamed(getSlots(getClass(class(def))), ".Data")))
          def <- def@.Data
        .Object@.Data <- .makeTracedFunction(def, tracer, exit, at, print, doEdit)
    }
    .Object
}

.showSource <- function(object) {
    cat("Object of class \"", class(object), "\"\n", sep = "")
    cat("Source environment created ", format(object@dateCreated), "\n")
    if(nzchar(object@packageName))
        cat("For package \"",object@packageName, "\"\n", sep = "")
    if(nzchar(object@sourceFile))
        cat("From source file \"", object@sourceFile, "\"\n", sep = "")
}

.doTracePrint <- function(msg = "") {
    call <- deparse(sys.call(sys.parent(1)))
    if(length(call)>1)
        call <- paste(call[[1L]], "....")
    cat("Tracing", call, msg, "\n")
}

.traceClassName <- function(className) {
    className[] <- paste(className, "WithTrace", sep="")
    className
}

.assignOverBinding <- function(what, value, where, verbose = TRUE) {
    if(verbose) {
        pname <- getPackageName(where)
        msg <-
            gettextf("assigning over the binding of symbol \"%s\" in environment/package \"%s\"",
                     what, pname)
        message(strwrap(msg), domain = NA)
    }
    warnOpt <- options(warn= -1) # kill the obsolete warning from R_LockBinding
    on.exit(options(warnOpt))
    if(is.function(value)) {
        ## assign in the namespace for the function as well
        fenv <- environment(value)
        if(is.null(fenv)) # primitives
          fenv <- baseenv()
        if(!identical(fenv, where) && exists(what, envir = fenv, inherits = FALSE #?
                                             ) && bindingIsLocked(what, fenv)) {
            unlockBinding(what, fenv)
            assign(what, value, fenv)
            lockBinding(what, fenv)
        }
    }
    if(exists(what, envir = where, inherits = FALSE) && bindingIsLocked(what, where)) {
      unlockBinding(what, where)
      assign(what, value, where)
      lockBinding(what, where)
    }
    else
      assign(what, value, where)
}

.setMethodOverBinding <- function(what, signature, method, where, verbose = TRUE) {
    if(verbose)
        warning(gettextf("setting a method over the binding of symbol \"%s\" in environment/package \"%s\"", what, getPackageName(where)), domain = NA)
    if(exists(what, envir = where, inherits = FALSE)) {
        fdef <- get(what, envir = where)
        hasFunction <- is(fdef, "genericFunction")
    }

        hasFunction <- FALSE
    if(hasFunction) {
        ## find the generic in the corresponding namespace
        where2 <- findFunction(what, where = environment(fdef))[[1L]] # must find it?
        unlockBinding(what, where)
        setMethod(what, signature, method, where = where)
        lockBinding(what, where)
        ## assign in the package namespace as well
        unlockBinding(what, where2)
        setMethod(what, signature, method, where = where2)
        lockBinding(what, where2)
    }
    else {
        setMethod(what, signature, method, where = where)
    }
}

### finding the package name for a loaded namespace -- kludgy but is there
### a table in this direction anywhere?
.searchNamespaceNames <- function(env) {
    namespaces <- .Internal(getNamespaceRegistry())
    names <- objects(namespaces, all.names = TRUE)
    for(what in names)
        if(identical(get(what, envir=namespaces), env))
            return(paste("namespace", what, sep=":"))
    return(character())
}

.findFunEnvAndName <- function(what, where, signature = NULL) {
    pname <- character()
    if(is.null(signature)) {
        whereF <- findFunction(what, where = where)
        if(length(whereF)>0)
            whereF <- whereF[[1L]]
        else return(list(pname = pname, whereF = baseenv()))
    } else
        whereF <- .genEnv(what, where)

    ## avoid partial matches to "names"
    if("name" %in% names(attributes(whereF)))
        pname <- gsub("^.*:", "", attr(whereF, "name"))
    else if(isNamespace(whereF))
        pname <- .searchNamespaceNames(whereF)
    list(pname = pname, whereF = whereF)
}

.makeTraceClass <- function(traceClassName, className, verbose = TRUE) {
  ## called because the traceClassName not a class
  ## first check whether it may exist but not in the same package
  if(isClass(as.character(traceClassName)))
    return(as.character(traceClassName))
  if(verbose)
    message("Constructing traceable class \"",traceClassName, "\"")
  env <- .classEnv(className)
  if(environmentIsLocked(env)) {
    message("Environment of class \"", className,
            "\" is locked; using global environment for new class")
    env <- .GlobalEnv
    packageSlot(traceClassName) <- NULL
  }
  setClass(traceClassName,
                 contains = c(className, "traceable"), where = env)
  if(existsMethod("show", className, env)) # override it for traceClassName
    setMethod("show", traceClassName, .showTraceable)
  traceClassName
}



.dummySetMethod <- function(f, signature = character(), definition,
	     where = topenv(parent.frame()), valueClass = NULL,
	     sealed = FALSE)
{
    if(is.function(f) && is(f, "genericFunction")) {
        f <- fdef@generic
    }
    else if(is.function(f)) {
        if(is.primitive(f)) {
            f <- .primname(f)
        }
        else
            stop("A function for argument \"f\" must be a generic function")
    }
    else {
        f <- switch(f, "as.double" =, "as.real" = "as.numeric", f)
    }
    assign(.dummyMethodName(f, signature), definition, envir = where)
}

.functionsOverriden <- c("setClass", "setClassUnion", "setGeneric", "setIs", "setMethod", "setValidity")

.setEnvForSource <- function(env) {
    doNothing <- function(x, ...)x
    ## establish some dummy definitions & a special setMethod()
    for(f in .functionsOverriden)
        assign(f, switch(f, setMethod = .dummySetMethod, doNothing),
               envir = env)
    env
}

.dummyMethodName <- function(f, signature)
    paste(c(f,signature), collapse="#")

.guessPackageName <- function(env) {
    allObjects <- objects(env, all.names = TRUE)
    allObjects <- allObjects[is.na(match(allObjects, .functionsOverriden))]
    ## counts of packaages containing objects; objects not found don't count
    possible <- sort(table(unlist(lapply(allObjects, find))), decreasing = TRUE)
    message <- ""
    if(length(possible) == 0)
        stop("None of the objects in the source code could be found:  need to attach or specify the package")
    else if(length(possible) > 1) {
        global <- match(".GlobalEnv", names(possible), 0)
        if(global > 0) {
            possible <- possible[-global] # even if it's the most common
        }
        if(length(possible) > 1)
            warning(gettextf("Objects found in multiple packages: using \"%s\" and ignoring %s",
                 names(possible[[1]]),
                 paste('"', names(possible[-1]), '"',sep="", collapse = ", ")),
                 domain = NA)
    }
    sub("package:","", names(possible[1])) # the package name, or .GlobalEnv
}

## extract the new definitions from the source file
evalSource <- function(source, package = "", lock = TRUE, cache = FALSE) {
    if(!nzchar(package))
        envp <- .GlobalEnv # will look for the package after evaluating source
    else {
        pstring <- paste("package",package, sep=":")
        packageIsVisible <- pstring %in% search()
        if(packageIsVisible) {
            envp <- as.environment(pstring)
            envns <- tryCatch(asNamespace(package), error = function(cond) NULL)
        }
        else {
            envp <- tryCatch(asNamespace(package), error = function(cond) NULL)
            envns <- envp
        }
        if(is.null(envp))
            stop(gettextf('Package "%s" is not attached and no namespace found for it',
                          package), domain = NA)
    }
    env <- new("sourceEnvironment", new.env(parent = envp),
        packageName = package,
        sourceFile = (if(is.character(source)) source else ""))
    env$.packageName <- package # Fixme: should be done by an initialize method
    setCacheOnAssign(env, cache)
    if(is(source, "character"))
        for(text in source)
            sys.source(text, envir = env)
    else if(is(source, "connection"))
        sys.source(source, envir = env)
    else if(!is(source, "environment"))
        stop(gettextf("Invalid source argument: expected file names(s) or connection, got an object of class \"%s\"", class(source)[[1]]), domain = NA)
    if(lock)
        lockEnvironment(env, bindings = TRUE) # no further changes allowed
    env
}

insertSource <- function(source, package = "",
                         functions = allPlainObjects(),
                         methods = (if(missing(functions)) allMethodTables() else NULL)
##                         ,classes = (if(missing(functions)) allClassDefs() else NULL)
                         , force = missing(functions) & missing(methods)
                     ){
    MPattern <- .TableMetaPattern()
    CPattern <- .ClassMetaPattern()
    allPlainObjects <- function()
        allObjects[!(grepl(MPattern, allObjects) | grepl(CPattern, allObjects))]
    allMethodTables <- function()
        allObjects[grepl(MPattern, allObjects)]
    allClassDefs <- function()
        allObjects[grepl(CPattern, allObjects)]
    differs <- function(f1, f2)
        !(identical(body(f1), body(f2)) && identical(args(f1), args(f2)))
    if(is.environment(source) && !nzchar(package)) {
        if(is(source, "sourceEnvironment"))
            package <- source@packageName
        else if(exists(".packageName", envir = source, inherits = FALSE))
            package <- get(".packageName", envir =source)
    }
    if(is(source, "environment"))
        env <- source
    else
        env <- evalSource(source, package, FALSE) # sourceEnvironment, unlocked
    envPackage <- getPackageName(env, FALSE)
    ## identify an environment and (if possible) namespace for the package
    envp <- parent.env(env)
    if(identical(envp, .GlobalEnv) || !nzchar(envPackage)) { # no package name in the eval, guess one
        if(!nzchar(package))
            package <- .guessPackageName(env) # use find() on objects in env
        if(identical(package, ".GlobalEnv"))
            envns <- NULL
        else {
            pname <- paste("package:", package, sep="")
            envp <- tryCatch(as.environment(pname), error = function(cond)NULL)
            if(is.null(envp)) {
                envp <- tryCatch(as.environment(pname), error = function(cond)NULL)
                if(is.null(envp))
                    stop(gettextf(
                     "Can't find an environment corresponding to package name \'%s\"",
                     package), domain = NA)
            }
            envns <- tryCatch(asNamespace(package), error = function(cond)NULL)
        }
        if(nzchar(package))
            assign(".packageName", package, envir = env)
    }
    else {
        if(isNamespace(envp))
            envns <- envp
        else
            envns <- tryCatch(asNamespace(package), error = function(cond)NULL)
    }
    if(nzchar(envPackage) && envPackage != package)
        warning(gettextf("Supplied package, \"%s\", differs from package inferred from source, \"%s\"",
                         package, envPackage),
                domain = NA)
    packageSlot(env) <- package
    ## at this point, envp is the target environment (package or other)
    ## and envns is the corresponding namespace if any, or NULL
    allObjects <- objects(envir = env, all.names = TRUE)
    ## Figure out what to trace.
    if(!missing(functions)) {
        notThere <- is.na(match(functions, allObjects))
        if(any(notThere)) {
            warning(gettextf("Can't insert these (not found in source): %s",
                    paste('"',functions[notThere],'"',
                          sep = "", collapse = ", ")),
                    domain = NA)
        }
    }
    .mnames <- allMethodTables()
    if(length(methods) > 0) {
        notThere <- sapply(methods,
         function(fname) (length(grep(fname, .mnames, fixed = TRUE)) == 0)
        )
        if(any(notThere)) {
            warning(gettextf("Can't insert methods for these functions (methods table not found in source): %s",
                    paste('"',methods[notThere],'"',
                          sep = "", collapse = ", ")),
                    domain = NA)
            methods <- methods[!notThere]
        }
        methodNames <- sapply(methods,
         function(fname) .mnames[[grep(fname, .mnames, fixed = TRUE)[[1]]]]
        )
    }
    else {
        methodNames <- .mnames
        methods <- sub(.TableMetaPrefix(), "", methodNames)
        methods <- sub(":.*","",methods)
    }
    ## if(!missing(classes)) {
    ##     .mnames <- allMethodNames()
    ##     notThere <- sapply(classes,
    ##      function(fname) length(grep(fname, .mnames, fixed = TRUE) == 0)
    ##     )
    ##     if(any(notThere)) {
    ##         warning(gettextf("Can't insert these classes (class definition not found in source): %s",
    ##                 paste('"',classes[notThere],'"',
    ##                       sep = "", collapse = ", ")),
    ##                 domain = NA)
    ##         classes <- classes[!notThere]
    ##     }
    ## }
    notTraceable <- newObjects <- objectsDone <- character()
    for(i in seq_along(functions)) {
        this <- functions[[i]]
        thisWhere <- NULL
        if(is.null(envns) ||
           exists(this, envir = envp, inherits = FALSE)) {
            envwhere <- envp
            thisWhere <- get(this, envir = envp)
        }
        else {
            envwhere <- envns
            if(is.environment(envns)  &&
               exists(this, envir = envns, inherits = FALSE))
                thisWhere <- get(this, envir = envns)
        }
        thisObj <- get(this, envir = env)
        if(is.function(thisObj) && is.function(thisWhere)
           && differs(thisObj, thisWhere)) {
            suppressMessages(
               .TraceWithMethods(this, where = envwhere, edit = env))
            objectsDone <- c(objectsDone, this)
        }
        else if(force)
            assign(this, thisObj, envir = envwhere)
        else if(!is.function(thisObj))
            notTraceable <- c(notTraceable, this)
        else if(is.null(thisWhere))
            newObjects <- c(newObjects, this)
    }
    if(length(notTraceable) > 0)
        message(gettextf("Non-function objects aren't currently inserted (not traceable): %s",
                 paste(notTraceable, collapse = ", ")), domain = NA)
    if(length(newObjects) > 0)
        message(gettextf("New functions aren't currently inserted (not untraceable): %s",
                 paste(newObjects, collapse = ", ")), domain = NA)
    if(length(objectsDone) > 0)
        message(gettextf("Modified functions inserted through trace(): %s",
                 paste(objectsDone, collapse = ", ")), domain = NA)
    for(i in seq_along(methods)) {
        .copyMethods(methods[[i]], methodNames[[i]], env, envp)
    }
    ## for(class in classes) {
    ##     .copyClass(class, env, envwhere)
    ## }
    ## return the environment, after cleaning up the dummy functions and
    ## adding a time stamp, if the source was parssed on this call
    if(!is.environment(source)) {
        lockEnvironment(env, bindings = TRUE) # no further changes allowed
        invisible(env)
    }
    else
        invisible(source)
}

.copyMethods <- function(f, tableName, env, envwhere) {
    differs <- function(o1, o2)
        !(is.function(o2) && # o2 can be NULL
          identical(body(o2), body(o2)) && identical(args(o1), args(o2)))
    table <- get(tableName, envir=env)
    fdef <- getGeneric(f, where = envwhere)
    if(!is(fdef, "genericFunction")) {
        message(gettextf("%s() is not a generic function in the target environment--methods will not be inserted",
                         f), domain = NA)
        return(NULL)
    }
    curTable <- getMethodsForDispatch(fdef)
    allObjects <- objects(table, all.names = TRUE)
    methodsInserted <- character()
    if(length(allObjects) > 0) {
        for(this in allObjects) {
            def <- get(this, envir = table)
            curdef <- (if(exists(this, envir = curTable, inherits = FALSE))
                get(this, envir = curTable)
                       else NULL)
            if(differs(def, curdef)) {
                suppressMessages(
                   .TraceWithMethods(f, signature = this, where = envwhere,
                              edit = env))
                methodsInserted <- c(methodsInserted, this)
            }
        }
        if(length(methodsInserted) > 0)
            message(gettextf("Methods inserted for function %s(): %s",
                  f, paste(methodsInserted, collapse =", ")),
                  domain = NA)
    }
}

.copyClass <- function(class, env, envwhere) {
    message("Pretend we inserted class ",class)
}

.findNewDefForTrace <- function(what, signature, env, package) {
    if(is.null(signature)) {
        if(exists(what, envir = env, inherits = FALSE))
            newObject <- get(what, envir = env)
        else
            stop(gettextf("No definition for object \"%s\" found in tracing environment",
                          what, source), domain = NA)
    }
    else {
        ## we don't know the package for the generic (which may not
        ## be active), so we search for the string w/o package
        table <- .TableMetaName(what, "")
        allObjects <- objects(env, all.names = TRUE)
        i <- grep(table, allObjects, fixed = TRUE)
        if(length(i) == 1)
            table <- get(allObjects[[i]], envir = env)
        else if(length(i) >1) {
            table <- allObjects[[i[[1]]]]
            warning(gettextf("multiple generics match pattern, using table %s", table)
                , domain = NA)
            table <- get(table, envir = env)
        }
        else
            stop(gettextf("Does not seem to be a method table for generic  \"%s\" in tracing environment",
                          what), domain = NA)
        if(exists(signature, envir = table, inherits = FALSE))
          newObject <- get(signature, envir = table)
        else
          stop(gettextf("No method in methods table for \"%s\" for signature \"%s\"", what, signature), domain = NA)
    }
    newObject
}
