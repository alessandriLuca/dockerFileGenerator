help.request <- function (subject = "",
			  ccaddress = Sys.getenv("USER"),
			  method = getOption("mailer"),
			  address = "r-help@R-project.org",
			  file = "R.help.request")
{
    no <- function(answer) answer == "n"
    yes <- function(answer) answer == "y"
    webpage <- "corresponding web page"
    catPlease <- function()
	cat("Please do this first - the",
	    webpage,"has been loaded in your web browser\n")
    go <- function(url) {
	catPlease()
	browseURL(url)
    }
    readMyLine <- function(..., .A. = "(y/n)")
	readline(paste(paste(strwrap(paste(...)), collapse="\n"),
		       .A., "")) # space after question

    checkPkgs <- function(pkgDescs,
			  pkgtxt = paste("packages",
                          paste(names(pkgDescs), collapse=", ")))
    {
        cat("Checking if", pkgtxt, "are up-to-date; may take some time...\n")

        stopifnot(sapply(pkgDescs, inherits, what="packageDescription"))
        fields <- .instPkgFields(NULL)
	n <- length(pkgDescs)
	iPkgs <- matrix(NA_character_, n, 2L + length(fields),
		      dimnames=list(NULL, c("Package", "LibPath", fields)))
	for(i in seq_len(n)) {
	    desc <- c(unlist(pkgDescs[[i]]),
		      "LibPath" = dirname(dirname(dirname(attr(pkgDescs[[i]],
		      "file")))))
	    nms <- intersect(names(desc), colnames(iPkgs))
	    iPkgs[i, nms] <- desc[nms]
	}

	old <- old.packages(instPkgs = iPkgs)

	if (!is.null(old)) {
	    update <- readMyLine("The following installed packages are out-of-date:\n",
				 paste(strwrap(rownames(old),
					       width = 0.7 *getOption("width"),
					       indent= 0.15*getOption("width")),
				       collapse="\n"),
				 "would you like to update now?")
	    if (yes(update)) update.packages(oldPkgs = old, ask = FALSE)
	}
    }

    cat("Checklist:\n")
    post <- readline("Have you read the posting guide? (y/n) ")
    if (no(post)) return(go("http://www.r-project.org/posting-guide.html"))
    FAQ <- readline("Have you checked the FAQ? (y/n) ")
    if (no(FAQ)) return(go("http://cran.r-project.org/faqs.html"))
    intro <- readline("Have you checked An Introduction to R? (y/n) ")
    if (no(intro))
	return(go("http://cran.r-project.org/doc/manuals/R-intro.html"))
    NEWS <- readMyLine("Have you checked the NEWS of the latest development release?")
    if (no(NEWS)) return(go("https://svn.r-project.org/R/trunk/NEWS"))
    rsitesearch <- readline("Have you looked on RSiteSearch? (y/n) ")
    if (no(rsitesearch)) {
	catPlease()
	return(RSiteSearch(subject))
    }
    inf <- sessionInfo()
    if ("otherPkgs" %in% names(inf)) {
	oPkgs <- names(inf$otherPkgs)
        ## FIXME: inf$otherPkgs is a list of packageDescription()s
	other <-
	    readMyLine("You have packages",
                       paste("(", paste(sQuote(oPkgs), collapse=", "),")", sep=""),
                       "other than the base packages loaded. ",
		       "If your query relates to one of these, have you ",
		       "checked any corresponding books/manuals and",
		       "considered contacting the package maintainer?",
                       .A. = "(y/n/NA)")
	if(no(other)) return("Please do this first.")
    }

    man <- url("http://cran.r-project.org/manuals.html")
    ver <- scan(man, what = character(0L), sep = "\n", skip = 13L, nlines = 1L,
		quiet = TRUE)
    ver <- strsplit(ver, " ")[[1L]][3L]
    if (getRversion() < numeric_version(ver)) {
	update <- readMyLine("Your R version is out-of-date,",
			     "would you like to update now?")
	if(yes(update)) return(go(getOption("repos")))
    }
    if ("otherPkgs" %in% names(inf)) {
        checkPkgs(inf$otherPkgs)
    }
    ## To get long prompt!
    cat("Have you written example code that is\n",
	"- minimal\n - reproducible\n - self-contained\n - commented",
	"\nusing data that is either\n",
	"- constructed by the code\n - loaded by data()\n",
	"- reproduced using dump(\"mydata\", file = \"\")\n")
    code <- readMyLine("have you checked this code in a fresh R session",
		       "(invoking R with the --vanilla option if possible)",
		       "and is this code copied to the clipboard?")
    if (no(code))
	return(cat("\nIf your query is not directly related to code",
		   "(e.g. a general query \nabout R's capabilities),",
		   "email R-help@r-project.org directly. ",
		   "\nOtherwise prepare some example code first.\n"))
    change <- readline(paste("Would you like to change your subject line:",
			     subject, "to something more meaningful? (y/n) ",
			     sep = "\n"))
    if (yes(change))
	subject <- readline("Enter subject: \n")

    create.post(instructions = paste(
		"\\n<<SEND AS PLAIN TEXT!>>\\n\\n",
		"\\n<<Write your query here, using your example code to illustrate>>",
		"\\n<<End with your name and affiliation>>\\n\\n\\n\\n"),
		description = "help request",
		subject = subject,
		ccaddress = ccaddress,
		method = method,
		address = address,
		file = file)
}
