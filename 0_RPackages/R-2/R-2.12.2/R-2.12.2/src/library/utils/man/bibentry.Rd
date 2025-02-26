\name{bibentry}
\alias{bibentry}
\alias{print.bibentry}
\title{Bibliography Entries}
\description{
  Functionality for representing and manipulating bibliographic
  information in enhanced BibTeX style.
}
\usage{
bibentry(bibtype, textVersion = NULL, header = NULL, footer = NULL,
         key = NULL, ..., other = list(),
         mheader = NULL, mfooter = NULL)
\method{print}{bibentry}(x, style = c("text", "Bibtex", "citation",
                   "html", "latex", "textVersion"),
      .bibstyle = "JSS", ...)
}
\arguments{
  \item{bibtype}{a character string with a BibTeX entry type.
    See \bold{Entry Types} for details.
  }
  \item{textVersion}{a character string with a text representation of
    the reference to optionally be employed for printing.}
  \item{header}{a character string with optional header text.}
  \item{footer}{a character string with optional footer text.}
  \item{key}{a character string giving the citation key for the entry.}
  \item{...}{for \code{bibentry}: arguments of the form
    \code{\var{tag}=\var{value}} giving the fields of the entry, with
    \var{tag} and \var{value} the name and value of the field,
    respectively.  Arguments with empty values are dropped.
    See \bold{Entry Fields} for details.

    For the \code{print} method, extra parameters to pass to the
    renderer.}
  \item{other}{a list of arguments as in \code{...} (useful in
    particular for fields named the same as formals of
    \code{bibentry}).}
  \item{mheader}{a character string with optional \dQuote{outer} header
    text.}
  \item{mfooter}{a character string with optional \dQuote{outer} footer
    text.}
  \item{x}{an object inheriting from class \code{"bibentry"}.}
  \item{style}{a character string specifying the print style.
    Must be a unique abbreviation of the choices indicated in the usage.}
  \item{.bibstyle}{a character string naming a bibliography style.}
}
\details{
  The bibentry objects created by \code{bibentry} can represent an
  arbitrary positive number of references.  One can use \code{c()} to
  combine bibentry objects, and hence in particular build a multiple
  reference object from single reference ones.  Alternatively, one can
  use \code{bibentry} to directly create a multiple reference object by
  \dQuote{vectorizing} the given arguments, i.e., use character vectors
  instead of character strings.

  The \code{\link{print}} method for bibentry objects provides a choice
  between six different styles:
  plain text (style \code{"text"}),
  BibTeX (\code{"Bibtex"}),
  a mixture of plain text and BibTeX as traditionally used for citations
  (\code{"citation"}),
  HTML (style \code{"html"}),
  LaTeX (style \code{"latex"}),
  and a simple copy of the \code{textVersion} elements (style
  \code{"textVersion"}).
  The \code{"text"}, \code{"html"} and \code{"latex"} styles make use
  of the \code{.bibstyle} argument using the \code{\link{bibstyle}}
  function.  When printing bibentry objects in citation style, a
  \code{header}/\code{footer} for each item can be displayed as well as
  a \code{mheader}/\code{mfooter} for the whole vector of references.

  There is also a \code{\link{toBibtex}} method for direct conversion to
  BibTeX.
}
\value{
  \code{bibentry} produces an object of class \code{"bibentry"}.
}
\section{Entry Types}{
  \code{bibentry} creates \code{"bibentry"} objects, which are modeled
  after BibTeX entries.  The entry should be a valid BibTeX entry type,
  e.g.,
  \describe{
    \item{Article:}{An article from a journal or magazine.}
    \item{Book:}{A book with an explicit publisher.}
    \item{InBook:}{A part of a book, which may be a chapter (or section
      or whatever) and/or a range of pages.}  
    \item{InCollection:}{A part of a book having its own title.}
    \item{InProceedings:}{An article in a conference proceedings.}
    \item{Manual:}{Technical documentation like a software manual.}
    \item{MastersThesis:}{A Master's thesis.}
    \item{Misc:}{Use this type when nothing else fits.}
    \item{PhdThesis:}{A PhD thesis.}
    \item{Proceedings:}{The proceedings of a conference.}
    \item{TechReport:}{A report published by a school or other
      institution, usually numbered within a series.}
    \item{Unpublished:}{A document having an author and title, but not
      formally published.}
  }
}
\section{Entry Fields}{
  The \code{\dots} argument of \code{bibentry} can be any number of
  BibTeX fields, including
  \describe{
    \item{address:}{The address of the publisher or other type of
      institution.}

    \item{author:}{The name(s) of the author(s), either 
      as a character string in the format described in the LaTeX book,
      or a \code{\link{person}} object.}

    \item{booktitle:}{Title of a book, part of which is being cited.}
    \item{chapter:}{A chapter (or section or whatever) number.}
    
    \item{editor:}{Name(s) of editor(s), same format as \code{author}.}

    \item{institution:}{The publishing institution of a technical report.}

    \item{journal:}{A journal name.}

    \item{note:}{Any additional information that can help the reader.
      The first word should be capitalized.}

    \item{number:}{The number of a journal, magazine, technical report,
      or of a work in a series.}

    \item{pages:}{One or more page numbers or range of numbers.}
    
    \item{publisher:}{The publisher's name.}
    
    \item{school:}{The name of the school where a thesis was written.}
    
    \item{series:}{The name of a series or set of books.}
    
    \item{title:}{The work's title.}
    
    \item{volume:}{The volume of a journal or multi-volume book.}
    
    \item{year:}{The year of publication.}
  }
}
\note{
  The bibentry functionality is still experimental.
}
\examples{
## R reference
rref <- bibentry(
   bibtype = "Manual",
   title = "R: A Language and Environment for Statistical Computing",
   author = person("R Development Core Team"),
   organization = "R Foundation for Statistical Computing",
   address = "Vienna, Austria",
   year = 2010,
   isbn = "3-900051-07-0",
   url = "http://www.R-project.org/")

## Different printing styles
print(rref)
print(rref, style = "Bibtex")
print(rref, style = "citation")
print(rref, style = "html")
print(rref, style = "latex")

## References for boot package and associated book
bref <- c(
   bibentry(
     bibtype = "Manual",
     title = "boot: Bootstrap R (S-PLUS) Functions",
     author = c(
       person("Angelo", "Canty", role = "aut", comment = "S original"),
       person(c("Brian", "D."), "Ripley", role = c("aut", "trl", "cre"),
         comment = "R port", email = "ripley@stats.ox.ac.uk")
     ),
     year = "2010",
     note = "R package version 1.2-42",
     url = "http://CRAN.R-project.org/package=boot",
     key = "boot-package"
   ),

   bibentry(
     bibtype = "Book",
     title = "Bootstrap Methods and Their Applications",
     author = as.person("Anthony C. Davison [aut], David V. Hinkley [aut]"),
     year = "1997",
     publisher = "Cambridge University Press",
     address = "Cambridge",
     isbn = "0-521-57391-2",
     url = "http://statwww.epfl.ch/davison/BMA/",
     key = "boot-book"
   )
)

## Combining and subsetting
c(rref, bref)
bref[2]

## Extracting fields
bref$author
bref[1]$author
bref[1]$author[2]$email

## Convert to BibTeX
toBibtex(bref)
}
\keyword{ utilities }
\keyword{ documentation }
