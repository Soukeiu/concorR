#' @export
make_blk <- function(adj_list, nsplit = 1) {
  concor_out <- suppressWarnings(concor(adj_list, nsplit))

  concor_order <- match(colnames(adj_list[[1]]), concor_out$vertex)
  block_ordered <- concor_out$block[concor_order]

  blockmodel_list <- lapply(adj_list,
                            function(x) sna::blockmodel(as.matrix(x),
                                                        block_ordered))

  return(blockmodel_list)
}

.edge_dens <- function(adj_mat) {
  adj_mat[adj_mat > 0] <- 1
  a <- sum(adj_mat)
  m <- length(adj_mat) - sqrt(length(adj_mat))
  d <- a / m
  return(d)
}

#' @export
make_reduced <- function(adj_list, nsplit = 1) {
  blk_out = make_blk(adj_list, nsplit)
  dens_vec <- sapply(adj_list, function(x) .edge_dens(x))
  d <- lapply(blk_out, function(x) x[[5]])
  mat_return <- vector("list", length = length(dens_vec))

  for (i in 1:length(dens_vec)) {
    temp1 <- d[[i]]
    temp1[is.nan(temp1)] <- 0
    temp1[temp1 < dens_vec[[i]]] <- 0
    temp1[temp1 > 0] <- 1
    mat_return[[i]] <- temp1
  }

  return_list <- list()
  return_list$reduced_mat <- mat_return
  return_list$dens <- dens_vec
  return(return_list)
}

#' @export
plot_blk <- function (x, labels = FALSE, ...) {
  # Adapted from sna::plot.blockmodel():
  # Carter T. Butts (2019). sna: Tools for Social Network Analysis.
  # R package version 2.5, licensed under GPL (>= 2).
  # https://CRAN.R-project.org/package=sna

  if (!labels) {
    x$plabels <- rep("", length(x$plabels))
    x$glabels <- ""
  }

  oldpar <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(oldpar))
  n <- dim(x$blocked.data)[2]
  m <- sna::stackcount(x$blocked.data)
  if (!is.null(x$plabels))
    plab <- x$plabels
  else plab <- (1:n)[x$order.vector]
  glab <- ""
  graphics::par(mfrow = c(floor(sqrt(m)), ceiling(m/floor(sqrt(m)))))
  if (m > 1)
    for (i in 1:m) {
      sna::plot.sociomatrix(x$blocked.data[i, , ], labels = list(plab, plab),
                       main = glab[i], drawlines = FALSE, asp = 1)

      for (j in 2:n) if (x$block.membership[j] != x$block.membership[j - 1])
        graphics::abline(v = j - 0.5, h = j - 0.5, lty = 3)
    }
  else {
    sna::plot.sociomatrix(x$blocked.data, labels = list(plab, plab),
                     main = glab[1], drawlines = FALSE, asp = 1)

    for (j in 2:n) if (x$block.membership[j] != x$block.membership[j - 1])
      graphics::abline(v = j - 0.5, h = j - 0.5, lty = 3)
  }
}

#' @export
make_reduced_igraph <- function(reduced_mat) {
  iplotty <- igraph::graph_from_adjacency_matrix(reduced_mat,
                                                 mode = "directed")
  return(iplotty)
}

#' @export
plot_reduced <- function(iobject) {
  vcolors <- c(1:length(igraph::vertex_attr(iobject)$name))
  igraph::plot.igraph(iobject, vertex.color = vcolors, vertex.label = NA,
                      edge.arrow.size = .6, vertex.size = 25)
}

