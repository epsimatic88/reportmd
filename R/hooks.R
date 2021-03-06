## Chunk hooks

#' Special processing for figure and table chunks
#'
#' These hooks are intended for use with knitr. There is usually no need
#' to call them directly.
#'
#' @param before Logical indicating whether the hook was called befere or
#' after the chunk has been processed.
#' @param options List of chunk options.
#' @param envir Environment in which the chunk is evaluated.
#'
#' @note These hooks are intended for chunks with the \code{fig.cap} (for figures) and
#' \code{tab.cap} (for tables) option and this is assumed to be present.
#' @return The chunk hooks produce markup that adds anchors to enable direct links to the
#' table or figure and add s the caption where required.
#' @author Peter Humburg
#' @importFrom knitr opts_chunk
#' @export
#'
#' @rdname figure-hooks
fig.cap_chunk_hook <- function(before, options, envir) {
  global_fmt <- options('reportmd.figure.format') %||% list('screen')
  fmt <- options$format %||% global_fmt[[1]]
  if(fmt[1] == 'interactive'){
    if(before){
      paste0('<div id="', knitr::opts_chunk$get('fig.lp'), options$label, '" class="figure">')
    } else{
      options(reportmd.figure.current=NULL)
      paste0('<p class="caption text-center">', options$fig.cap,"</p></div>")
    }
  }
}

#' @export
#' @rdname figure-hooks
tab.cap_chunk_hook <- function(before, options, envir) {
  if(before){
    paste0('<div id="tab:', options$label, '" class="table-wrapper">',
           '<p class="caption">', options$tab.cap, "</p>")
  } else{
    "</div>"
  }
}


## Option hooks

#' @return \code{fig.cap_opts_hook} returns a list of chunk options
#' adjusted for the requested figure format.
#' @export
#' @rdname figure-hooks
fig.cap_opts_hook <- function(options){
  global_fmt <- options('reportmd.figure.format')[[1]]
  fmt <- options$format %||% global_fmt
  options(reportmd.figure.current=fmt)

  options$fig.cap = figRef(options$label, options$fig.cap)
  if(length(options$fig_download) && 'print' %in% fmt && length(fmt) > 1){
    download <- options$fig_download
    download <- stringr::str_replace(options$fig_download, stringr::fixed('%PATH%'),
                                     file.path(options$fig.path,
                                               paste(options$label, '1.pdf', sep='-')))
    options$fig.cap <- paste(options$fig.cap, download)
  }

  options$cache <- FALSE
  if(options$hide.fig.code){
    options$echo <- FALSE
    options$warning <- FALSE
  }

  opts <- options(paste('reportmd', 'figure', fmt, sep='.'))[[1]]
  opts <- merge_list(opts, options)
  opts
}

#' @return \code{tab.cap_opts_hook} returns a list of chunk options with
#' the \code{tab.cap} option augmented for automatic table numbering.
#' @export
#' @rdname figure-hooks
tab.cap_opts_hook <- function(options){
  options$tab.cap <- tabRef(options$label, options$tab.cap)
  options$echo <- FALSE
  options
}

#' Dependency processing
#'
#' Hooks for use with knitr to facilitate handling of inter-file dependencies.
#' @param options List of chunk options
#'
#' @return Updated list of options
#' @export
#' @importFrom knitr opts_knit
#' @author Peter Humburg
dependson_opts_hook <- function(options){
  depends <- options$dependson
  parse <- grepl("\\S+:\\S+", depends)
  if(any(parse)){
    if(is.null(opts_knit$get('dependencies'))){
      stop("Requested external dependency (", depends[parse][1],
           ") but dependency information is missing. Did you list dependencies in the header?")
    }
    external <- strsplit(depends[parse], "[:/]")
    for(ext_dep in external){
      dep <- opts_knit$get('dependencies')[ext_dep[[1]]]
      dep[[1]]$chunks <- ext_dep[[2]]
      load_dependencies(dep)
      if(is.null(options$ext.depends)){
        options$ext.depends <- list()
      }
      if(length(ext_dep) > 2){
        options$ext.depends <- c(options$ext.depends, get(ext_dep[3]))
      } else{
        options$ext.depends <- c(options$ext.depends, file.mtime(dep[[1]]$source))
      }
    }
  }
  options
}

format_opts_hook <- function(options){
  general_opts <- c('fig.width', 'fig.height', 'out.width', 'out.height', 'out.extra', 'dpi')
  options$dev <- plot_formats[options$format]
  dev_opts <- lapply(options$format, function(x )figureOptions(format=x))
  opts <- lapply(dev_opts, function(x, general) x[general], general_opts)
  opts <- Reduce(function(x, y) mapply(`%||%`, x, y, SIMPLIFY=FALSE), opts)
  opts <- opts[!sapply(opts, is.null)]
  options[names(opts)] <- opts
  dev_opts <- lapply(dev_opts, function(x, general) x[!names(x) %in% general], general_opts)
  names(dev_opts) <- options$dev
  options$dev.args <- dev_opts
  options
}

## Output hooks

#' @importFrom knitr opts_knit
document_hook <- function(x){
  if(!is.null(opts_knit$get('dependencies'))){
    deps <- opts_knit$get('dependencies')
    link_section <- c('##Related Documents',
                      sapply(deps, printMD, format='md reference'), '',
                      sapply(deps, printMD, format='reference'))
    x <- paste(c(x, link_section), collapse='  \n')
  }
  mapply(write_index, opts_knit$get('reportmd.index'), names(opts_knit$get('reportmd.index')))
  x
}


#' Set knitr hooks
#'
#' Installs all required knitr hooks.
#'
#' @return Called for its side effect.
#' @author Peter Humburg
#' @importFrom knitr opts_hooks
#' @importFrom knitr knit_hooks
#' @export
installHooks <- function(){
  knitr::opts_hooks$set(fig.cap=fig.cap_opts_hook)
  knitr::opts_hooks$set(tab.cap=tab.cap_opts_hook)
  knitr::opts_hooks$set(dependson=dependson_opts_hook)
  knitr::opts_hooks$set(format=format_opts_hook)
  knitr::knit_hooks$set(fig.cap=fig.cap_chunk_hook)
  knitr::knit_hooks$set(tab.cap=tab.cap_chunk_hook)
  knitr::knit_hooks$set(document=document_hook)
}

